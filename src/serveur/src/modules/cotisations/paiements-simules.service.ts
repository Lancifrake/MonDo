import { BadRequestException, ConflictException, ForbiddenException, Inject, Injectable } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import {
  CONNECTEUR_MOBILE_MONEY,
  type ConnecteurMobileMoney,
  type IssueSimulee,
  type Operateur,
} from "../../paiement/connecteur-mobile-money.js";
import { FileSms } from "../../sms/file-sms.js";
import { fcfa } from "../../sms/montant.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { CotisationsService } from "./cotisations.service.js";

export interface PaiementSimule {
  id: string;
  cotisationId: string;
  operateur: Operateur;
  issue: IssueSimulee;
  statut: "en_attente_operateur" | "reussi" | "echoue";
  referenceOperateur?: string;
  motif?: string;
  initieLe: string;
  retourLe?: string;
}

interface LignePaiement extends Record<string, unknown> {
  id: string;
  cotisation_id: string;
  operateur: Operateur;
  issue: IssueSimulee;
  statut: PaiementSimule["statut"];
  reference_operateur: string | null;
  motif: string | null;
  initie_le: Date | string;
  retour_le: Date | string | null;
}

const versPaiement = (l: LignePaiement): PaiementSimule => ({
  id: l.id,
  cotisationId: l.cotisation_id,
  operateur: l.operateur,
  issue: l.issue,
  statut: l.statut,
  ...(l.reference_operateur ? { referenceOperateur: l.reference_operateur } : {}),
  ...(l.motif ? { motif: l.motif } : {}),
  initieLe: new Date(l.initie_le).toISOString(),
  ...(l.retour_le ? { retourLe: new Date(l.retour_le).toISOString() } : {}),
});

const NOM_OPERATEUR: Record<Operateur, string> = { orange_money: "Orange Money", mtn_momo: "MTN MoMo" };

/**
 * Paiement Mobile Money simulé (cahier des charges, M4), hors production seulement. Le payeur demande un
 * paiement à l'opérateur simulé avec l'issue de son choix. Réussi : le retour de l'opérateur déclare le paiement
 * avec sa référence, et le bénéficiaire est prié de confirmer (le retour ne remplace jamais sa confirmation).
 * Échoué : rien n'est déclaré. En retard : le planificateur traite le retour quand il arrive.
 */
@Injectable()
export class PaiementsSimulesService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CONNECTEUR_MOBILE_MONEY) private readonly operateur: ConnecteurMobileMoney,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  async payer(
    cotisationId: string,
    payeurId: string,
    operateur: Operateur,
    issue: IssueSimulee,
    maintenant = new Date(),
  ): Promise<PaiementSimule> {
    if (process.env.NODE_ENV === "production") {
      throw new ForbiddenException("Paiement simulé désactivé en production : le paiement réel se fait hors de MonDo");
    }
    const c = await this.cotisations.consulter(cotisationId);
    if (c.payeurId !== payeurId) throw new ForbiddenException("Seul le payeur paie sa cotisation");
    if (c.statut !== "due" || c.enLitige) throw new BadRequestException("Cette cotisation n'est plus à payer");
    const reponse = await this.operateur.demanderPaiement({ operateur, montant: c.montant, issue });
    const id = randomUUID();
    try {
      await this.base.requete(
        `INSERT INTO cotisations.paiements_simules
           (id, cotisation_id, payeur_id, operateur, issue, statut, reference_operateur, initie_le, retour_prevu_le)
         VALUES ($1, $2, $3, $4, $5, 'en_attente_operateur', $6, $7, $8)`,
        [
          id,
          cotisationId,
          payeurId,
          operateur,
          issue,
          reponse.referenceOperateur,
          maintenant.toISOString(),
          new Date(maintenant.getTime() + (reponse.retourDansMs ?? 0)).toISOString(),
        ],
      );
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Un paiement attend déjà la réponse de l'opérateur");
      throw e;
    }
    if (reponse.retour) await this.recevoirRetour(id, reponse.retour.statut, reponse.retour.motif, maintenant);
    return this.trouver(id);
  }

  async lister(cotisationId: string, demandeurId: string): Promise<PaiementSimule[]> {
    const c = await this.cotisations.consulter(cotisationId);
    if (![c.payeurId, c.beneficiaireId].includes(demandeurId)) {
      throw new ForbiddenException("Réservé au payeur et au bénéficiaire");
    }
    const lignes = await this.base.requete<LignePaiement>(
      "SELECT * FROM cotisations.paiements_simules WHERE cotisation_id = $1 ORDER BY initie_le, id",
      [cotisationId],
    );
    return lignes.map(versPaiement);
  }

  /** Retours d'opérateur arrivés à échéance (issue « en retard »), traités par le planificateur. Rejouable. */
  async traiterRetoursEnAttente(maintenant: Date): Promise<number> {
    const prets = await this.base.requete<{ id: string }>(
      `SELECT id FROM cotisations.paiements_simules
       WHERE statut = 'en_attente_operateur' AND retour_prevu_le <= $1 ORDER BY retour_prevu_le, id`,
      [maintenant.toISOString()],
    );
    for (const p of prets) await this.recevoirRetour(p.id, "reussi", undefined, maintenant);
    return prets.length;
  }

  /**
   * Retour de l'opérateur, une seule fois par paiement (mise à jour conditionnelle). Réussi : le paiement est
   * déclaré si la cotisation est toujours à payer ; le bénéficiaire est prié de confirmer. Échoué : le payeur est
   * prévenu et la cotisation reste à payer.
   */
  private async recevoirRetour(id: string, statut: "reussi" | "echoue", motif: string | undefined, maintenant: Date) {
    const [l] = await this.base.requete<LignePaiement & { payeur_id: string }>(
      `UPDATE cotisations.paiements_simules SET statut = $2, motif = $3, retour_le = $4
       WHERE id = $1 AND statut = 'en_attente_operateur' RETURNING *`,
      [id, statut, motif ?? null, maintenant.toISOString()],
    );
    if (!l) return;
    const c = await this.cotisations.consulter(l.cotisation_id);
    if (statut === "echoue") {
      await this.prevenir(
        `mm:${id}:echec`,
        l.payeur_id,
        `MonDo : paiement ${NOM_OPERATEUR[l.operateur]} échoué (${motif ?? "refusé"}). La cotisation du tour ${c.tour} reste à payer.`,
      );
      return;
    }
    if (c.statut !== "due" || c.enLitige) return;
    await this.cotisations.declarerPaiement(c.id, l.reference_operateur!, l.payeur_id);
    await this.prevenir(
      `mm:${id}:recu`,
      c.beneficiaireId,
      `MonDo : ${fcfa(c.montant)} vous ont été envoyés par ${NOM_OPERATEUR[l.operateur]} (paiement simulé, tour ${c.tour}). ` +
        "Vérifiez votre compte, puis confirmez la réception dans l'application.",
    );
  }

  private async prevenir(cle: string, membreId: string, texte: string) {
    const compte = await this.comptes.chercher(membreId);
    if (!compte) return;
    await this.sms.mettreEnFile(cle, compte.numero, texte);
    this.sms.declencher();
  }

  private async trouver(id: string): Promise<PaiementSimule> {
    const [l] = await this.base.requete<LignePaiement>("SELECT * FROM cotisations.paiements_simules WHERE id = $1", [
      id,
    ]);
    return versPaiement(l!);
  }
}
