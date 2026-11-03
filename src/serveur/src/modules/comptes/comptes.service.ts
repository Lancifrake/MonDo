import { ConflictException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { messageInscription } from "../../authentification/messages.js";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { verifierSignature } from "../../signature/signature.js";

export interface Compte {
  id: string;
  numero: string;
  nom: string;
  /** 1 = numéro et nom ; 2 = identité vérifiée (simulée au prototype). */
  niveau: 1 | 2;
  clePublique: JsonWebKey;
}

interface LigneCompte extends Record<string, unknown> {
  id: string;
  numero: string;
  nom: string;
  niveau: number;
  cle_publique: JsonWebKey;
}

const versCompte = (l: LigneCompte): Compte => ({
  id: l.id,
  numero: l.numero,
  nom: l.nom,
  niveau: l.niveau === 2 ? 2 : 1,
  clePublique: l.cle_publique,
});

/** Le serveur ne connaît que la clé publique : la clé privée reste dans le téléphone. */
@Injectable()
export class ComptesService {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  /** La forme des données est validée en amont (schemaInscription) ; ici, les règles métier. */
  async inscrire(d: { numero: string; nom: string; clePublique: JsonWebKey; preuve: string }): Promise<Compte> {
    const { preuve, ...donnees } = d;
    if (!verifierSignature(donnees.clePublique, messageInscription(donnees), preuve)) {
      throw new ForbiddenException("Preuve de détention de la clé invalide");
    }
    try {
      const [ligne] = await this.base.requete<LigneCompte>(
        "INSERT INTO comptes.comptes (id, numero, nom, niveau, cle_publique) VALUES ($1, $2, $3, 1, $4) RETURNING *",
        [randomUUID(), donnees.numero, donnees.nom, JSON.stringify(donnees.clePublique)],
      );
      return versCompte(ligne!);
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Numéro déjà inscrit");
      throw e;
    }
  }

  /** Vérification d'identité simulée au prototype (prestataire réel en V2). */
  async passerAuNiveau2(id: string): Promise<Compte> {
    const [ligne] = await this.base.requete<LigneCompte>(
      "UPDATE comptes.comptes SET niveau = 2 WHERE id = $1 RETURNING *",
      [id],
    );
    if (!ligne) throw new NotFoundException("Compte introuvable");
    return versCompte(ligne);
  }

  async chercher(id: string): Promise<Compte | undefined> {
    if (!/^[0-9a-f-]{36}$/i.test(id)) return undefined;
    const [ligne] = await this.base.requete<LigneCompte>("SELECT * FROM comptes.comptes WHERE id = $1", [id]);
    return ligne && versCompte(ligne);
  }

  async trouver(id: string): Promise<Compte> {
    const compte = await this.chercher(id);
    if (!compte) throw new NotFoundException("Compte introuvable");
    return compte;
  }

  /** Anti-rejeu stocké en base : plusieurs copies du serveur partagent la même mémoire (décision 02, règle 3). */
  async marquerSignatureUtilisee(signature: string, expireLe: Date): Promise<boolean> {
    await this.base.requete("DELETE FROM comptes.signatures_vues WHERE expire_le < now()");
    const lignes = await this.base.requete(
      "INSERT INTO comptes.signatures_vues (signature, expire_le) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING signature",
      [signature, expireLe.toISOString()],
    );
    return lignes.length === 1;
  }
}
