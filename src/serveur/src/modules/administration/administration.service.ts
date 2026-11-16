import { ForbiddenException, Inject, Injectable } from "@nestjs/common";
import { estAdministrateur } from "../../administration/administrateurs.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";

/** Un compte vu par l'Administrateur. Aucune pièce d'identité, aucune clé : seulement de quoi s'y retrouver. */
export interface CompteListe {
  id: string;
  nom: string;
  numero: string;
  /** 1 : identité non vérifiée ; 2 : pièce d'identité validée. */
  niveau: 1 | 2;
  creeLe: string;
  /** Cercles où le compte est membre et n'est pas parti. */
  cerclesActifs: number;
  /** Blocage en cours (essais de code secret ratés, ou opposition à une récupération). */
  blocage: { motif: "essais_rates" | "opposition"; bloqueLe: string } | null;
  /** Une pièce d'identité attend la décision d'un Administrateur. */
  verificationEnAttente: boolean;
}

/** Un cercle vu par l'Administrateur. Un cercle n'a pas de nom : on le reconnaît à son organisateur et à son montant. */
export interface CercleListe {
  id: string;
  statut: "en_attente" | "complet" | "termine";
  creeLe: string;
  termineLe: string | null;
  organisateur: { nom: string; numero: string } | null;
  reglement: { montant: number; frequence: string; periodeJours: number | null; nombreMembres: number };
  /** Membres inscrits qui ne sont pas partis. */
  membres: number;
  /** Tours dont toutes les cotisations sont confirmées, sur le nombre de tours du cercle. */
  toursTermines: number;
  toursTotal: number;
  litigesOuverts: number;
}

@Injectable()
export class AdministrationService {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  private exigerAdministrateur(membreId: string): void {
    if (!estAdministrateur(membreId)) throw new ForbiddenException("Réservé à l'administrateur");
  }

  /** Tous les comptes, du plus récent au plus ancien. Lecture seule. */
  async listerComptes(parMembreId: string): Promise<CompteListe[]> {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<{
      id: string;
      nom: string;
      numero: string;
      niveau: number;
      cree_le: Date | string;
      cercles_actifs: string | number;
      blocage_motif: CompteListe["blocage"] extends infer B ? (B extends { motif: infer M } ? M : never) : never;
      blocage_le: Date | string | null;
      verification: boolean;
    }>(
      `SELECT c.id, c.nom, c.numero, c.niveau, c.cree_le,
              (SELECT count(*) FROM cercles.adhesions a WHERE a.membre_id = c.id AND a.parti_le IS NULL) AS cercles_actifs,
              b.motif AS blocage_motif, b.bloque_le AS blocage_le,
              EXISTS (SELECT 1 FROM comptes.verifications_identite v WHERE v.compte_id = c.id AND v.statut = 'en_attente') AS verification
       FROM comptes.comptes c
       LEFT JOIN comptes.blocages b ON b.compte_id = c.id AND b.leve_le IS NULL
       ORDER BY c.cree_le DESC, c.id`,
    );
    return lignes.map((l) => ({
      id: l.id,
      nom: l.nom,
      numero: l.numero,
      niveau: l.niveau === 2 ? 2 : 1,
      creeLe: new Date(l.cree_le).toISOString(),
      cerclesActifs: Number(l.cercles_actifs),
      blocage: l.blocage_le ? { motif: l.blocage_motif, bloqueLe: new Date(l.blocage_le).toISOString() } : null,
      verificationEnAttente: l.verification,
    }));
  }

  /** Tous les cercles, du plus récent au plus ancien. Lecture seule : ni membres ni ordre, réservés aux membres. */
  async listerCercles(parMembreId: string): Promise<CercleListe[]> {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<{
      id: string;
      statut: CercleListe["statut"];
      cree_le: Date | string;
      termine_le: Date | string | null;
      organisateur_nom: string | null;
      organisateur_numero: string | null;
      montant: string | number;
      frequence: string;
      periode_jours: number | null;
      nombre_membres: number;
      membres: string | number;
      tours_termines: string | number;
      litiges_ouverts: string | number;
    }>(
      `SELECT c.id, c.statut, c.cree_le, c.termine_le, o.nom AS organisateur_nom, o.numero AS organisateur_numero,
              (c.reglement ->> 'montant')::bigint AS montant, c.reglement ->> 'frequence' AS frequence,
              (c.reglement ->> 'periodeJours')::int AS periode_jours, (c.reglement ->> 'nombreMembres')::int AS nombre_membres,
              (SELECT count(*) FROM cercles.adhesions a WHERE a.cercle_id = c.id AND a.parti_le IS NULL) AS membres,
              (SELECT count(*) FROM cotisations.tours t WHERE t.cercle_id = c.id::text AND NOT EXISTS (
                 SELECT 1 FROM cotisations.cotisations k
                 WHERE k.cercle_id = t.cercle_id AND k.tour = t.numero AND k.statut <> 'confirmee')) AS tours_termines,
              (SELECT count(*) FROM litiges.litiges l WHERE l.cercle_id = c.id::text AND l.statut = 'ouvert') AS litiges_ouverts
       FROM cercles.cercles c
       LEFT JOIN comptes.comptes o ON o.id = c.organisateur_id
       ORDER BY c.cree_le DESC, c.id`,
    );
    return lignes.map((l) => ({
      id: l.id,
      statut: l.statut,
      creeLe: new Date(l.cree_le).toISOString(),
      termineLe: l.termine_le ? new Date(l.termine_le).toISOString() : null,
      organisateur: l.organisateur_nom ? { nom: l.organisateur_nom, numero: l.organisateur_numero ?? "" } : null,
      reglement: {
        montant: Number(l.montant),
        frequence: l.frequence,
        periodeJours: l.periode_jours,
        nombreMembres: l.nombre_membres,
      },
      membres: Number(l.membres),
      toursTermines: Number(l.tours_termines),
      toursTotal: l.nombre_membres,
      litigesOuverts: Number(l.litiges_ouverts),
    }));
  }
}
