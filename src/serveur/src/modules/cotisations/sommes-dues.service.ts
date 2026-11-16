import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { estAdministrateur } from "../../administration/administrateurs.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";

export type NatureSomme = "frais_mondo" | "remise" | "remboursement_depart";

/**
 * Somme due entre deux membres, ou d'un membre à MonDo, en dehors des cotisations : part de MonDo et remise
 * aux places de fin (modèle A), remboursement après un départ. Suivie comme une cotisation : due, déclarée
 * par celui qui paie, confirmée par celui qui reçoit. MonDo ne détient jamais ces fonds : le paiement se fait
 * par Mobile Money, hors de MonDo.
 */
export interface SommeDue {
  id: string;
  cercleId: string;
  nature: NatureSomme;
  debiteurId: string;
  /** Absent : la somme revient à MonDo, confirmée par un Administrateur. */
  creancierId?: string;
  montant: number;
  /** Tour du bénéficiaire qui doit les frais ; 0 pour un remboursement. */
  tour: number;
  exigibleLe: string;
  dateLimite: string;
  referenceTransaction?: string;
  declareeLe?: string;
  statut: "due" | "declaree" | "confirmee" | "annulee";
}

/** Ce que voit l'Administrateur : la somme, plus de quoi savoir qui a payé et pour quel cercle. */
export interface SommeDuePourAdministrateur extends SommeDue {
  /** Null si le compte a disparu : la somme reste listée, l'identifiant suffit à la retrouver. */
  debiteur: { nom: string; numero: string } | null;
  cercle: { organisateur: string | null; montant: number; nombreMembres: number } | null;
}

interface LigneSomme extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  nature: NatureSomme;
  debiteur_id: string;
  creancier_id: string | null;
  montant: string | number;
  tour: number;
  exigible_le: Date | string;
  date_limite: Date | string;
  reference_transaction: string | null;
  declaree_le: Date | string | null;
  statut: SommeDue["statut"];
}

const versSomme = (l: LigneSomme): SommeDue => ({
  id: l.id,
  cercleId: l.cercle_id,
  nature: l.nature,
  debiteurId: l.debiteur_id,
  ...(l.creancier_id ? { creancierId: l.creancier_id } : {}),
  montant: Number(l.montant),
  tour: l.tour,
  exigibleLe: new Date(l.exigible_le).toISOString(),
  dateLimite: new Date(l.date_limite).toISOString(),
  ...(l.reference_transaction ? { referenceTransaction: l.reference_transaction } : {}),
  ...(l.declaree_le ? { declareeLe: new Date(l.declaree_le).toISOString() } : {}),
  statut: l.statut,
});

const UUID = /^[0-9a-f-]{36}$/i;

@Injectable()
export class SommesDuesService {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  /** Ce que je dois et ce qu'on me doit, dans un cercle ou dans tous. Rien sur les autres membres. */
  async listerPour(membreId: string, cercleId?: string): Promise<SommeDue[]> {
    const lignes = await this.base.requete<LigneSomme>(
      `SELECT * FROM cotisations.sommes_dues
       WHERE (debiteur_id = $1 OR creancier_id = $1) AND ($2::text IS NULL OR cercle_id = $2)
       ORDER BY exigible_le, id`,
      [membreId, cercleId ?? null],
    );
    return lignes.map(versSomme);
  }

  /**
   * Parts de MonDo déclarées, en attente de confirmation par un Administrateur. Avec de quoi rapprocher la
   * référence du compte marchand : nom et numéro de celui qui a payé, organisateur et montant du cercle
   * (un cercle n'a pas de nom).
   */
  async listerPourAdministrateur(parMembreId: string): Promise<SommeDuePourAdministrateur[]> {
    if (!estAdministrateur(parMembreId)) throw new ForbiddenException("Réservé à l'administrateur");
    const lignes = await this.base.requete<
      LigneSomme & {
        debiteur_nom: string | null;
        debiteur_numero: string | null;
        organisateur_nom: string | null;
        cercle_montant: string | number | null;
        cercle_nombre_membres: number | null;
      }
    >(
      `SELECT s.*, d.nom AS debiteur_nom, d.numero AS debiteur_numero, o.nom AS organisateur_nom,
              (c.reglement ->> 'montant')::bigint AS cercle_montant,
              (c.reglement ->> 'nombreMembres')::int AS cercle_nombre_membres
       FROM cotisations.sommes_dues s
       LEFT JOIN comptes.comptes d ON d.id = s.debiteur_id
       LEFT JOIN cercles.cercles c ON c.id::text = s.cercle_id
       LEFT JOIN comptes.comptes o ON o.id = c.organisateur_id
       WHERE s.creancier_id IS NULL AND s.statut = 'declaree'
       ORDER BY s.declaree_le, s.id`,
    );
    return lignes.map((l) => ({
      ...versSomme(l),
      debiteur: l.debiteur_nom ? { nom: l.debiteur_nom, numero: l.debiteur_numero ?? "" } : null,
      cercle:
        l.cercle_montant !== null
          ? {
              organisateur: l.organisateur_nom,
              montant: Number(l.cercle_montant),
              nombreMembres: l.cercle_nombre_membres ?? 0,
            }
          : null,
    }));
  }

  /** Celui qui doit déclare son paiement, une fois la somme exigible (le jour de sa cagnotte pour des frais). */
  async declarerPaiement(
    id: string,
    reference: string,
    parMembreId: string,
    maintenant = new Date(),
  ): Promise<SommeDue> {
    const s = await this.trouver(id);
    if (parMembreId !== s.debiteurId) throw new ForbiddenException("Seul celui qui doit la somme déclare son paiement");
    if (maintenant.getTime() < Date.parse(s.exigibleLe)) {
      throw new BadRequestException("Somme pas encore exigible : elle se règle après réception de la cagnotte");
    }
    const [l] = await this.base.requete<LigneSomme>(
      `UPDATE cotisations.sommes_dues SET reference_transaction = $2, statut = 'declaree', declaree_le = $3
       WHERE id = $1 AND statut IN ('due', 'declaree') RETURNING *`,
      [id, reference, maintenant.toISOString()],
    );
    if (!l) throw new BadRequestException(s.statut === "annulee" ? "Somme annulée" : "Somme déjà confirmée");
    return versSomme(l);
  }

  /**
   * Celui qui reçoit confirme : le membre créancier, ou un Administrateur pour la part de MonDo. Jamais celui
   * qui doit la somme, même s'il est Administrateur. Le silence ne vaut pas confirmation.
   */
  async confirmer(id: string, parMembreId: string): Promise<SommeDue> {
    const s = await this.trouver(id);
    const autorise = s.creancierId
      ? parMembreId === s.creancierId
      : estAdministrateur(parMembreId) && parMembreId !== s.debiteurId;
    if (!autorise) throw new ForbiddenException("Seul celui qui reçoit la somme confirme sa réception");
    // Mise à jour conditionnelle : deux confirmations simultanées ne comptent qu'une fois.
    const [l] = await this.base.requete<LigneSomme>(
      "UPDATE cotisations.sommes_dues SET statut = 'confirmee', confirmee_le = now() WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à confirmer");
    return versSomme(l);
  }

  private async trouver(id: string): Promise<SommeDue> {
    const [l] = UUID.test(id)
      ? await this.base.requete<LigneSomme>("SELECT * FROM cotisations.sommes_dues WHERE id = $1", [id])
      : [];
    if (!l) throw new NotFoundException("Somme introuvable");
    return versSomme(l);
  }
}
