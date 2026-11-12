import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  type OnModuleInit,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { Assistant } from "../../assistant/assistant.js";
import type { Action, EvenementCercle, Mode, Reglement as ReglementAgents } from "../../assistant/types.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { FileSms } from "../../sms/file-sms.js";
import { fcfa } from "../../sms/montant.js";
import { CerclesService, type Reglement } from "../cercles/cercles.service.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { CotisationsService } from "../cotisations/cotisations.service.js";
import { PreuveService } from "../preuve/preuve.service.js";

/** Tant que l'organisateur n'a rien choisi : manuel, aucune action sans son accord. */
export const MODE_PAR_DEFAUT: Mode = "manuel";

export interface ActionJournal {
  id: string;
  cercleId: string;
  type: Action["type"];
  membreId: string;
  issue: "executee" | "en_attente" | "acceptee" | "refusee" | "hors_reglement";
  creeeLe: string;
  trancheeLe: string | null;
}

interface LigneAction extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  type: Action["type"];
  membre_id: string;
  cotisation_id?: string | null;
  issue: ActionJournal["issue"];
  creee_le: Date | string;
  tranchee_le: Date | string | null;
}

const versAction = (l: LigneAction): ActionJournal => ({
  id: l.id,
  cercleId: l.cercle_id,
  type: l.type,
  membreId: l.membre_id,
  issue: l.issue,
  creeeLe: new Date(l.creee_le).toISOString(),
  trancheeLe: l.tranchee_le ? new Date(l.tranchee_le).toISOString() : null,
});

/** 10 000 FCFA, avec une espace ordinaire : les SMS restent dans l'alphabet GSM (160 caractères par message). */

