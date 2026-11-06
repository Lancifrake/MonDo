import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes, type CercleComplet } from "../../evenements/evenements-internes.js";
import { calendrierDesTours } from "./calendrier.js";

const JOUR_MS = 24 * 60 * 60 * 1000;

export interface Cotisation {
  id: string;
  cercleId: string;
  payeurId: string;
  beneficiaireId: string;
  montant: number;
  /** Numéro du tour ; 0 pour une cotisation créée à la main avant le 05/11 (prototype). */
  tour: number;
  dateLimite: string;
  /** Au-delà, la cotisation non payée devient un défaut (délai de grâce du règlement). */
  finGrace: string;
  referenceTransaction?: string;
  /** Moment de la déclaration du paiement par le payeur. */
  declareeLe?: string;
  statut: "due" | "declaree" | "confirmee";
}

export interface BilanDeCycle {
  cercleId: string;
  membreId: string;
  /** Fin de grâce du dernier tour du cercle. */
  finCycle: string;
  toutConfirme: boolean;
}

interface LigneCotisation extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  payeur_id: string;
  beneficiaire_id: string;
  montant: string | number;
  tour: number | null;
  date_limite: Date | string;
  fin_grace: Date | string | null;
  reference_transaction: string | null;
  declaree_le?: Date | string | null;
  statut: Cotisation["statut"];
}

const versCotisation = (l: LigneCotisation): Cotisation => ({
  id: l.id,
  cercleId: l.cercle_id,
  payeurId: l.payeur_id,
  beneficiaireId: l.beneficiaire_id,
  montant: Number(l.montant),
  tour: l.tour ?? 0,
  dateLimite: new Date(l.date_limite).toISOString(),
  finGrace: new Date(l.fin_grace ?? l.date_limite).toISOString(),
  ...(l.reference_transaction ? { referenceTransaction: l.reference_transaction } : {}),
  ...(l.declaree_le ? { declareeLe: new Date(l.declaree_le).toISOString() } : {}),
  statut: l.statut,
});

/** Le bénéficiaire confirme la réception : le silence ne vaut jamais confirmation. */
@Injectable()
export class CotisationsService {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {
    this.evenements.ecouter("cercle_complet", (e) => this.planifierTours(e));
  }

  /**
   * Tours et cotisations du cycle, créés d'un coup quand le cercle est complet : chaque membre doit le
   * montant du règlement à chaque bénéficiaire sauf lui-même. Rejouable : un cercle déjà planifié est ignoré.
   */
  async planifierTours(c: CercleComplet): Promise<void> {
    const tours = calendrierDesTours(c);
    await this.base.transaction(async (tx) => {
      const [deja] = await tx.requete("SELECT 1 FROM cotisations.tours WHERE cercle_id = $1 LIMIT 1", [c.cercleId]);
      if (deja) return;
      for (const t of tours) {
        await tx.requete(
          "INSERT INTO cotisations.tours (cercle_id, numero, beneficiaire_id, date_limite) VALUES ($1, $2, $3, $4)",
          [c.cercleId, t.numero, t.beneficiaireId, t.dateLimite],
        );
        const finGrace = new Date(Date.parse(t.dateLimite) + c.delaiGraceJours * JOUR_MS).toISOString();
        for (const payeurId of c.ordre.filter((m) => m !== t.beneficiaireId)) {
          await tx.requete(
            `INSERT INTO cotisations.cotisations
               (id, cercle_id, payeur_id, beneficiaire_id, montant, tour, date_limite, fin_grace, statut)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'due')`,
            [randomUUID(), c.cercleId, payeurId, t.beneficiaireId, c.montant, t.numero, t.dateLimite, finGrace],
          );
        }
      }
    });
  }

