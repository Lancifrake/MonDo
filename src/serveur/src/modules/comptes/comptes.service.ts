import { ConflictException, ForbiddenException, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { messageInscription } from "../../authentification/messages.js";
import { verifierSignature } from "../../signature/signature.js";

export interface Compte {
  id: string;
  numero: string;
  nom: string;
  /** 1 = numéro et nom ; 2 = identité vérifiée (simulée au prototype). */
  niveau: 1 | 2;
  clePublique: JsonWebKey;
}

/** Le serveur ne connaît que la clé publique : la clé privée reste dans le téléphone. */
@Injectable()
export class ComptesService {
  private readonly comptes = new Map<string, Compte>();

  /** La forme des données est validée en amont (schemaInscription) ; ici, les règles métier. */
  inscrire(d: { numero: string; nom: string; clePublique: JsonWebKey; preuve: string }): Compte {
    const { preuve, ...donnees } = d;
    if (!verifierSignature(donnees.clePublique, messageInscription(donnees), preuve)) {
      throw new ForbiddenException("Preuve de détention de la clé invalide");
    }
    if ([...this.comptes.values()].some((c) => c.numero === donnees.numero)) {
      throw new ConflictException("Numéro déjà inscrit");
    }
    const compte: Compte = { id: randomUUID(), niveau: 1, ...donnees };
    this.comptes.set(compte.id, compte);
    return compte;
  }

  /** Vérification d'identité simulée au prototype (prestataire réel en V2). */
  passerAuNiveau2(id: string): Compte {
    const c = this.trouver(id);
    c.niveau = 2;
    return c;
  }

  chercher(id: string): Compte | undefined {
    return this.comptes.get(id);
  }

  trouver(id: string): Compte {
    const c = this.comptes.get(id);
    if (!c) throw new NotFoundException("Compte introuvable");
    return c;
  }
}
