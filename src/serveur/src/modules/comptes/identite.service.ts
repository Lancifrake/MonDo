import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { createHash, randomUUID } from "node:crypto";
import { estAdministrateur } from "../../administration/administrateurs.js";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { canonique } from "../../signature/canonique.js";
import { FileSms } from "../../sms/file-sms.js";
import { STOCKAGE_OBJETS, type StockageObjets } from "../../stockage/stockage-objets.js";
import { ComptesService } from "./comptes.service.js";
import { ContactConfianceService } from "./contact-confiance.service.js";

/** Texte que le membre accepte avant le dépôt ; l'application l'affiche et renvoie sa version. */
export const VERSION_CONSENTEMENT = "2026-11-11";
export const TEXTE_CONSENTEMENT =
  "J'accepte que MonDo reçoive la photo de ma pièce d'identité (recto et verso) et un selfie pour vérifier mon " +
  "identité. Un administrateur de MonDo les examine. Le selfie est supprimé dès la décision. La pièce est gardée " +
  "chiffrée, à part, 5 ans après la fin de mon dernier cercle, puis supprimée. En cas de refus, tout est supprimé. " +
  "Je peux retirer mon consentement en écrivant à MonDo.";

/** Durée provisoire (choix de David, 11/11), à faire valider par un juriste (loi 2024/017, article 28). */
export const DUREE_CONSERVATION_CARTE_ANS = 5;
export const TAILLE_MAX_IMAGE = 2 * 1024 * 1024;
/** Dépôts par compte sur 24 h (valeur de sécurité, choix prudent). */
export const DEPOTS_MAX_PAR_JOUR = 3;

export const NATURES = ["recto", "verso", "selfie"] as const;
export type NaturePiece = (typeof NATURES)[number];

export interface VerificationIdentite {
  id: string;
  compteId: string;
  typePiece: string;
  consentementLe: string;
  versionConsentement: string;
  deposeeLe: string;
  statut: "en_attente" | "validee" | "refusee";
  /** niveau2 : passage au niveau 2 ; recuperation : preuve d'identité d'une récupération sans contact. */
  motif: "niveau2" | "recuperation";
  motifDecision?: string;
  decideeLe?: string;
}

interface LigneVerification extends Record<string, unknown> {
  id: string;
  compte_id: string;
  type_piece: string;
  consentement_le: Date | string;
  version_consentement: string;
  deposee_le: Date | string;
  statut: VerificationIdentite["statut"];
  motif: VerificationIdentite["motif"];
  motif_decision: string | null;
  decidee_le: Date | string | null;
}

const versVerification = (l: LigneVerification): VerificationIdentite => ({
  id: l.id,
  compteId: l.compte_id,
  typePiece: l.type_piece,
  consentementLe: new Date(l.consentement_le).toISOString(),
  versionConsentement: l.version_consentement,
  deposeeLe: new Date(l.deposee_le).toISOString(),
  statut: l.statut,
  motif: l.motif,
  ...(l.motif_decision ? { motifDecision: l.motif_decision } : {}),
  ...(l.decidee_le ? { decideeLe: new Date(l.decidee_le).toISOString() } : {}),
});