  async declarerPaiement(id: string, referenceTransaction: string, parMembreId: string): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.payeurId) throw new ForbiddenException("Seul le payeur déclare son paiement");
    // Pendant un litige ouvert, la déclaration est gelée : l'administrateur tranche sur la pièce d'origine.
    const [l] = await this.base.requete<LigneCotisation>(
      `UPDATE cotisations.cotisations SET reference_transaction = $2, statut = 'declaree', declaree_le = now()
       WHERE id = $1 AND statut <> 'confirmee' AND NOT en_litige RETURNING *`,
      [id, referenceTransaction],
    );
    if (!l) {
      throw new BadRequestException(
        c.statut === "confirmee"
          ? "Cotisation déjà confirmée"
          : "Litige en cours : la déclaration est gelée jusqu'à la décision de l'administrateur",
      );
    }
    return versCotisation(l);
  }

  /** Litige ouvert sur cette cotisation : le payeur ne peut plus changer sa déclaration jusqu'à la décision. */
  async geler(id: string): Promise<void> {
    await this.base.requete("UPDATE cotisations.cotisations SET en_litige = true WHERE id = $1", [id]);
  }

  async confirmer(id: string, parMembreId: string, maintenant: Date = new Date()): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.beneficiaireId) throw new ForbiddenException("Seul le bénéficiaire peut confirmer");
    // Mise à jour conditionnelle : deux confirmations simultanées ne comptent qu'une fois.
    const [l] = await this.base.requete<LigneCotisation>(
      "UPDATE cotisations.cotisations SET statut = 'confirmee', en_litige = false WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à confirmer");
    const confirmee = versCotisation(l);
    await this.publierConfirmation(confirmee, maintenant <= new Date(confirmee.dateLimite));
    return confirmee;
  }

  /**
   * Décision d'un litige : paiement validé par l'administrateur. À temps si le paiement avait été déclaré
   * avant la date limite : le payeur ne paie pas le retard de confirmation du bénéficiaire.
   */
  async validerApresLitige(id: string): Promise<Cotisation> {
    const [l] = await this.base.requete<LigneCotisation>(
      "UPDATE cotisations.cotisations SET statut = 'confirmee', en_litige = false WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à valider");
    const validee = versCotisation(l);
    await this.publierConfirmation(validee, Date.parse(validee.declareeLe!) <= Date.parse(validee.dateLimite));
    return validee;
  }

  /** Décision d'un litige : paiement refusé, la cotisation redevient due (défaut si la grâce est passée). */
  async remettreDueApresLitige(id: string): Promise<Cotisation> {
    const [l] = await this.base.requete<LigneCotisation>(
      `UPDATE cotisations.cotisations SET statut = 'due', reference_transaction = NULL, declaree_le = NULL,
         en_litige = false
       WHERE id = $1 AND statut = 'declaree' RETURNING *`,
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à refuser");
    return versCotisation(l);
  }

  async consulter(id: string): Promise<Cotisation> {
    return this.trouver(id);
  }

  private publierConfirmation(c: Cotisation, aTemps: boolean): Promise<void> {
    return this.evenements.publier({
      type: "cotisation_confirmee",
      cercleId: c.cercleId,
      membreId: c.payeurId,
      cotisationId: c.id,
      aTemps,
    });
  }

  /** Cotisations ni payées ni déclarées, pour l'examen des échéances. */
  async listerDues(): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE statut = 'due' ORDER BY date_limite, id",
    );
    return lignes.map(versCotisation);
  }

  /**
   * Pour chaque cercle et chaque payeur : fin du cycle (fin de grâce la plus tardive du cercle) et
   * « tout confirmé » (le bénéficiaire a confirmé toutes ses cotisations). Pour le planificateur.
   */
  async bilansDeCycle(): Promise<BilanDeCycle[]> {
    const lignes = await this.base.requete<{
      cercle_id: string;
      payeur_id: string;
      tout_confirme: boolean;
      fin_cycle: Date | string;
    }>(
      `SELECT cercle_id, payeur_id, bool_and(statut = 'confirmee') AS tout_confirme,
              max(max(fin_grace)) OVER (PARTITION BY cercle_id) AS fin_cycle
       FROM cotisations.cotisations WHERE tour > 0
       GROUP BY cercle_id, payeur_id ORDER BY cercle_id, payeur_id`,
    );
    return lignes.map((l) => ({
      cercleId: l.cercle_id,
      membreId: l.payeur_id,
      toutConfirme: l.tout_confirme,
      finCycle: new Date(l.fin_cycle).toISOString(),
    }));
  }

  /** Paiements déclarés mais pas encore confirmés, pour l'ouverture automatique des litiges. */
  async listerDeclarees(): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE statut = 'declaree' AND tour > 0 ORDER BY date_limite, id",
    );
    return lignes.map(versCotisation);
  }

  /** Ce que le membre doit et ce qu'on lui doit dans un cercle, par tour. Rien sur les autres membres. */
  async listerDuMembre(cercleId: string, membreId: string): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      `SELECT * FROM cotisations.cotisations WHERE cercle_id = $1 AND (payeur_id = $2 OR beneficiaire_id = $2)
       ORDER BY tour, date_limite, id`,
      [cercleId, membreId],
    );
    return lignes.map(versCotisation);
  }

  /** Relevé d'un payeur dans un cercle, du plus ancien au plus récent. */
  async listerPour(cercleId: string, payeurId: string): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE cercle_id = $1 AND payeur_id = $2 ORDER BY date_limite, id",
      [cercleId, payeurId],
    );
    return lignes.map(versCotisation);
  }

  private async trouver(id: string): Promise<Cotisation> {
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw new NotFoundException("Cotisation introuvable");
    const [l] = await this.base.requete<LigneCotisation>("SELECT * FROM cotisations.cotisations WHERE id = $1", [id]);
    if (!l) throw new NotFoundException("Cotisation introuvable");
    return versCotisation(l);
  }
}
