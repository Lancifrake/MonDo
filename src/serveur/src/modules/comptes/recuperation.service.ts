import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { createHash, randomBytes, randomUUID, scryptSync, timingSafeEqual } from "node:crypto";
import { estAdministrateur } from "../../administration/administrateurs.js";
import { FENETRE_MS } from "../../authentification/fenetre.js";
import { messagePiecesRecuperation, messageRecuperation } from "../../authentification/messages.js";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { RegistreService } from "../../registre/registre.service.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { FileSms } from "../../sms/file-sms.js";
import { BlocagesService } from "./blocages.service.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";
import { IdentiteService } from "./identite.service.js";
import { OtpService } from "./otp.service.js";

const HEURE_MS = 60 * 60 * 1000;
/** Choix de David (08/11 et 11/11). */
export const DELAI_AVEC_CONTACT_MS = 48 * HEURE_MS;
export const DELAI_SANS_CONTACT_MS = 72 * HEURE_MS;
// Valeurs de sécurité, choix prudents sans règle métier écrite.
/** Sans pièces validées, une demande sans contact s'éteint 7 jours après la fin de son délai. */
export const EXPIRATION_SANS_PIECES_MS = 7 * 24 * HEURE_MS;
export const ECHECS_MAX_CODE_SECRET = 5;

export type StatutRecuperation = "en_attente" | "opposee" | "acceptee" | "refusee" | "expiree";

export interface DemandeRecuperation {
  id: string;
  demandeeLe: string;
  finDelaiLe: string;
  avecContact: boolean;
  /** Sans contact de confiance : carte d'identité et selfie à déposer, validés par un Administrateur. */
  piecesRequises: boolean;
  statut: StatutRecuperation;
}

interface LigneRecuperation extends Record<string, unknown> {
  id: string;
  compte_id: string;
  nouvelle_cle: JsonWebKey;
  demandee_le: Date | string;
  fin_delai_le: Date | string;
  avec_contact: boolean;
  statut: StatutRecuperation;
}

const versDemande = (l: LigneRecuperation): DemandeRecuperation => ({
  id: l.id,
  demandeeLe: new Date(l.demandee_le).toISOString(),
  finDelaiLe: new Date(l.fin_delai_le).toISOString(),
  avecContact: l.avec_contact,
  piecesRequises: !l.avec_contact,
  statut: l.statut,
});

const hacherCodeSecret = (sel: string, code: string) => scryptSync(code, sel, 32).toString("hex");
const empreinteCle = (cle: JsonWebKey) => createHash("sha256").update(canonique(cle)).digest("hex");
const REFUS = "Récupération refusée : numéro, code SMS, code secret ou preuve de clé invalide";
const UUID = /^[0-9a-f-]{36}$/i;

/**
 * Récupération d'un compte après la perte du téléphone (flow 2). Le nouveau téléphone prouve qu'il reçoit les
 * SMS du numéro, donne le code secret et présente une nouvelle clé. La clé ne change qu'après un délai, pendant
 * lequel le titulaire (ancienne clé) peut s'opposer : 48 h avec un contact de confiance, 72 h plus carte
 * d'identité et selfie sans contact. Une opposition bloque le compte jusqu'à la décision d'un Administrateur.
 */