/** JPEG ou PNG, reconnu à ses premiers octets : le type annoncé par le client ne prouve rien. */
function typeImage(contenu: Buffer): "image/jpeg" | "image/png" | undefined {
  if (contenu.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) return "image/jpeg";
  if (contenu.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "image/png";
  return undefined;
}

const UUID = /^[0-9a-f-]{36}$/i;

/**
 * Vérification d'identité faite en interne (choix de David, 08/11 et 11/11) : le membre dépose recto, verso et
 * selfie avec son consentement explicite ; un Administrateur valide ou refuse avec un motif. Les images vont
 * dans le stockage d'objets chiffré, jamais en base ni dans les journaux. Le selfie est supprimé juste après
 * la décision ; en cas de refus, tout est supprimé ; la carte validée est gardée 5 ans après le dernier cercle
 * du membre. Chaque ouverture d'une pièce par un Administrateur est journalisée.
 */
@Injectable()
export class IdentiteService {
  private readonly journal = new Logger("Identité");

  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(STOCKAGE_OBJETS) private readonly stockage: StockageObjets,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ContactConfianceService) private readonly contacts: ContactConfianceService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(FileSms) private readonly sms: FileSms,
    @Inject(EvenementsInternes) evenements: EvenementsInternes,
  ) {
    evenements.ecouter("fin_de_cercle_pour_membre", (e) => this.noterFinDeCercle(e.membreId, new Date(e.termineLe)));
  }

  async deposer(
    compteId: string,
    d: { typePiece: string; versionConsentement: string; recto: string; verso: string; selfie: string },
    maintenant = new Date(),
  ): Promise<VerificationIdentite> {
    const compte = await this.comptes.trouver(compteId);
    if (compte.niveau === 2) throw new ConflictException("Identité déjà vérifiée");
    if (d.versionConsentement !== VERSION_CONSENTEMENT) {
      throw new BadRequestException("Texte de consentement périmé : relire et accepter la version en vigueur");
    }
    if (!(await this.contacts.aUnContactConsentant(compteId))) {
      throw new ForbiddenException("Un contact de confiance qui a donné son accord est exigé pour le niveau 2");
    }
    return this.enregistrer(compteId, d, "niveau2", null, maintenant);
  }

  /** Carte et selfie d'une récupération sans contact : même stockage, même file, même décision. */
  async deposerPourRecuperation(
    compteId: string,
    recuperationId: string,
    d: { typePiece: string; versionConsentement: string; recto: string; verso: string; selfie: string },
    maintenant = new Date(),
  ): Promise<VerificationIdentite> {
    if (d.versionConsentement !== VERSION_CONSENTEMENT) {
      throw new BadRequestException("Texte de consentement périmé : relire et accepter la version en vigueur");
    }
    return this.enregistrer(compteId, d, "recuperation", recuperationId, maintenant);
  }

  /** Décision de l'Administrateur sur les pièces d'une récupération, ou « aucune » tant qu'il n'a pas décidé. */
  async decisionPourRecuperation(recuperationId: string): Promise<"validee" | "refusee" | "aucune"> {
    const lignes = await this.base.requete<{ statut: VerificationIdentite["statut"] }>(
      "SELECT statut FROM comptes.verifications_identite WHERE recuperation_id = $1",
      [recuperationId],
    );
    if (lignes.some((l) => l.statut === "validee")) return "validee";
    return lignes.some((l) => l.statut === "refusee") && !lignes.some((l) => l.statut === "en_attente")
      ? "refusee"
      : "aucune";
  }

  private async enregistrer(
    compteId: string,
    d: { typePiece: string; versionConsentement: string; recto: string; verso: string; selfie: string },
    motif: VerificationIdentite["motif"],
    recuperationId: string | null,
    maintenant: Date,
  ): Promise<VerificationIdentite> {
    const images = NATURES.map((nature) => {
      const contenu = Buffer.from(d[nature], "base64");
      if (contenu.length > TAILLE_MAX_IMAGE)
        throw new BadRequestException(`Image trop lourde (${nature}) : 2 Mo au plus`);
      if (!typeImage(contenu)) throw new BadRequestException(`Image invalide (${nature}) : JPEG ou PNG attendu`);
      return { nature, contenu };
    });
    const [{ n }] = (await this.base.requete<{ n: string | number }>(
      "SELECT count(*) AS n FROM comptes.verifications_identite WHERE compte_id = $1 AND deposee_le > $2",
      [compteId, new Date(maintenant.getTime() - 24 * 60 * 60 * 1000).toISOString()],
    )) as [{ n: string | number }];
    if (Number(n) >= DEPOTS_MAX_PAR_JOUR) {
      throw new HttpException("Trop de dépôts aujourd'hui : réessayer demain", HttpStatus.TOO_MANY_REQUESTS);
    }

    const id = randomUUID();
    let ligne: LigneVerification;
    try {
      // L'index unique garantit un seul dossier en attente par compte, même pour deux dépôts simultanés.
      [ligne] = (await this.base.requete<LigneVerification>(
        `INSERT INTO comptes.verifications_identite
           (id, compte_id, type_piece, consentement_le, version_consentement, deposee_le, statut, motif, recuperation_id)
         VALUES ($1, $2, $3, $4, $5, $4, 'en_attente', $6, $7) RETURNING *`,
        [id, compteId, d.typePiece, maintenant.toISOString(), d.versionConsentement, motif, recuperationId],
      )) as [LigneVerification];
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Un dossier est déjà en attente de décision");
      throw e;
    }
    const deposees: string[] = [];
    try {
      for (const { nature, contenu } of images) {
        const cle = `identite/${id}/${nature}`;
        await this.stockage.deposer(cle, contenu);
        deposees.push(cle);
        await this.base.requete(
          "INSERT INTO comptes.pieces_identite (verification_id, nature, cle_stockage, empreinte) VALUES ($1, $2, $3, $4)",
          [id, nature, cle, createHash("sha256").update(contenu).digest("hex")],
        );
      }
    } catch (e) {
      // Dépôt incomplet : rien ne reste, ni fichier ni dossier.
      for (const cle of deposees) await this.stockage.supprimer(cle).catch(() => undefined);
      await this.base.requete("DELETE FROM comptes.pieces_identite WHERE verification_id = $1", [id]);
      await this.base.requete("DELETE FROM comptes.verifications_identite WHERE id = $1", [id]);
      throw e;
    }
    return versVerification(ligne);
  }

  /** Mon dernier dossier, sans aucune image. */
  async consulterLeMien(compteId: string): Promise<VerificationIdentite> {
    const [l] = await this.base.requete<LigneVerification>(
      `SELECT * FROM comptes.verifications_identite WHERE compte_id = $1 AND motif = 'niveau2'
       ORDER BY deposee_le DESC, id LIMIT 1`,
      [compteId],
    );
    if (!l) throw new NotFoundException("Aucun dossier d'identité déposé");
    return versVerification(l);
  }

  async listerEnAttente(parMembreId: string) {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<LigneVerification & { nom: string; numero: string }>(
      `SELECT v.*, c.nom, c.numero FROM comptes.verifications_identite v JOIN comptes.comptes c ON c.id = v.compte_id
       WHERE v.statut = 'en_attente' ORDER BY v.deposee_le, v.id`,
    );
    return lignes.map((l) => ({ ...versVerification(l), nom: l.nom, numero: l.numero }));
  }

  /** Ouvre une pièce d'un dossier en attente. L'ouverture est journalisée avant la lecture. */
  async lirePiece(id: string, nature: string, parMembreId: string) {
    this.exigerAdministrateur(parMembreId);
    const v = await this.trouver(id);
    if (!(NATURES as readonly string[]).includes(nature)) throw new NotFoundException("Pièce inconnue");
    if (v.compte_id === parMembreId) throw new ForbiddenException("Un administrateur ne traite pas son propre dossier");
    if (v.statut !== "en_attente") throw new BadRequestException("Dossier déjà décidé : la pièce ne s'ouvre plus");
    const [p] = await this.base.requete<{ cle_stockage: string }>(
      "SELECT cle_stockage FROM comptes.pieces_identite WHERE verification_id = $1 AND nature = $2 AND supprimee_le IS NULL",
      [id, nature],
    );
    if (!p) throw new NotFoundException("Pièce supprimée");
    await this.base.requete(
      "INSERT INTO comptes.acces_pieces (verification_id, nature, administrateur_id) VALUES ($1, $2, $3)",
      [id, nature, parMembreId],
    );
    const contenu = await this.stockage.lire(p.cle_stockage);
    return { nature, type: typeImage(contenu) ?? "application/octet-stream", contenu: contenu.toString("base64") };
  }

  async decider(
    id: string,
    decision: "validee" | "refusee",
    motif: string,
    parMembreId: string,
    maintenant = new Date(),
  ): Promise<VerificationIdentite> {
    this.exigerAdministrateur(parMembreId);
    const avant = await this.trouver(id);
    if (avant.compte_id === parMembreId) {
      throw new ForbiddenException("Un administrateur ne décide pas de sa propre identité");
    }
    // Mise à jour conditionnelle : deux décisions simultanées, une seule passe.
    const [l] = await this.base.requete<LigneVerification>(
      `UPDATE comptes.verifications_identite SET statut = $2, motif_decision = $3, decidee_par = $4, decidee_le = $5
       WHERE id = $1 AND statut = 'en_attente' RETURNING *`,
      [id, decision, motif, parMembreId, maintenant.toISOString()],
    );
    if (!l) throw new BadRequestException("Dossier déjà décidé");
    const decidee = versVerification(l);
    const recuperation = decidee.motif === "recuperation";
    if (decision === "validee" && !recuperation) await this.comptes.passerAuNiveau2(decidee.compteId);
    // Trace au registre : une empreinte, sans le motif ni aucune donnée de la pièce.
    await this.registre.enregistrer(
      canonique({
        objet: "decision_identite",
        verificationId: id,
        compteId: decidee.compteId,
        decision,
        administrateurId: parMembreId,
        decideeLe: decidee.decideeLe,
      }),
    );
    // Selfie supprimé tout de suite ; tout en cas de refus. Un échec est repris par la purge du planificateur.
    // Pièces d'une récupération : elles n'ont servi qu'à cette décision, rien n'est gardé.
    await this.supprimerPieces(id, decision === "refusee" || recuperation ? NATURES : ["selfie"]).catch((e: unknown) =>
      this.journal.error(`Suppression après décision à reprendre : ${e instanceof Error ? e.message : String(e)}`),
    );
    const compte = recuperation ? undefined : await this.comptes.chercher(decidee.compteId);
    if (compte) {
      await this.sms.mettreEnFile(
        `identite:${id}:decision`,
        compte.numero,
        decision === "validee"
          ? "MonDo : identité vérifiée. Vous pouvez rejoindre des cercles ouverts. Votre selfie a été supprimé."
          : "MonDo : vérification d'identité refusée. Le motif est dans l'application ; vos images ont été supprimées.",
      );
      this.sms.declencher();
    }
    return decidee;
  }

  /** Un cercle du membre se termine : la carte se garde 5 ans à partir du plus tardif. */
  async noterFinDeCercle(compteId: string, termineLe: Date): Promise<void> {
    await this.base.requete(
      `UPDATE comptes.verifications_identite
       SET dernier_cercle_termine_le = GREATEST(COALESCE(dernier_cercle_termine_le, $2), $2)
       WHERE compte_id = $1 AND statut = 'validee' AND motif = 'niveau2'`,
      [compteId, termineLe.toISOString()],
    );
  }

  /**
   * Passage régulier, rejouable : (1) reprend les suppressions manquées après une décision ; (2) supprime la
   * carte 5 ans après la décision ou la fin du dernier cercle du membre, jamais tant qu'il a un cercle en
   * cours (`aUnCercleEnCours` est fourni par l'appelant : ce module ne lit pas les cercles). Rend le nombre
   * d'images supprimées.
   */
  async purger(maintenant: Date, aUnCercleEnCours: (compteId: string) => Promise<boolean>): Promise<number> {
    let supprimees = 0;
    const manquees = await this.base.requete<{ verification_id: string; nature: NaturePiece }>(
      `SELECT p.verification_id, p.nature FROM comptes.pieces_identite p
       JOIN comptes.verifications_identite v ON v.id = p.verification_id
       WHERE p.supprimee_le IS NULL
         AND (v.statut = 'refusee' OR (v.statut = 'validee' AND (p.nature = 'selfie' OR v.motif = 'recuperation')))`,
    );
    for (const m of manquees) supprimees += await this.supprimerPieces(m.verification_id, [m.nature]);

    const limite = new Date(maintenant);
    limite.setUTCFullYear(limite.getUTCFullYear() - DUREE_CONSERVATION_CARTE_ANS);
    const echues = await this.base.requete<{ id: string; compte_id: string }>(
      `SELECT v.id, v.compte_id FROM comptes.verifications_identite v
       WHERE v.statut = 'validee' AND v.motif = 'niveau2' AND GREATEST(v.decidee_le, COALESCE(v.dernier_cercle_termine_le, v.decidee_le)) < $1
         AND EXISTS (SELECT 1 FROM comptes.pieces_identite p WHERE p.verification_id = v.id AND p.supprimee_le IS NULL)`,
      [limite.toISOString()],
    );
    for (const v of echues) {
      if (await aUnCercleEnCours(v.compte_id)) continue;
      supprimees += await this.supprimerPieces(v.id, NATURES);
    }
    return supprimees;
  }

  /** Efface du stockage puis marque en base : rejouable, un fichier déjà absent ne gêne pas. */
  private async supprimerPieces(verificationId: string, natures: readonly NaturePiece[]): Promise<number> {
    const pieces = await this.base.requete<{ nature: string; cle_stockage: string }>(
      `SELECT nature, cle_stockage FROM comptes.pieces_identite
       WHERE verification_id = $1 AND nature = ANY($2::text[]) AND supprimee_le IS NULL`,
      [verificationId, [...natures]],
    );
    for (const p of pieces) {
      await this.stockage.supprimer(p.cle_stockage);
      await this.base.requete(
        "UPDATE comptes.pieces_identite SET supprimee_le = now() WHERE verification_id = $1 AND nature = $2",
        [verificationId, p.nature],
      );
    }
    return pieces.length;
  }

  private exigerAdministrateur(membreId: string): void {
    if (!estAdministrateur(membreId)) throw new ForbiddenException("Réservé à l'administrateur");
  }

  private async trouver(id: string): Promise<LigneVerification> {
    const [l] = UUID.test(id)
      ? await this.base.requete<LigneVerification>("SELECT * FROM comptes.verifications_identite WHERE id = $1", [id])
      : [];
    if (!l) throw new NotFoundException("Dossier introuvable");
    return l;
  }
}
