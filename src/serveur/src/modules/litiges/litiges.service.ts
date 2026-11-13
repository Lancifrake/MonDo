import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { canonique } from "../../signature/canonique.js";
import { FileSms } from "../../sms/file-sms.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { CotisationsService, type Cotisation } from "../cotisations/cotisations.service.js";
import { PlanificateurService } from "../planificateur/planificateur.service.js";
import { estAdministrateur } from "./administrateurs.js";

/** Le payeur attend 48 h de confirmation avant de pouvoir ouvrir un litige (choix de David, 05/11). */
export const ATTENTE_PAYEUR_MS = 48 * 60 * 60 * 1000;

export type Decision = "paiement_valide" | "paiement_refuse";

export interface Litige {
  id: string;
  cotisationId: string;
  cercleId: string;
  payeurId: string;
  beneficiaireId: string;
  ouvertPar: "payeur" | "beneficiaire" | "automatique";
  motif: string;
  ouvertLe: string;
  /** clos : le bénéficiaire a fini par confirmer lui-même. */
  statut: "ouvert" | "tranche" | "clos";
  decision?: Decision | "confirme_par_beneficiaire";
  motifDecision?: string;
  tranchePar?: string;
  trancheLe?: string;
}

interface LigneLitige extends Record<string, unknown> {
  id: string;
  cotisation_id: string;
  cercle_id: string;
  payeur_id: string;
  beneficiaire_id: string;
  ouvert_par: Litige["ouvertPar"];
  motif: string;
  ouvert_le: Date | string;
  statut: Litige["statut"];
  decision: Litige["decision"] | null;
  motif_decision: string | null;
  tranche_par: string | null;
  tranche_le: Date | string | null;
}

const versLitige = (l: LigneLitige): Litige => ({
  id: l.id,
  cotisationId: l.cotisation_id,
  cercleId: l.cercle_id,
  payeurId: l.payeur_id,
  beneficiaireId: l.beneficiaire_id,
  ouvertPar: l.ouvert_par,
  motif: l.motif,
  ouvertLe: new Date(l.ouvert_le).toISOString(),
  statut: l.statut,
  ...(l.decision ? { decision: l.decision } : {}),
  ...(l.motif_decision ? { motifDecision: l.motif_decision } : {}),
  ...(l.tranche_par ? { tranchePar: l.tranche_par } : {}),
  ...(l.tranche_le ? { trancheLe: new Date(l.tranche_le).toISOString() } : {}),
});

/** Numéro de suivi communiqué par SMS : début de l'identifiant du litige. */
const numeroDeSuivi = (l: Litige) => l.id.slice(0, 8);

/**
 * Litige sur un paiement déclaré mais pas confirmé (choix de David, 05/11) : ouvert par le payeur après
 * 48 h, par le bénéficiaire qui dit n'avoir rien reçu, ou tout seul à la fin de grâce. Un administrateur
 * tranche (décision 04) ; il ne touche jamais l'argent, il valide ou refuse le paiement déclaré.
 */