@Injectable()
export class RecuperationService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(OtpService) private readonly otp: OtpService,
    @Inject(ContactConfianceService) private readonly contacts: ContactConfianceService,
    @Inject(IdentiteService) private readonly identite: IdentiteService,
    @Inject(BlocagesService) private readonly blocages: BlocagesService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  /** Le code secret n'est jamais gardé en clair : sel et dérivation lente (scrypt). */
  async definirCodeSecret(compteId: string, code: string): Promise<{ defini: true }> {
    const sel = randomBytes(16).toString("hex");
    await this.base.requete(
      `INSERT INTO comptes.codes_secrets (compte_id, empreinte, sel, echecs) VALUES ($1, $2, $3, 0)
       ON CONFLICT (compte_id) DO UPDATE SET empreinte = $2, sel = $3, echecs = 0`,
      [compteId, hacherCodeSecret(sel, code), sel],
    );
    return { defini: true };
  }

  async demander(
    d: { numero: string; clePublique: JsonWebKey; preuve: string; codeOtp: string; codeSecret?: string },
    maintenant = new Date(),
  ): Promise<DemandeRecuperation> {
    if (
      !verifierSignature(d.clePublique, messageRecuperation({ numero: d.numero, clePublique: d.clePublique }), d.preuve)
    ) {
      throw new ForbiddenException(REFUS);
    }
    // Le code SMS d'abord : on ne dit pas si un numéro est inscrit à qui ne le possède pas.
    if (!(await this.otp.verifier(d.numero, d.codeOtp, maintenant))) throw new ForbiddenException(REFUS);
    const compte = await this.comptes.chercherParNumero(d.numero);
    if (!compte) throw new ForbiddenException(REFUS);
    if (await this.blocages.estBloque(compte.id, maintenant)) {
      throw new HttpException("Compte bloqué : récupération impossible pour le moment", HttpStatus.LOCKED);
    }
    const codeSecretVerifie = await this.verifierCodeSecret(compte.id, d.codeSecret, maintenant);
    // Sans code secret défini ou sans contact consentant : le chemin le plus strict.
    const contact = codeSecretVerifie ? await this.contacts.numeroDuContactConsentant(compte.id) : undefined;
    const avecContact = Boolean(contact);
    const finDelai = new Date(maintenant.getTime() + (avecContact ? DELAI_AVEC_CONTACT_MS : DELAI_SANS_CONTACT_MS));
    let ligne: LigneRecuperation;
    try {
      [ligne] = (await this.base.requete<LigneRecuperation>(
        `INSERT INTO comptes.recuperations (id, compte_id, nouvelle_cle, demandee_le, fin_delai_le, avec_contact, statut)
         VALUES ($1, $2, $3, $4, $5, $6, 'en_attente') RETURNING *`,
        [
          randomUUID(),
          compte.id,
          JSON.stringify(d.clePublique),
          maintenant.toISOString(),
          finDelai.toISOString(),
          avecContact,
        ],
      )) as [LigneRecuperation];
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Une récupération est déjà en cours pour ce compte");
      throw e;
    }
    const heures = avecContact ? 48 : 72;
    await this.sms.mettreEnFile(
      `recuperation:${ligne.id}:titulaire`,
      compte.numero,
      `MonDo : une récupération de votre compte a été demandée depuis un autre téléphone. Si ce n'est pas vous, ` +
        `opposez-vous dans l'application avant ${heures} h.`,
    );
    if (contact) {
      await this.sms.mettreEnFile(
        `recuperation:${ligne.id}:contact`,
        contact,
        `MonDo : une récupération du compte de ${compte.nom} a été demandée. Si ce n'est pas lui, prévenez-le : ` +
          `il peut s'y opposer depuis son téléphone.`,
      );
    }
    this.sms.declencher();
    return versDemande(ligne);
  }

  /**
   * Vrai si un code secret est défini et qu'il est bon. Faux s'il n'y en a pas. Un code faux est refusé ; au
   * cinquième sur 24 h, le compte est bloqué un temps. L'échec est compté dans la même instruction que la
   * lecture : deux essais simultanés ne contournent pas la limite.
   */
  private async verifierCodeSecret(compteId: string, code: string | undefined, maintenant: Date): Promise<boolean> {
    const [l] = await this.base.requete<{ empreinte: string; sel: string }>(
      "SELECT empreinte, sel FROM comptes.codes_secrets WHERE compte_id = $1",
      [compteId],
    );
    if (!l) return false;
    const bon =
      code !== undefined &&
      timingSafeEqual(Buffer.from(l.empreinte, "hex"), Buffer.from(hacherCodeSecret(l.sel, code), "hex"));
    if (bon) {
      await this.base.requete("UPDATE comptes.codes_secrets SET echecs = 0 WHERE compte_id = $1", [compteId]);
      return true;
    }
    const debutFenetre = new Date(maintenant.getTime() - 24 * HEURE_MS).toISOString();
    const [{ echecs }] = (await this.base.requete<{ echecs: number }>(
      `UPDATE comptes.codes_secrets
       SET echecs = CASE WHEN fenetre_debut IS NULL OR fenetre_debut <= $2 THEN 1 ELSE echecs + 1 END,
           fenetre_debut = CASE WHEN fenetre_debut IS NULL OR fenetre_debut <= $2 THEN $3 ELSE fenetre_debut END
       WHERE compte_id = $1 RETURNING echecs`,
      [compteId, debutFenetre, maintenant.toISOString()],
    )) as [{ echecs: number }];
    if (echecs >= ECHECS_MAX_CODE_SECRET) {
      await this.base.requete(
        "UPDATE comptes.codes_secrets SET echecs = 0, fenetre_debut = NULL WHERE compte_id = $1",
        [compteId],
      );
      await this.blocages.bloquer(compteId, "essais_rates", maintenant);
    }
    throw new ForbiddenException(REFUS);
  }

  /** Pièces de la branche sans contact, déposées par le téléphone qui a fait la demande (preuve par sa clé). */
  async deposerPieces(
    id: string,
    d: {
      typePiece: string;
      versionConsentement: string;
      recto: string;
      verso: string;
      selfie: string;
      horodatage: string;
      preuve: string;
    },
    maintenant = new Date(),
  ) {
    const l = await this.trouver(id);
    const instant = Date.parse(d.horodatage);
    const { preuve, horodatage, ...pieces } = d;
    if (
      Number.isNaN(instant) ||
      Math.abs(maintenant.getTime() - instant) > FENETRE_MS ||
      !verifierSignature(l.nouvelle_cle, messagePiecesRecuperation(id, horodatage), preuve)
    ) {
      throw new ForbiddenException("Preuve invalide : seul le téléphone qui a fait la demande dépose les pièces");
    }
    if (l.statut !== "en_attente" || l.avec_contact)
      throw new BadRequestException("Aucune pièce attendue pour cette demande");
    return this.identite.deposerPourRecuperation(l.compte_id, id, pieces, maintenant);
  }

  /** La demande en cours sur mon compte, pour que l'ancien téléphone puisse la voir et s'y opposer. */
  async enCoursPour(compteId: string): Promise<DemandeRecuperation> {
    const [l] = await this.base.requete<LigneRecuperation>(
      "SELECT * FROM comptes.recuperations WHERE compte_id = $1 AND statut IN ('en_attente', 'opposee')",
      [compteId],
    );
    if (!l) throw new NotFoundException("Aucune récupération en cours");
    return versDemande(l);
  }

  /** Pour l'échange de places : suspendu tant qu'un des deux comptes est en récupération. */
  async enRecuperation(compteId: string): Promise<boolean> {
    const lignes = await this.base.requete(
      "SELECT 1 FROM comptes.recuperations WHERE compte_id = $1 AND statut IN ('en_attente', 'opposee')",
      [compteId],
    );
    return lignes.length > 0;
  }

  /** Le titulaire, avec son ancienne clé, s'oppose : le compte est bloqué et le dossier part chez l'Administrateur. */
  async sOpposer(compteId: string, maintenant = new Date()): Promise<DemandeRecuperation> {
    const [l] = await this.base.requete<LigneRecuperation>(
      "UPDATE comptes.recuperations SET statut = 'opposee' WHERE compte_id = $1 AND statut = 'en_attente' RETURNING *",
      [compteId],
    );
    if (!l) throw new NotFoundException("Aucune récupération en attente sur ce compte");
    await this.blocages.bloquer(compteId, "opposition", maintenant);
    await this.registre.enregistrer(
      canonique({ objet: "opposition_recuperation", recuperationId: l.id, opposeeLe: maintenant.toISOString() }),
    );
    return versDemande(l);
  }

  async listerOpposees(parMembreId: string) {
    if (!estAdministrateur(parMembreId)) throw new ForbiddenException("Réservé à l'administrateur");
    const lignes = await this.base.requete<LigneRecuperation>(
      "SELECT * FROM comptes.recuperations WHERE statut = 'opposee' ORDER BY demandee_le, id",
    );
    return Promise.all(
      lignes.map(async (l) => {
        const compte = await this.comptes.chercher(l.compte_id);
        return { ...versDemande(l), compteId: l.compte_id, nom: compte?.nom, numero: compte?.numero };
      }),
    );
  }

  /** Récupération contestée : l'Administrateur confirme le titulaire ou accepte la récupération, puis débloque. */
  async trancher(
    id: string,
    decision: "titulaire_confirme" | "recuperation_acceptee",
    motif: string,
    parMembreId: string,
    maintenant = new Date(),
  ): Promise<DemandeRecuperation> {
    if (!estAdministrateur(parMembreId)) throw new ForbiddenException("Réservé à l'administrateur");
    const avant = await this.trouver(id);
    if (avant.compte_id === parMembreId) {
      throw new ForbiddenException("Un administrateur ne tranche pas la récupération de son propre compte");
    }
    const statut: StatutRecuperation = decision === "recuperation_acceptee" ? "acceptee" : "refusee";
    const l = await this.clore(id, "opposee", statut, maintenant, { parMembreId, motif });
    if (!l) throw new BadRequestException("Aucune opposition à trancher sur cette demande");
    await this.blocages.lever(l.compte_id, maintenant);
    return versDemande(l);
  }

  /**
   * Passage régulier, rejouable : les demandes dont le délai est passé sans opposition. Avec contact : clé
   * remplacée. Sans contact : seulement si un Administrateur a validé les pièces ; refusée s'il les a refusées ;
   * expirée après 7 jours de plus sans pièces validées.
   */
  async finaliser(maintenant = new Date()): Promise<number> {
    const mures = await this.base.requete<LigneRecuperation>(
      "SELECT * FROM comptes.recuperations WHERE statut = 'en_attente' AND fin_delai_le <= $1 ORDER BY demandee_le, id",
      [maintenant.toISOString()],
    );
    let closes = 0;
    for (const l of mures) {
      const pieces = l.avec_contact ? "validee" : await this.identite.decisionPourRecuperation(l.id);
      const tropTard = maintenant.getTime() > new Date(l.fin_delai_le).getTime() + EXPIRATION_SANS_PIECES_MS;
      const statut: StatutRecuperation | undefined =
        pieces === "validee" ? "acceptee" : pieces === "refusee" ? "refusee" : tropTard ? "expiree" : undefined;
      if (statut && (await this.clore(l.id, "en_attente", statut, maintenant))) closes++;
    }
    return closes;
  }

  /** Changement d'état conditionnel (jamais deux issues pour une demande) ; si acceptée, la clé est remplacée. */
  private async clore(
    id: string,
    depuis: StatutRecuperation,
    vers: StatutRecuperation,
    maintenant: Date,
    decision?: { parMembreId: string; motif: string },
  ): Promise<LigneRecuperation | undefined> {
    const [l] = await this.base.requete<LigneRecuperation>(
      `UPDATE comptes.recuperations SET statut = $3, close_le = $4, decidee_par = $5, motif_decision = $6
       WHERE id = $1 AND statut = $2 RETURNING *`,
      [id, depuis, vers, maintenant.toISOString(), decision?.parMembreId ?? null, decision?.motif ?? null],
    );
    if (!l) return undefined;
    const compte = await this.comptes.trouver(l.compte_id);
    if (vers === "acceptee") {
      await this.comptes.remplacerCle(l.compte_id, l.nouvelle_cle, maintenant);
    }
    // Au registre : des empreintes de clés, aucune donnée personnelle.
    await this.registre.enregistrer(
      canonique({
        objet: "issue_recuperation",
        recuperationId: id,
        issue: vers,
        ancienneCle: empreinteCle(compte.clePublique),
        ...(vers === "acceptee" ? { nouvelleCle: empreinteCle(l.nouvelle_cle) } : {}),
        le: maintenant.toISOString(),
        ...(decision ? { administrateurId: decision.parMembreId } : {}),
      }),
    );
    await this.sms.mettreEnFile(
      `recuperation:${id}:issue`,
      compte.numero,
      vers === "acceptee"
        ? "MonDo : votre compte est récupéré sur le nouveau téléphone. L'ancien téléphone ne peut plus signer."
        : "MonDo : la récupération de votre compte n'a pas abouti. Votre clé de signature n'a pas changé.",
    );
    this.sms.declencher();
    return l;
  }

  private async trouver(id: string): Promise<LigneRecuperation> {
    const [l] = UUID.test(id)
      ? await this.base.requete<LigneRecuperation>("SELECT * FROM comptes.recuperations WHERE id = $1", [id])
      : [];
    if (!l) throw new NotFoundException("Demande de récupération introuvable");
    return l;
  }
}