/** Date au Cameroun (UTC+1), jour/mois/année. */
const jour = (iso: string) =>
  new Intl.DateTimeFormat("fr-FR", {
    timeZone: "Africa/Douala",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(iso));

/** Ce que les agents ont le droit de faire, lu dans le règlement signé du cercle. */
const limitesDuReglement = (r: Reglement): ReglementAgents => ({
  delaiGraceJours: r.delaiGraceJours,
  rappelsAvantEcheanceJours: r.rappelsAvantEcheanceJours ?? [],
  // Flow 7 : la mise en demeure suit tout défaut constaté.
  miseEnDemeureAutorisee: true,
});

/**
 * Assistant de l'organisateur (décision 04), branché sur les événements internes.
 * Il ne touche ni à l'argent, ni au score, ni à l'ordre de passage ; chaque action est tracée.
 */
@Injectable()
export class AssistantService implements OnModuleInit {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CerclesService) private readonly cercles: CerclesService,
    @Inject(PreuveService) private readonly preuve: PreuveService,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  onModuleInit(): void {
    this.evenements.ecouter("echeance_proche", (e) =>
      this.traiter(e.cercleId, {
        type: "date_limite_proche",
        membreId: e.membreId,
        joursRestants: e.joursRestants,
        cotisationId: e.cotisationId,
      }),
    );
    this.evenements.ecouter("echeance_depassee", (e) =>
      this.traiter(e.cercleId, {
        type: "date_limite_depassee",
        membreId: e.membreId,
        joursDeRetard: e.joursDeRetard,
        cotisationId: e.cotisationId,
      }),
    );
    this.evenements.ecouter("defaut_constate", (e) =>
      this.traiter(e.cercleId, { type: "defaut_constate", membreId: e.membreId }),
    );
  }

  async changerMode(cercleId: string, demandeurId: string, mode: Mode): Promise<{ cercleId: string; mode: Mode }> {
    await this.verifierOrganisateur(cercleId, demandeurId);
    await this.base.requete(
      "INSERT INTO assistant.reglages (cercle_id, mode) VALUES ($1, $2) ON CONFLICT (cercle_id) DO UPDATE SET mode = $2",
      [cercleId, mode],
    );
    return { cercleId, mode };
  }

  async journal(cercleId: string, demandeurId: string): Promise<ActionJournal[]> {
    await this.verifierOrganisateur(cercleId, demandeurId);
    const lignes = await this.base.requete<LigneAction>(
      "SELECT * FROM assistant.actions WHERE cercle_id = $1 ORDER BY creee_le, id",
      [cercleId],
    );
    return lignes.map(versAction);
  }

  async trancher(actionId: string, demandeurId: string, decision: "acceptee" | "refusee"): Promise<ActionJournal> {
    if (!/^[0-9a-f-]{36}$/i.test(actionId)) throw new NotFoundException("Proposition introuvable");
    const [action] = await this.base.requete<LigneAction>("SELECT * FROM assistant.actions WHERE id = $1", [actionId]);
    if (!action) throw new NotFoundException("Proposition introuvable");
    await this.verifierOrganisateur(action.cercle_id, demandeurId);
    const [tranchee] = await this.base.requete<LigneAction>(
      "UPDATE assistant.actions SET issue = $2, tranchee_le = now() WHERE id = $1 AND issue = 'en_attente' RETURNING *",
      [actionId, decision],
    );
    if (!tranchee) throw new BadRequestException("Cette proposition a déjà été tranchée");
    if (decision === "acceptee") {
      await this.executer(tranchee.id, tranchee.cercle_id, {
        type: tranchee.type,
        membreId: tranchee.membre_id,
        ...(tranchee.cotisation_id ? { cotisationId: tranchee.cotisation_id } : {}),
      });
    }
    return versAction(tranchee);
  }

  private async traiter(cercleId: string, evenement: EvenementCercle): Promise<void> {
    const cercle = await this.cercles.trouver(cercleId);
    const [reglage] = await this.base.requete<{ mode: Mode }>(
      "SELECT mode FROM assistant.reglages WHERE cercle_id = $1",
      [cercleId],
    );
    const assistant = new Assistant(reglage?.mode ?? MODE_PAR_DEFAUT, limitesDuReglement(cercle.reglement));
    assistant.traiter([evenement]);
    for (const { action, issue } of assistant.coordinateur.journal) {
      const id = randomUUID();
      await this.base.requete(
        "INSERT INTO assistant.actions (id, cercle_id, type, membre_id, cotisation_id, issue) VALUES ($1, $2, $3, $4, $5, $6)",
        [id, cercleId, action.type, action.membreId, action.cotisationId ?? null, issue],
      );
      if (issue === "executee") await this.executer(id, cercleId, action);
    }
  }

  /**
   * SMS par la file d'envoi, rédigé au moment de l'exécution (en mode manuel, l'accord peut venir plus tard) :
   * un rappel vise la cotisation qui l'a déclenché, et ne part pas si elle a été payée ou déclarée entre-temps.
   * La mise en demeure est marquée envoyée une fois remise à la file. Clé = action : jamais deux SMS par action.
   */
  private async executer(actionId: string, cercleId: string, { type, membreId, cotisationId }: Action): Promise<void> {
    const texte =
      type === "mise_en_demeure"
        ? await this.texteMiseEnDemeure(cercleId, membreId)
        : await this.texteRappel(cercleId, membreId, type, cotisationId);
    const compte = await this.comptes.chercher(membreId);
    if (texte && compte) {
      await this.sms.mettreEnFile(`assistant:${actionId}`, compte.numero, texte);
      this.sms.declencher();
    }
    if (type === "mise_en_demeure") await this.preuve.marquerEnvoyees(cercleId, membreId);
  }

  private async texteRappel(
    cercleId: string,
    membreId: string,
    type: Action["type"],
    cotisationId: string | undefined,
  ): Promise<string | undefined> {
    // Action enregistrée avant le 05/11, sans cotisation : la plus ancienne encore due.
    const due = cotisationId
      ? await this.cotisations.consulter(cotisationId)
      : (await this.cotisations.listerPour(cercleId, membreId)).find((c) => c.statut === "due");
    if (!due || due.statut !== "due") return undefined;
    const quoi = `votre cotisation du tour ${due.tour} (${fcfa(due.montant)})`;
    return type === "rappel"
      ? `MonDo : rappel, ${quoi} est à payer avant le ${jour(due.dateLimite)}.`
      : `MonDo : ${quoi} est en retard. Payez avant le ${jour(due.finGrace)} pour éviter un défaut.`;
  }

  private async texteMiseEnDemeure(cercleId: string, membreId: string): Promise<string | undefined> {
    const [m] = await this.preuve.aEnvoyer(cercleId, membreId);
    if (!m) return undefined;
    return (
      `MonDo : mise en demeure (tour ${m.tour}). Vous devez ${fcfa(m.montantDu.total)} à votre cercle : ` +
      `${fcfa(m.montantDu.cotisations)} de cotisations et ${fcfa(m.montantDu.penalites)} de pénalités. ` +
      `Réglez par Mobile Money. Le dossier de preuve est à la disposition des membres du cercle.`
    );
  }

  private async verifierOrganisateur(cercleId: string, demandeurId: string): Promise<void> {
    const cercle = await this.cercles.trouver(cercleId);
    if (cercle.organisateurId !== demandeurId) throw new ForbiddenException("Réservé à l'organisateur du cercle");
  }
}