@Injectable()
export class LitigesService {
  private readonly journal = new Logger("Litiges");

  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(FileSms) private readonly sms: FileSms,
    @Inject(PlanificateurService) private readonly planificateur: PlanificateurService,
  ) {
    this.evenements.ecouter("confirmation_manquante", async (e) => {
      await this.enregistrer(
        await this.cotisations.consulter(e.cotisationId),
        "automatique",
        "Fin du délai de grâce sans confirmation",
        new Date(),
        true,
      );
    });
    this.evenements.ecouter("cotisation_confirmee", (e) => this.clore(e.cotisationId));
  }

  async ouvrir(cotisationId: string, motif: string, parMembreId: string, maintenant = new Date()): Promise<Litige> {
    const c = await this.cotisations.consulter(cotisationId);
    const role = parMembreId === c.payeurId ? "payeur" : parMembreId === c.beneficiaireId ? "beneficiaire" : null;
    if (!role) throw new ForbiddenException("Seuls le payeur et le bénéficiaire ouvrent un litige");
    if (c.statut !== "declaree") throw new BadRequestException("Aucun paiement déclaré en attente de confirmation");
    if (role === "payeur" && maintenant.getTime() < Date.parse(c.declareeLe ?? "") + ATTENTE_PAYEUR_MS) {
      throw new BadRequestException("Le bénéficiaire a 48 h pour confirmer avant un litige");
    }
    return this.enregistrer(c, role, motif, maintenant, false);
  }

  async consulter(id: string, parMembreId: string): Promise<Litige> {
    const l = await this.trouver(id);
    if (![l.payeurId, l.beneficiaireId].includes(parMembreId) && !estAdministrateur(parMembreId)) {
      throw new ForbiddenException("Réservé aux parties et à l'administrateur");
    }
    return l;
  }

  async listerOuverts(parMembreId: string): Promise<Litige[]> {
    if (!estAdministrateur(parMembreId)) throw new ForbiddenException("Réservé à l'administrateur");
    const lignes = await this.base.requete<LigneLitige>(
      "SELECT * FROM litiges.litiges WHERE statut = 'ouvert' ORDER BY ouvert_le, id",
    );
    return lignes.map(versLitige);
  }

  /** Litiges où le membre est partie, du plus récent au plus ancien. */
  async listerPour(membreId: string): Promise<Litige[]> {
    const lignes = await this.base.requete<LigneLitige>(
      "SELECT * FROM litiges.litiges WHERE payeur_id = $1 OR beneficiaire_id = $1 ORDER BY ouvert_le DESC, id",
      [membreId],
    );
    return lignes.map(versLitige);
  }

  /**
   * Le litige est marqué tranché avant d'agir sur la cotisation : la confirmation qui en découle ne le clôt
   * pas une seconde fois. Si la cotisation refuse, le litige redevient ouvert.
   */
  async trancher(id: string, decision: Decision, motif: string, parMembreId: string, maintenant = new Date()) {
    if (!estAdministrateur(parMembreId)) throw new ForbiddenException("Réservé à l'administrateur");
    const avant = await this.trouver(id);
    if ([avant.payeurId, avant.beneficiaireId].includes(parMembreId)) {
      throw new ForbiddenException("Un administrateur ne tranche pas un litige où il est partie");
    }
    const [l] = await this.base.requete<LigneLitige>(
      `UPDATE litiges.litiges SET statut = 'tranche', decision = $2, motif_decision = $3, tranche_par = $4, tranche_le = $5
       WHERE id = $1 AND statut = 'ouvert' RETURNING *`,
      [id, decision, motif, parMembreId, maintenant.toISOString()],
    );
    if (!l) throw new BadRequestException("Litige déjà tranché ou clos");
    try {
      if (decision === "paiement_valide") await this.cotisations.validerApresLitige(avant.cotisationId);
      else await this.cotisations.remettreDueApresLitige(avant.cotisationId);
    } catch (e) {
      await this.base.requete(
        `UPDATE litiges.litiges SET statut = 'ouvert', decision = NULL, motif_decision = NULL, tranche_par = NULL,
         tranche_le = NULL WHERE id = $1`,
        [id],
      );
      throw e;
    }
    const tranche = versLitige(l);
    await this.registre.enregistrer(canonique({ objet: "decision_litige", ...tranche }));
    const { tour, finGrace } = await this.cotisations.consulter(tranche.cotisationId);
    // Refus après la fin de grâce : défaut constaté tout de suite (choix de David, 06/11), sinon une fausse
    // redéclaration avant le passage du planificateur l'éviterait. Même tâche que le planificateur : jamais
    // deux défauts pour un tour. La décision reste acquise si le constat échoue : erreur journalisée, et le
    // planificateur le constatera à son passage tant que la cotisation reste due.
    if (decision === "paiement_refuse" && maintenant.getTime() > Date.parse(finGrace)) {
      await this.planificateur.constaterDefaut(tranche.cercleId, tranche.payeurId, tour, maintenant).catch((e) => {
        this.journal.error(`Défaut après refus du litige ${tranche.id} non constaté : ${String(e)}`);
      });
    }
    const suivi = numeroDeSuivi(tranche);
    if (decision === "paiement_valide") {
      const texte = `MonDo : litige ${suivi} tranché, paiement validé. La cotisation du tour ${tour} est confirmée.`;
      await this.prevenir(tranche, "decision", { payeur: texte, beneficiaire: texte });
    } else {
      const debut = `MonDo : litige ${suivi} tranché, paiement refusé. La cotisation du tour ${tour} est de nouveau due`;
      await this.prevenir(tranche, "decision", {
        payeur: `${debut} : réglez-la vite pour éviter un défaut.`,
        beneficiaire: `${debut} par le payeur.`,
      });
    }
    return tranche;
  }

  private async enregistrer(
    c: Cotisation,
    ouvertPar: Litige["ouvertPar"],
    motif: string,
    maintenant: Date,
    siAbsent: boolean,
  ): Promise<Litige> {
    try {
      const [l] = await this.base.requete<LigneLitige>(
        `INSERT INTO litiges.litiges
           (id, cotisation_id, cercle_id, payeur_id, beneficiaire_id, ouvert_par, motif, ouvert_le, statut)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'ouvert') RETURNING *`,
        [randomUUID(), c.id, c.cercleId, c.payeurId, c.beneficiaireId, ouvertPar, motif, maintenant.toISOString()],
      );
      const litige = versLitige(l!);
      await this.cotisations.geler(c.id);
      await this.registre.enregistrer(canonique({ objet: "ouverture_litige", ...litige }));
      const texte =
        `MonDo : litige ouvert sur la cotisation du tour ${c.tour} (paiement déclaré, pas encore confirmé). ` +
        `Suivi ${numeroDeSuivi(litige)}. Un administrateur va trancher.`;
      await this.prevenir(litige, "ouverture", { payeur: texte, beneficiaire: texte });
      return litige;
    } catch (e) {
      if (!estDoublon(e)) throw e;
      if (siAbsent) return this.ouvertPour(c.id);
      throw new ConflictException("Un litige est déjà ouvert pour cette cotisation");
    }
  }

  private async clore(cotisationId: string): Promise<void> {
    const [l] = await this.base.requete<LigneLitige>(
      `UPDATE litiges.litiges SET statut = 'clos', decision = 'confirme_par_beneficiaire', tranche_le = now()
       WHERE cotisation_id = $1 AND statut = 'ouvert' RETURNING *`,
      [cotisationId],
    );
    if (!l) return;
    const clos = versLitige(l);
    const { tour } = await this.cotisations.consulter(cotisationId);
    const texte = `MonDo : litige ${numeroDeSuivi(clos)} clos, le bénéficiaire a confirmé le paiement du tour ${tour}.`;
    await this.prevenir(clos, "cloture", { payeur: texte, beneficiaire: texte });
  }

  /** SMS aux deux parties, par la file d'envoi : rejouable (clé par litige, étape et membre), jamais bloquant. */
  private async prevenir(
    l: Litige,
    etape: "ouverture" | "decision" | "cloture",
    textes: { payeur: string; beneficiaire: string },
  ): Promise<void> {
    for (const [membreId, texte] of [
      [l.payeurId, textes.payeur],
      [l.beneficiaireId, textes.beneficiaire],
    ] as const) {
      const compte = await this.comptes.chercher(membreId);
      if (compte) await this.sms.mettreEnFile(`litige:${l.id}:${etape}:${membreId}`, compte.numero, texte, membreId);
    }
    this.sms.declencher();
  }

  private async ouvertPour(cotisationId: string): Promise<Litige> {
    const [l] = await this.base.requete<LigneLitige>(
      "SELECT * FROM litiges.litiges WHERE cotisation_id = $1 AND statut = 'ouvert'",
      [cotisationId],
    );
    return versLitige(l!);
  }

  private async trouver(id: string): Promise<Litige> {
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw new NotFoundException("Litige introuvable");
    const [l] = await this.base.requete<LigneLitige>("SELECT * FROM litiges.litiges WHERE id = $1", [id]);
    if (!l) throw new NotFoundException("Litige introuvable");
    return versLitige(l);
  }
}
