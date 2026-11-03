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
import { CerclesService, type Reglement } from "../cercles/cercles.service.js";
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
  ) {}

  onModuleInit(): void {
    this.evenements.ecouter("echeance_proche", (e) =>
      this.traiter(e.cercleId, { type: "date_limite_proche", membreId: e.membreId, joursRestants: e.joursRestants }),
    );
    this.evenements.ecouter("echeance_depassee", (e) =>
      this.traiter(e.cercleId, { type: "date_limite_depassee", membreId: e.membreId, joursDeRetard: e.joursDeRetard }),
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
    if (decision === "acceptee") await this.executer(tranchee.cercle_id, tranchee.type, tranchee.membre_id);
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
      await this.base.requete(
        "INSERT INTO assistant.actions (id, cercle_id, type, membre_id, issue) VALUES ($1, $2, $3, $4, $5)",
        [randomUUID(), cercleId, action.type, action.membreId, issue],
      );
      if (issue === "executee") await this.executer(cercleId, action.type, action.membreId);
    }
  }

  /** Envoi simulé au prototype (pas encore de file d'envoi SMS) ; la mise en demeure est marquée envoyée. */
  private async executer(cercleId: string, type: Action["type"], membreId: string): Promise<void> {
    if (type === "mise_en_demeure") await this.preuve.marquerEnvoyees(cercleId, membreId);
  }

  private async verifierOrganisateur(cercleId: string, demandeurId: string): Promise<void> {
    const cercle = await this.cercles.trouver(cercleId);
    if (cercle.organisateurId !== demandeurId) throw new ForbiddenException("Réservé à l'organisateur du cercle");
  }
}
