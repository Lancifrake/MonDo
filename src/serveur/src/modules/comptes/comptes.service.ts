import { BadRequestException, ConflictException, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";

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

  inscrire(d: { numero: string; nom: string; clePublique: JsonWebKey }): Compte {
    if (!/^\+?\d{8,15}$/.test(d.numero)) throw new BadRequestException("Numéro de téléphone invalide");
    if (!d.nom.trim()) throw new BadRequestException("Le nom est obligatoire");
    if (d.clePublique?.kty !== "EC" || d.clePublique.crv !== "P-256" || d.clePublique.d) {
      throw new BadRequestException("Clé publique ECDSA P-256 attendue, sans partie privée");
    }
    if ([...this.comptes.values()].some((c) => c.numero === d.numero)) throw new ConflictException("Numéro déjà inscrit");
    const compte: Compte = { id: randomUUID(), niveau: 1, ...d };
    this.comptes.set(compte.id, compte);
    return compte;
  }

  /** Vérification d'identité simulée au prototype (prestataire réel en V2). */
  passerAuNiveau2(id: string): Compte {
    const c = this.trouver(id);
    c.niveau = 2;
    return c;
  }

  trouver(id: string): Compte {
    const c = this.comptes.get(id);
    if (!c) throw new NotFoundException("Compte introuvable");
    return c;
  }
}
