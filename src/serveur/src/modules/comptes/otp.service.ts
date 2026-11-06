import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { CONNECTEUR_SMS, type ConnecteurSms } from "../../sms/connecteur-sms.js";

// Paramètres de sécurité (aucune règle métier écrite) : valeurs courantes pour un code SMS.
export const DUREE_VALIDITE_MS = 5 * 60 * 1000;
export const ESSAIS_MAX = 5;
export const DELAI_RENVOI_MS = 60 * 1000;
/** Codes envoyés à un même numéro sur 24 h glissantes : coupe la fraude au SMS et le harcèlement d'un numéro. */
export const ENVOIS_MAX_PAR_JOUR = 5;
const JOUR_MS = 24 * 60 * 60 * 1000;

const empreinteCode = (sel: string, code: string) => createHash("sha256").update(`${sel}:${code}`).digest("hex");

interface LigneOtp extends Record<string, unknown> {
  empreinte_code: string;
  sel: string;
  expire_le: Date | string;
  essais: number;
  consomme: boolean;
  cree_le: Date | string;
}

/**
 * Code SMS à usage unique : il prouve que la personne reçoit les SMS de ce numéro.
 * Il authentifie l'inscription, il ne signe jamais un engagement (recours-legaux.md, décision 1).
 */
@Injectable()
export class OtpService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CONNECTEUR_SMS) private readonly sms: ConnecteurSms,
  ) {}

  async demander(numero: string, maintenant: Date = new Date()): Promise<{ expireLe: string }> {
    const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
    const sel = randomBytes(16).toString("hex");
    const expireLe = new Date(maintenant.getTime() + DUREE_VALIDITE_MS);
    const finFenetre = new Date(maintenant.getTime() - JOUR_MS).toISOString();
    const renvoiPossible = new Date(maintenant.getTime() - DELAI_RENVOI_MS).toISOString();
    // Contrôles et écriture en une seule instruction : deux demandes simultanées ne passent pas toutes les deux.
    const accepte = await this.base.requete(
      `INSERT INTO comptes.codes_otp (numero, empreinte_code, sel, expire_le, essais, consomme, cree_le, envois, fenetre_debut)
       VALUES ($1, $2, $3, $4, 0, false, $5, 1, $5)
       ON CONFLICT (numero) DO UPDATE SET empreinte_code = $2, sel = $3, expire_le = $4, essais = 0, consomme = false,
         cree_le = $5,
         envois = CASE WHEN codes_otp.fenetre_debut <= $6 THEN 1 ELSE codes_otp.envois + 1 END,
         fenetre_debut = CASE WHEN codes_otp.fenetre_debut <= $6 THEN $5 ELSE codes_otp.fenetre_debut END
       WHERE (codes_otp.consomme OR codes_otp.cree_le <= $7)
         AND (codes_otp.fenetre_debut <= $6 OR codes_otp.envois < $8)
       RETURNING numero`,
      [
        numero,
        empreinteCode(sel, code),
        sel,
        expireLe.toISOString(),
        maintenant.toISOString(),
        finFenetre,
        renvoiPossible,
        ENVOIS_MAX_PAR_JOUR,
      ],
    );
    if (accepte.length === 0) {
      const [actuel] = await this.base.requete<LigneOtp>("SELECT * FROM comptes.codes_otp WHERE numero = $1", [numero]);
      const tropTot = actuel && !actuel.consomme && new Date(actuel.cree_le).toISOString() > renvoiPossible;
      throw new HttpException(
        tropTot
          ? "Attendre une minute avant de redemander un code"
          : "Trop de codes demandés pour ce numéro : réessayer demain",
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    await this.sms.envoyer(numero, `MonDo : votre code est ${code}. Ne le communiquez à personne.`);
    return { expireLe: expireLe.toISOString() };
  }

  /** Vrai une seule fois, pour le bon code, avant expiration et dans la limite d'essais. */
  async verifier(numero: string, code: string, maintenant: Date = new Date()): Promise<boolean> {
    // L'essai est compté avant la comparaison : deux essais simultanés ne contournent pas la limite.
    const [ligne] = await this.base.requete<LigneOtp>(
      `UPDATE comptes.codes_otp SET essais = essais + 1
       WHERE numero = $1 AND NOT consomme AND essais < $2 RETURNING *`,
      [numero, ESSAIS_MAX],
    );
    if (!ligne || maintenant > new Date(ligne.expire_le)) return false;
    const attendu = Buffer.from(ligne.empreinte_code, "hex");
    const recu = Buffer.from(empreinteCode(ligne.sel, code), "hex");
    if (!timingSafeEqual(attendu, recu)) return false;
    const consomme = await this.base.requete(
      "UPDATE comptes.codes_otp SET consomme = true WHERE numero = $1 AND NOT consomme RETURNING numero",
      [numero],
    );
    return consomme.length === 1;
  }
}
