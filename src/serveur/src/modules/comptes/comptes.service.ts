import { ConflictException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { createHash, randomUUID } from "node:crypto";
import { messageInscription } from "../../authentification/messages.js";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { verifierSignature } from "../../signature/signature.js";
import { OtpService } from "./otp.service.js";

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
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(OtpService) private readonly otp: OtpService,
  ) {}

  /** La forme des données est validée en amont (schemaInscription) ; ici, les règles métier. */
  async inscrire(d: {
    numero: string;
    nom: string;
    clePublique: JsonWebKey;
    preuve: string;
    codeOtp: string;
  }): Promise<Compte> {
    const { preuve, codeOtp, ...donnees } = d;
    if (!verifierSignature(donnees.clePublique, messageInscription(donnees), preuve)) {
      throw new ForbiddenException("Preuve de détention de la clé invalide");
    }
    // Le code SMS d'abord : on ne dit pas si un numéro est inscrit à qui ne le possède pas.
    if (!(await this.otp.verifier(donnees.numero, codeOtp))) {
      throw new ForbiddenException("Code SMS invalide, expiré ou trop d'essais");
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

  async chercherParNumero(numero: string): Promise<Compte | undefined> {
    const [ligne] = await this.base.requete<LigneCompte>("SELECT * FROM comptes.comptes WHERE numero = $1", [numero]);
    return ligne && versCompte(ligne);
  }

  /**
   * Récupération acceptée : la nouvelle clé remplace l'ancienne, qui est gardée comme clé révoquée. Les
   * documents signés avant restent vérifiables avec elle (dossier de preuve).
   */
  async remplacerCle(id: string, nouvelleCle: JsonWebKey, maintenant: Date = new Date()): Promise<void> {
    await this.base.transaction(async (tx) => {
      const [avant] = await tx.requete<LigneCompte>("SELECT * FROM comptes.comptes WHERE id = $1 FOR UPDATE", [id]);
      if (!avant) throw new NotFoundException("Compte introuvable");
      await tx.requete(
        "INSERT INTO comptes.cles_revoquees (compte_id, cle_publique, revoquee_le) VALUES ($1, $2, $3)",
        [id, JSON.stringify(avant.cle_publique), maintenant.toISOString()],
      );
      await tx.requete("UPDATE comptes.comptes SET cle_publique = $2 WHERE id = $1", [id, JSON.stringify(nouvelleCle)]);
    });
  }

  /** Clés remplacées lors d'une récupération, de la plus ancienne à la plus récente. */
  async clesRevoquees(id: string): Promise<{ clePublique: JsonWebKey; revoqueeLe: string }[]> {
    const lignes = await this.base.requete<{ cle_publique: JsonWebKey; revoquee_le: Date | string }>(
      "SELECT cle_publique, revoquee_le FROM comptes.cles_revoquees WHERE compte_id = $1 ORDER BY revoquee_le, id",
      [id],
    );
    return lignes.map((l) => ({ clePublique: l.cle_publique, revoqueeLe: new Date(l.revoquee_le).toISOString() }));
  }

  async trouver(id: string): Promise<Compte> {
    const compte = await this.chercher(id);
    if (!compte) throw new NotFoundException("Compte introuvable");
    return compte;
  }

  /**
   * Anti-rejeu stocké en base : plusieurs copies du serveur partagent la même mémoire (décision 02, règle 3).
   * Clé = empreinte du membre et du message signé, jamais le texte de la signature, qui s'écrit de plusieurs
   * façons valides (padding base64, malléabilité ECDSA) : une requête déjà vue est refusée quelle que soit
   * l'écriture de sa signature.
   */
  async marquerRequeteVue(membreId: string, message: string, expireLe: Date): Promise<boolean> {
    const empreinte = createHash("sha256").update(`${membreId}\n${message}`).digest("hex");
    await this.base.requete("DELETE FROM comptes.requetes_vues WHERE expire_le < now()");
    const lignes = await this.base.requete(
      "INSERT INTO comptes.requetes_vues (empreinte, expire_le) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING empreinte",
      [empreinte, expireLe.toISOString()],
    );
    return lignes.length === 1;
  }
}
