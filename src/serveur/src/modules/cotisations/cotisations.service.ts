import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";

export interface Cotisation {
  id: string;
  cercleId: string;
  payeurId: string;
  beneficiaireId: string;
  montant: number;
  dateLimite: string;
  referenceTransaction?: string;
  statut: "due" | "declaree" | "confirmee";
}

interface LigneCotisation extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  payeur_id: string;
  beneficiaire_id: string;
  montant: string | number;
  date_limite: Date | string;
  reference_transaction: string | null;
  statut: Cotisation["statut"];
}

const versCotisation = (l: LigneCotisation): Cotisation => ({
  id: l.id,
  cercleId: l.cercle_id,
  payeurId: l.payeur_id,
  beneficiaireId: l.beneficiaire_id,
  montant: Number(l.montant),
  dateLimite: new Date(l.date_limite).toISOString(),
  ...(l.reference_transaction ? { referenceTransaction: l.reference_transaction } : {}),
  statut: l.statut,
});

/** Le bénéficiaire confirme la réception : le silence ne vaut jamais confirmation. */
@Injectable()
export class CotisationsService {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {}

  async creer(d: Omit<Cotisation, "id" | "statut" | "referenceTransaction">): Promise<Cotisation> {
    const [l] = await this.base.requete<LigneCotisation>(
      `INSERT INTO cotisations.cotisations (id, cercle_id, payeur_id, beneficiaire_id, montant, date_limite, statut)
       VALUES ($1, $2, $3, $4, $5, $6, 'due') RETURNING *`,
      [randomUUID(), d.cercleId, d.payeurId, d.beneficiaireId, d.montant, d.dateLimite],
    );
    return versCotisation(l!);
  }

  async declarerPaiement(id: string, referenceTransaction: string, parMembreId: string): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.payeurId) throw new ForbiddenException("Seul le payeur déclare son paiement");
    const [l] = await this.base.requete<LigneCotisation>(
      `UPDATE cotisations.cotisations SET reference_transaction = $2, statut = 'declaree'
       WHERE id = $1 AND statut <> 'confirmee' RETURNING *`,
      [id, referenceTransaction],
    );
    if (!l) throw new BadRequestException("Cotisation déjà confirmée");
    return versCotisation(l);
  }

  async confirmer(id: string, parMembreId: string, maintenant: Date = new Date()): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.beneficiaireId) throw new ForbiddenException("Seul le bénéficiaire peut confirmer");
    // Mise à jour conditionnelle : deux confirmations simultanées ne comptent qu'une fois.
    const [l] = await this.base.requete<LigneCotisation>(
      "UPDATE cotisations.cotisations SET statut = 'confirmee' WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à confirmer");
    const confirmee = versCotisation(l);
    await this.evenements.publier({
      type: "cotisation_confirmee",
      cercleId: confirmee.cercleId,
      membreId: confirmee.payeurId,
      aTemps: maintenant <= new Date(confirmee.dateLimite),
    });
    return confirmee;
  }

  /** Cotisations ni payées ni déclarées, pour l'examen des échéances. */
  async listerDues(): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE statut = 'due' ORDER BY date_limite, id",
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
