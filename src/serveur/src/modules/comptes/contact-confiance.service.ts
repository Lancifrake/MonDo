import { BadRequestException, HttpException, HttpStatus, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { FileSms } from "../../sms/file-sms.js";
import { ComptesService } from "./comptes.service.js";

// Valeurs de sécurité choisies par prudence (aucune règle métier écrite).
/** Le contact a 48 h pour donner son accord. */
export const VALIDITE_ACCORD_MS = 48 * 60 * 60 * 1000;
export const ESSAIS_MAX_ACCORD = 5;
/** Désignations par compte sur 24 h : empêche d'envoyer des SMS en série à des inconnus. */
export const DESIGNATIONS_MAX_PAR_JOUR = 3;
const JOUR_MS = 24 * 60 * 60 * 1000;

export interface ContactConfiance {
  nom: string;
  numero: string;
  statut: "en_attente" | "accepte";
  demandeLe: string;
  expireLe?: string;
  consentementLe?: string;
}

interface LigneContact extends Record<string, unknown> {
  nom: string;
  numero: string;
  empreinte_code: string;
  sel: string;
  essais: number;
  expire_le: Date | string;
  demande_le: Date | string;
  consentement_le: Date | string | null;
}

const empreinte = (sel: string, code: string) => createHash("sha256").update(`${sel}:${code}`).digest("hex");

const versContact = (l: LigneContact): ContactConfiance => ({
  nom: l.nom,
  numero: l.numero,
  statut: l.consentement_le ? "accepte" : "en_attente",
  demandeLe: new Date(l.demande_le).toISOString(),
  ...(l.consentement_le
    ? { consentementLe: new Date(l.consentement_le).toISOString() }
    : { expireLe: new Date(l.expire_le).toISOString() }),
});

/**
 * Contact de confiance (flow 1) : une personne qui aide le membre à récupérer son compte. Exigé au niveau 2,
 * facultatif au niveau 1, aucun engagement financier (une caution électronique serait interdite, loi 2010/021,
 * article 13). Le contact reçoit un SMS avec un code : s'il accepte, il le donne au membre, qui le saisit.
 */
@Injectable()
export class ContactConfianceService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  async designer(compteId: string, d: { nom: string; numero: string }, maintenant = new Date()) {
    const compte = await this.comptes.trouver(compteId);
    if (compte.numero === d.numero) {
      throw new BadRequestException("Le contact de confiance doit être une autre personne que vous");
    }
    const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
    const sel = randomBytes(16).toString("hex");
    const expireLe = new Date(maintenant.getTime() + VALIDITE_ACCORD_MS);
    const debutFenetre = new Date(maintenant.getTime() - JOUR_MS).toISOString();
    // Plafond et écriture en une seule instruction : deux désignations simultanées ne le contournent pas.
    const [l] = await this.base.requete<LigneContact>(
      `INSERT INTO comptes.contacts_confiance
         (compte_id, nom, numero, empreinte_code, sel, essais, expire_le, demande_le, designations, fenetre_debut)
       VALUES ($1, $2, $3, $4, $5, 0, $6, $7, 1, $7)
       ON CONFLICT (compte_id) DO UPDATE SET nom = $2, numero = $3, empreinte_code = $4, sel = $5, essais = 0,
         expire_le = $6, demande_le = $7, consentement_le = NULL,
         designations = CASE WHEN contacts_confiance.fenetre_debut <= $8 THEN 1
                             ELSE contacts_confiance.designations + 1 END,
         fenetre_debut = CASE WHEN contacts_confiance.fenetre_debut <= $8 THEN $7
                              ELSE contacts_confiance.fenetre_debut END
       WHERE contacts_confiance.fenetre_debut <= $8 OR contacts_confiance.designations < $9
       RETURNING *`,
      [
        compteId,
        d.nom,
        d.numero,
        empreinte(sel, code),
        sel,
        expireLe.toISOString(),
        maintenant.toISOString(),
        debutFenetre,
        DESIGNATIONS_MAX_PAR_JOUR,
      ],
    );
    if (!l) {
      throw new HttpException("Trop de désignations aujourd'hui : réessayer demain", HttpStatus.TOO_MANY_REQUESTS);
    }
    await this.sms.mettreEnFile(
      `contact_confiance:${compteId}:${maintenant.toISOString()}`,
      d.numero,
      `MonDo : ${compte.nom} vous propose comme contact de confiance, pour l'aider à retrouver son compte. ` +
        `Aucun engagement financier. Si vous acceptez, donnez-lui le code ${code}.`,
    );
    this.sms.declencher();
    return versContact(l);
  }

  /** L'essai est compté avant la comparaison ; le code ne sert qu'une fois et expire. */
  async enregistrerAccord(compteId: string, code: string, maintenant = new Date()): Promise<ContactConfiance> {
    const [l] = await this.base.requete<LigneContact>(
      `UPDATE comptes.contacts_confiance SET essais = essais + 1
       WHERE compte_id = $1 AND consentement_le IS NULL AND essais < $2 RETURNING *`,
      [compteId, ESSAIS_MAX_ACCORD],
    );
    const bon =
      l &&
      maintenant <= new Date(l.expire_le) &&
      timingSafeEqual(Buffer.from(l.empreinte_code, "hex"), Buffer.from(empreinte(l.sel, code), "hex"));
    if (!bon) throw new BadRequestException("Code invalide, expiré ou trop d'essais : désigner de nouveau le contact");
    const [accepte] = await this.base.requete<LigneContact>(
      `UPDATE comptes.contacts_confiance SET consentement_le = $2
       WHERE compte_id = $1 AND consentement_le IS NULL AND empreinte_code = $3 RETURNING *`,
      [compteId, maintenant.toISOString(), l.empreinte_code],
    );
    if (!accepte) throw new BadRequestException("Accord déjà enregistré ou contact remplacé");
    return versContact(accepte);
  }

  async consulter(compteId: string): Promise<ContactConfiance> {
    const l = await this.ligne(compteId);
    if (!l) throw new NotFoundException("Aucun contact de confiance désigné");
    return versContact(l);
  }

  /** Vrai si le contact a donné son accord : condition du niveau 2 et de la récupération en 48 h. */
  async aUnContactConsentant(compteId: string): Promise<boolean> {
    return Boolean((await this.ligne(compteId))?.consentement_le);
  }

  /** Numéro du contact qui a donné son accord, pour le prévenir d'une récupération. */
  async numeroDuContactConsentant(compteId: string): Promise<string | undefined> {
    const l = await this.ligne(compteId);
    return l?.consentement_le ? l.numero : undefined;
  }

  private async ligne(compteId: string): Promise<LigneContact | undefined> {
    const [l] = await this.base.requete<LigneContact>("SELECT * FROM comptes.contacts_confiance WHERE compte_id = $1", [
      compteId,
    ]);
    return l;
  }
}
