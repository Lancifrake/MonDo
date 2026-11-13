import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { createHash, randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees, type Executeur } from "../../base/base-de-donnees.js";
import { EvenementsInternes, type FraisDeTour } from "../../evenements/evenements-internes.js";
import { RegistreService, type RegistreDuCercle } from "../../registre/registre.service.js";
import { attribuerLesPlaces, premierePlaceAutorisee, zoneDe } from "../../score/attribution-des-places.js";
import { baremeExact, taillesDesZones, type LigneBareme } from "../../score/frais.js";
import { calculerOrdreDePassage } from "../../score/ordre-de-passage.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { FileSms } from "../../sms/file-sms.js";
import { fcfa } from "../../sms/montant.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { periodeMinimaleJours, type Frequence } from "../cotisations/calendrier.js";
import { CotisationsService } from "../cotisations/cotisations.service.js";
import { ScoreService } from "../score/score.service.js";

export interface Reglement {
  montant: number;
  frequence: Frequence;
  /** Avec frequence « jours » seulement : tous les combien de jours (1 à 60). */
  periodeJours?: number;
  nombreMembres: number;
  penaliteRetard: number;
  delaiGraceJours: number;
  /** Ouvert à des inconnus : exige l'identité vérifiée (niveau 2). */
  ouvert: boolean;
  /** Jours avant la date limite où l'assistant peut rappeler. Absent : aucun rappel avant l'échéance. */
  rappelsAvantEcheanceJours?: number[];
  /** Date limite des cotisations du premier tour ; décalée d'une période si le cercle n'est pas complet à temps. */
  datePremierTour: string;
  /**
   * Frais du modèle A (choix de David, 11/11), en francs, place par place : chaque membre signe des montants.
   * Obligatoire à la création, et égal au calcul de `calculerBareme`. Absent des cercles d'avant.
   */
  bareme?: LigneBareme[];
  /** Score minimum pour rejoindre, fixé par l'organisateur (M3). Absent : pas de seuil. */
  scoreMinimum?: number;
  /** Cercle privé : ordre de passage fixé par l'organisateur, identifiants du premier au dernier (11/11). */
  ordreFixe?: string[];
}

export interface PlaceOrdre {
  position: number;
  zone: string;
  membreId: string;
  /** Place que le membre avait signée ; elle peut différer de la place obtenue (conflit, score). */
  placeSouhaitee?: number;
}

export interface Cercle {
  id: string;
  organisateurId: string;
  reglement: Reglement;
  empreinteReglement: string;
  /** Cercle terminé dont celui-ci est le cycle suivant. */
  cerclePrecedentId?: string;
  /** Membres actuels, dans l'ordre d'inscription ; ceux qui sont partis sont dans `partis`. */
  membres: string[];
  /** Membres qui ont quitté le cercle en cours de cycle. */
  partis?: string[];
  /** terminé : fin de grâce du dernier tour passée ; défauts, litiges et dossier de preuve continuent. */
  statut: "en_attente" | "complet" | "termine";
  ordre?: PlaceOrdre[];
  termineLe?: string;
}

/** Ce qu'un non-membre voit avec le lien d'invitation : de quoi décider et signer, jamais qui est dedans. */
export type CerclePourNonMembre = Omit<Cercle, "membres" | "ordre"> & {
  placesRestantes: number;
  /** Place la plus tôt que le score du demandeur lui permet de demander. Absente si l'ordre est fixé. */
  premierePlaceAutorisee?: number;
  /** Ordre fixé par l'organisateur : la liste n'est montrée qu'aux membres prévus. */
  ordreFixeParOrganisateur?: true;
  /** Ma place dans l'ordre fixé, si l'organisateur m'y a mis. */
  placeFixee?: number;
  /** Mon score atteint-il le seuil d'entrée du cercle ? */
  scoreSuffisant: boolean;
};

/** Un cercle ouvert du catalogue, vu par quelqu'un qui cherche un cercle : jamais qui est dedans ni qui l'organise. */
export interface CercleDuCatalogue {
  id: string;
  reglement: Reglement;
  statut: Cercle["statut"];
  placesRestantes: number;
  premierePlaceAutorisee: number;
  scoreSuffisant: boolean;
}

/** Plafond d'invitations par cercle : trois fois le nombre de places (choix prudent contre l'envoi en série). */
export const INVITATIONS_PAR_PLACE = 3;

/** Résumé d'un cercle pour l'un de ses membres : de quoi afficher sa liste de cercles. */
export interface ResumeCercle {
  id: string;
  organisateur: boolean;
  reglement: Reglement;
  statut: Cercle["statut"];
  nombreInscrits: number;
  /** Ma place dans l'ordre de passage, dès que le cercle est complet. */
  maPlace?: number;
  termineLe?: string;
}

interface LigneCercle extends Record<string, unknown> {
  id: string;
  organisateur_id: string;
  reglement: Reglement;
  empreinte_reglement: string;
  statut: Cercle["statut"];
  ordre: PlaceOrdre[] | null;
  termine_le?: Date | string | null;
  cercle_precedent_id?: string | null;
}

/**
 * L'organisateur signe en un seul acte le règlement et son propre engagement, place souhaitée comprise.
 * Sans place (cercles d'avant le 08/11), le message est celui d'origine.
 */
export const messageReglement = (organisateurId: string, r: Reglement, placeSouhaitee?: number) =>
  canonique({
    objet: "reglement",
    organisateurId,
    reglement: r,
    ...(placeSouhaitee === undefined ? {} : { placeSouhaitee }),
  });
/** Engagement d'un membre : le règlement (par son empreinte) et la place qu'il souhaite. */
export const messageEngagement = (
  cercleId: string,
  empreinteReglement: string,
  membreId: string,
  placeSouhaitee?: number,
) =>
  canonique({
    objet: "engagement",
    cercleId,
    empreinteReglement,
    membreId,
    ...(placeSouhaitee === undefined ? {} : { placeSouhaitee }),
  });

/** Échange de places : les deux membres signent le même message, qui nomme le cercle et les deux places. */
export const messageEchange = (
  cercleId: string,
  demandeurId: string,
  placeDemandeur: number,
  cedantId: string,
  placeCedant: number,
) => canonique({ objet: "echange_de_places", cercleId, demandeurId, placeDemandeur, cedantId, placeCedant });

const UUID = /^[0-9a-f-]{36}$/i;

/** Barème signé et ordre figé : qui doit quoi à qui. La remise va à chaque membre d'une place de fin. */
function fraisParTour(bareme: readonly LigneBareme[], ordre: readonly string[]): FraisDeTour[] {
  const { fin, premierePlaceDeFin } = taillesDesZones(ordre.length);
  const placesDeFin = ordre.slice(premierePlaceDeFin - 1, premierePlaceDeFin - 1 + fin);
  return bareme.map((l) => ({
    tour: l.place,
    partMonDo: l.partMonDo,
    remises: placesDeFin.map((creancierId) => ({ creancierId, montant: l.remiseParPlaceDeFin })),
  }));
}

@Injectable()
export class CerclesService {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(FileSms) private readonly sms: FileSms,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
  ) {
    this.evenements.ecouter("cercle_termine", (e) => this.terminer(e.cercleId, e.termineLe));
    this.evenements.ecouter("compte_bloque", (e) =>
      this.prevenirLesAutres(
        e.membreId,
        `blocage:${e.membreId}:${e.bloqueLe}`,
        "MonDo : le compte d'un membre de votre cercle est bloqué le temps d'une vérification. Ses échéances sont suspendues, les vôtres ne changent pas.",
      ),
    );
    this.evenements.ecouter("compte_debloque", (e) =>
      this.prevenirLesAutres(
        e.membreId,
        `deblocage:${e.membreId}:${e.debloqueLe}`,
        "MonDo : le compte bloqué d'un membre de votre cercle est débloqué. Ses échéances reprennent, décalées de la durée du blocage.",
      ),
    );
  }

  /**
   * SMS, par la file, aux autres membres des cercles en cours du membre (règle du 03/11). Le message ne le
   * nomme pas. Une clé par destinataire : un événement rejoué ne donne qu'un SMS.
   */
  private async prevenirLesAutres(membreId: string, cle: string, texte: string): Promise<void> {
    const autres = await this.base.requete<{ membre_id: string }>(
      `SELECT DISTINCT b.membre_id FROM cercles.adhesions a
       JOIN cercles.cercles c ON c.id = a.cercle_id AND c.statut = 'complet'
       JOIN cercles.adhesions b ON b.cercle_id = a.cercle_id AND b.membre_id <> a.membre_id AND b.parti_le IS NULL
       WHERE a.membre_id = $1 AND a.parti_le IS NULL`,
      [membreId],
    );
    for (const { membre_id } of autres) {
      const compte = await this.comptes.chercher(membre_id);
      if (compte) await this.sms.mettreEnFile(`${cle}:${membre_id}`, compte.numero, texte);
    }
    if (autres.length > 0) this.sms.declencher();
  }

  /** Une seule fois : un cercle déjà terminé garde sa date. */
  private async terminer(cercleId: string, termineLe: string): Promise<void> {
    const fini = await this.base.requete(
      "UPDATE cercles.cercles SET statut = 'termine', termine_le = $2 WHERE id = $1 AND statut = 'complet' RETURNING id",
      [cercleId, termineLe],
    );
    if (fini.length === 0) return;
    await this.registre.enregistrer(canonique({ objet: "fin_cercle", cercleId, termineLe }));
    for (const membreId of await this.membres(this.base, cercleId)) {
      await this.evenements.publier({ type: "fin_de_cercle_pour_membre", cercleId, membreId, termineLe });
    }
  }

  /** Vrai si le membre est dans un cercle qui n'est pas terminé (en attente ou en cours). */
  async aUnCercleEnCours(membreId: string): Promise<boolean> {
    const lignes = await this.base.requete(
      `SELECT 1 FROM cercles.adhesions a JOIN cercles.cercles c ON c.id = a.cercle_id
       WHERE a.membre_id = $1 AND a.parti_le IS NULL AND c.statut <> 'termine' LIMIT 1`,
      [membreId],
    );
    return lignes.length > 0;
  }

  async creer(
    d: {
      organisateurId: string;
      reglement: Reglement;
      placeSouhaitee: number;
      signature: string;
      /** Cycle suivant d'un cercle terminé, relancé par son organisateur. */
      cerclePrecedentId?: string;
    },
    maintenant: Date = new Date(),
  ): Promise<Cercle> {
    const precedent = d.cerclePrecedentId ? await this.trouver(d.cerclePrecedentId) : undefined;
    if (precedent && precedent.organisateurId !== d.organisateurId) {
      throw new ForbiddenException("Seul l'organisateur relance son cercle");
    }
    if (precedent && precedent.statut !== "termine") {
      throw new BadRequestException("Un cercle ne se relance qu'une fois terminé");
    }
    if (Date.parse(d.reglement.datePremierTour) <= maintenant.getTime()) {
      throw new BadRequestException("La date du premier tour doit être dans le futur");
    }
    if (!baremeExact(d.reglement.bareme, d.reglement.nombreMembres, d.reglement.montant)) {
      throw new BadRequestException(
        "Barème des frais absent ou inexact : le demander par GET /cercles/bareme et l'écrire dans le règlement",
      );
    }
    const organisateur = await this.comptes.trouver(d.organisateurId);
    if (d.reglement.ordreFixe) {
      for (const id of d.reglement.ordreFixe) {
        if (!(await this.comptes.chercher(id))) throw new BadRequestException("Ordre fixé : un membre est inconnu");
      }
    }
    await this.verifierPlace(d.organisateurId, d.placeSouhaitee, d.reglement);
    // Forme validée en amont (schemaReglement).
    const message = messageReglement(d.organisateurId, d.reglement, d.placeSouhaitee);
    if (!verifierSignature(organisateur.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature du règlement invalide");
    }
    const id = randomUUID();
    const empreinte = await this.registre.enregistrer(message, { cercleId: id });
    await this.base.transaction(async (tx) => {
      await tx.requete(
        `INSERT INTO cercles.cercles (id, organisateur_id, reglement, empreinte_reglement, statut, cercle_precedent_id)
         VALUES ($1, $2, $3, $4, 'en_attente', $5)`,
        [id, d.organisateurId, JSON.stringify(d.reglement), empreinte, precedent?.id ?? null],
      );
      await tx.requete(
        "INSERT INTO cercles.adhesions (cercle_id, membre_id, rang, signature, place_souhaitee) VALUES ($1, $2, 1, $3, $4)",
        [id, d.organisateurId, d.signature, d.placeSouhaitee],
      );
    });
    await this.evenements.publier({
      type: "adhesion_enregistree",
      cercleId: id,
      membreId: d.organisateurId,
      cerclePrive: !d.reglement.ouvert,
    });
    if (precedent) {
      // Les anciens membres sont invités : chacun signera de nouveau, en connaissant le nouveau règlement.
      for (const ancien of precedent.membres.filter((m) => m !== d.organisateurId)) {
        const compte = await this.comptes.chercher(ancien);
        if (!compte) continue;
        await this.sms.mettreEnFile(
          `relance:${id}:${ancien}`,
          compte.numero,
          `MonDo : votre cercle repart pour un nouveau cycle (${fcfa(d.reglement.montant)}). ` +
            `Pour y entrer, ouvrez MonDo et saisissez l'identifiant ${id}.`,
        );
      }
      this.sms.declencher();
    }
    return this.trouver(id);
  }

  async rejoindre(
    cercleId: string,
    d: { membreId: string; placeSouhaitee: number; signature: string },
  ): Promise<Cercle> {
    const cercle = await this.trouver(cercleId);
    const membre = await this.comptes.trouver(d.membreId);
    if (cercle.reglement.ouvert && membre.niveau < 2) {
      throw new ForbiddenException("Identité vérifiée (niveau 2) requise pour un cercle ouvert");
    }
    if (cercle.reglement.scoreMinimum !== undefined) {
      const { score } = await this.score.consulter(d.membreId);
      if (score < cercle.reglement.scoreMinimum) {
        throw new ForbiddenException(
          `Votre score (${score}) est sous le seuil fixé par l'organisateur (${cercle.reglement.scoreMinimum})`,
        );
      }
    }
    await this.verifierPlace(d.membreId, d.placeSouhaitee, cercle.reglement);
    const message = messageEngagement(cercle.id, cercle.empreinteReglement, d.membreId, d.placeSouhaitee);
    if (!verifierSignature(membre.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature de l'engagement invalide");
    }

    // Verrou sur la ligne du cercle : deux adhésions simultanées ne dépassent jamais le nombre de places.
    const complet = await this.base.transaction(async (tx) => {
      const [verrou] = await tx.requete<LigneCercle>("SELECT * FROM cercles.cercles WHERE id = $1 FOR UPDATE", [
        cercleId,
      ]);
      if (verrou!.statut !== "en_attente") {
        throw new BadRequestException(verrou!.statut === "termine" ? "Cercle terminé" : "Cercle complet");
      }
      const membres = await this.membres(tx, cercleId);
      if (membres.includes(d.membreId)) throw new BadRequestException("Déjà membre");
      membres.push(d.membreId);
      await tx.requete(
        "INSERT INTO cercles.adhesions (cercle_id, membre_id, rang, signature, place_souhaitee) VALUES ($1, $2, $3, $4, $5)",
        [cercleId, d.membreId, membres.length, d.signature, d.placeSouhaitee],
      );
      if (membres.length < cercle.reglement.nombreMembres) return undefined;
      await tx.requete("UPDATE cercles.cercles SET statut = 'complet' WHERE id = $1", [cercleId]);
      return membres;
    });

    await this.registre.enregistrer(message);
    await this.evenements.publier({
      type: "adhesion_enregistree",
      cercleId,
      membreId: d.membreId,
      cerclePrive: !cercle.reglement.ouvert,
    });
    if (complet) {
      const completLe = new Date().toISOString();
      const ordre = await this.figerOrdre(cercleId, complet);
      await this.registre.enregistrer(canonique({ objet: "ordre", cercleId, ordre }));
      const { montant, frequence, periodeJours, delaiGraceJours, datePremierTour, bareme, penaliteRetard } =
        cercle.reglement;
      await this.evenements.publier({
        type: "cercle_complet",
        cercleId,
        ordre: ordre.map((p) => p.membreId),
        montant,
        frequence,
        ...(periodeJours ? { periodeJours } : {}),
        delaiGraceJours,
        penaliteRetard,
        datePremierTour,
        completLe,
        ...(bareme
          ? {
              frais: fraisParTour(
                bareme,
                ordre.map((p) => p.membreId),
              ),
            }
          : {}),
      });
    }
    return this.trouver(cercleId);
  }

  /**
   * Départ en cours de cycle (choix de David, 11/11) : libre tant que le membre n'a rien reçu de sa cagnotte,
   * impossible après. Le module Cotisations vérifie et applique d'abord (tout ou rien) ; ensuite le départ est
   * noté ici, inscrit au registre, publié (score −15) et annoncé aux autres membres.
   */
  async quitter(cercleId: string, membreId: string, maintenant: Date = new Date()) {
    const cercle = await this.trouver(cercleId);
    if (cercle.partis?.includes(membreId)) throw new BadRequestException("Vous avez déjà quitté ce cercle");
    if (!cercle.membres.includes(membreId)) throw new ForbiddenException("Réservé aux membres du cercle");
    if (cercle.statut !== "complet") {
      throw new BadRequestException(
        cercle.statut === "termine"
          ? "Cercle terminé"
          : "Le départ n'est prévu que pour un cercle complet, en cours de cycle",
      );
    }
    const { frequence, periodeJours } = cercle.reglement;
    const limite = new Date(maintenant.getTime() + periodeMinimaleJours(frequence, periodeJours) * 24 * 60 * 60 * 1000);
    const { remboursements } = await this.cotisations.enregistrerDepart(cercleId, membreId, maintenant, limite);
    const partiLe = maintenant.toISOString();
    // Une seule demande note le départ ici : la suite (registre, score, SMS) n'a lieu qu'une fois, y compris
    // quand une demande est rejouée après une panne survenue juste après l'étape des cotisations.
    const note = await this.base.requete(
      "UPDATE cercles.adhesions SET parti_le = $3 WHERE cercle_id = $1 AND membre_id = $2 AND parti_le IS NULL RETURNING membre_id",
      [cercleId, membreId, partiLe],
    );
    if (note.length === 0) throw new BadRequestException("Vous avez déjà quitté ce cercle");
    await this.registre.enregistrer(canonique({ objet: "depart", cercleId, membreId, partiLe }));
    await this.evenements.publier({ type: "depart_enregistre", cercleId, membreId, partiLe });
    for (const autre of cercle.membres.filter((m) => m !== membreId)) {
      const compte = await this.comptes.chercher(autre);
      if (compte) {
        await this.sms.mettreEnFile(
          `depart:${cercleId}:${membreId}:${autre}`,
          compte.numero,
          "MonDo : un membre a quitté votre cercle avant son tour. Son tour est supprimé, ses cotisations à venir sont annulées. Le détail est dans l'application.",
        );
      }
    }
    this.sms.declencher();
    return { cercleId, partiLe, remboursements };
  }

  /** Échange signé par les deux : leurs places sont permutées dans l'ordre figé, sous verrou de la ligne. */
  async echangerPlaces(cercleId: string, a: string, b: string): Promise<void> {
    const ordre = await this.base.transaction(async (tx) => {
      const [l] = await tx.requete<LigneCercle>("SELECT * FROM cercles.cercles WHERE id = $1 FOR UPDATE", [cercleId]);
      const nouvel = (l?.ordre ?? []).map((p) =>
        p.membreId === a ? { ...p, membreId: b } : p.membreId === b ? { ...p, membreId: a } : p,
      );
      await tx.requete("UPDATE cercles.cercles SET ordre = $2 WHERE id = $1", [cercleId, JSON.stringify(nouvel)]);
      return nouvel;
    });
    // Le nouvel ordre est inscrit à son tour : la vérification du registre le reconnaît comme légitime.
    await this.registre.enregistrer(canonique({ objet: "ordre", cercleId, ordre }));
  }

  /**
   * Registre du cercle, pour ses membres : chaque événement avec son empreinte, son lot et sa preuve, et la
   * vérification que le règlement, l'ordre et les engagements en base sont bien ceux qui ont été inscrits.
   */
  async registreDuCercle(cercleId: string, demandeurId: string): Promise<RegistreDuCercle> {
    const cercle = await this.trouver(cercleId);
    if (![...cercle.membres, ...(cercle.partis ?? [])].includes(demandeurId)) {
      throw new ForbiddenException("Registre réservé aux membres du cercle");
    }
    const evenements = await this.registre.consulterCercle(cercleId);
    const adhesions = await this.base.requete<{ membre_id: string; rang: number; place_souhaitee: number | null }>(
      "SELECT membre_id, rang, place_souhaitee FROM cercles.adhesions WHERE cercle_id = $1 ORDER BY rang",
      [cercleId],
    );
    const placeOrg = adhesions.find((a) => a.rang === 1)?.place_souhaitee ?? undefined;
    const documents = [
      {
        objet: "reglement",
        conforme: await this.registre.contientPour(
          cercleId,
          messageReglement(cercle.organisateurId, cercle.reglement, placeOrg),
        ),
      },
      ...(cercle.ordre
        ? [
            {
              objet: "ordre",
              conforme: await this.registre.contientPour(
                cercleId,
                canonique({ objet: "ordre", cercleId, ordre: cercle.ordre }),
              ),
            },
          ]
        : []),
      {
        objet: "engagements",
        conforme: (
          await Promise.all(
            adhesions
              .filter((a) => a.rang > 1)
              .map((a) =>
                this.registre.contientPour(
                  cercleId,
                  messageEngagement(cercleId, cercle.empreinteReglement, a.membre_id, a.place_souhaitee ?? undefined),
                ),
              ),
          )
        ).every(Boolean),
      },
    ];
    const integre = documents.every((d) => d.conforme) && evenements.every((e) => e.statut !== "alteree");
    return { cercleId, evenements, documents, integre };
  }

  async trouver(id: string): Promise<Cercle> {
    if (!UUID.test(id)) throw new NotFoundException("Cercle introuvable");
    const [l] = await this.base.requete<LigneCercle>("SELECT * FROM cercles.cercles WHERE id = $1", [id]);
    if (!l) throw new NotFoundException("Cercle introuvable");
    const partis = (
      await this.base.requete<{ membre_id: string }>(
        "SELECT membre_id FROM cercles.adhesions WHERE cercle_id = $1 AND parti_le IS NOT NULL ORDER BY parti_le",
        [id],
      )
    ).map((x) => x.membre_id);
    return {
      id: l.id,
      organisateurId: l.organisateur_id,
      reglement: l.reglement,
      empreinteReglement: l.empreinte_reglement,
      ...(l.cercle_precedent_id ? { cerclePrecedentId: l.cercle_precedent_id } : {}),
      membres: await this.membres(this.base, id),
      ...(partis.length > 0 ? { partis } : {}),
      statut: l.statut,
      ...(l.ordre ? { ordre: l.ordre } : {}),
      ...(l.termine_le ? { termineLe: new Date(l.termine_le).toISOString() } : {}),
    };
  }

  /** Cercles où le membre a adhéré, du plus récent au plus ancien. Rien sur les autres membres. */
  async listerPour(membreId: string): Promise<ResumeCercle[]> {
    const lignes = await this.base.requete<LigneCercle & { inscrits: number | string }>(
      `SELECT c.*, (SELECT count(*) FROM cercles.adhesions x WHERE x.cercle_id = c.id) AS inscrits
       FROM cercles.cercles c JOIN cercles.adhesions a ON a.cercle_id = c.id
       WHERE a.membre_id = $1 ORDER BY c.cree_le DESC, c.id`,
      [membreId],
    );
    return lignes.map((l) => {
      const maPlace = l.ordre?.find((p) => p.membreId === membreId)?.position;
      return {
        id: l.id,
        organisateur: l.organisateur_id === membreId,
        reglement: l.reglement,
        statut: l.statut,
        nombreInscrits: Number(l.inscrits),
        ...(maPlace ? { maPlace } : {}),
        ...(l.termine_le ? { termineLe: new Date(l.termine_le).toISOString() } : {}),
      };
    });
  }

  /**
   * Règlement public, membres privés (choix de David, 06/11) : avec le lien, un non-membre voit le règlement,
   * le statut et les places restantes ; la liste des membres et l'ordre de passage sont réservés aux membres.
   */
  async consulterPour(id: string, demandeurId: string): Promise<Cercle | CerclePourNonMembre> {
    const { membres, ordre, ...cercle } = await this.trouver(id);
    // Les places libérées par un départ ne se reprennent pas : le remplacement n'est pas prévu.
    const placesRestantes =
      cercle.statut === "en_attente" ? Math.max(0, cercle.reglement.nombreMembres - membres.length) : 0;
    if (membres.includes(demandeurId)) return { ...cercle, membres, ...(ordre ? { ordre } : {}), placesRestantes };
    const { ordreFixe, ...reglementSansOrdre } = cercle.reglement;
    const { score, premieresPlacesFermees } = await this.score.consulter(demandeurId);
    const scoreSuffisant = score >= (cercle.reglement.scoreMinimum ?? 0);
    if (ordreFixe) {
      // Un membre prévu lit l'ordre qu'il va signer ; un inconnu qui a le lien ne voit pas qui est attendu.
      const placeFixee = ordreFixe.indexOf(demandeurId) + 1;
      return placeFixee > 0
        ? { ...cercle, placesRestantes, ordreFixeParOrganisateur: true, placeFixee, scoreSuffisant }
        : { ...cercle, reglement: reglementSansOrdre, placesRestantes, ordreFixeParOrganisateur: true, scoreSuffisant };
    }
    return {
      ...cercle,
      placesRestantes,
      premierePlaceAutorisee: premierePlaceAutorisee(score, cercle.reglement.nombreMembres, {
        exclusDuDebut: premieresPlacesFermees,
      }),
      scoreSuffisant,
    };
  }

  /**
   * Catalogue (US7) : les cercles ouverts à des inconnus qui cherchent encore des membres, les plus récents
   * d'abord, filtrés par montant, fréquence et taille. Les cercles privés n'y figurent jamais : on n'y entre
   * qu'avec le lien.
   */
  async catalogue(
    demandeurId: string,
    filtres: { montantMin?: number; montantMax?: number; frequence?: string; nombreMembresMax?: number },
  ): Promise<CercleDuCatalogue[]> {
    const lignes = await this.base.requete<LigneCercle & { inscrits: number | string }>(
      `SELECT c.*, (SELECT count(*) FROM cercles.adhesions a WHERE a.cercle_id = c.id) AS inscrits
       FROM cercles.cercles c
       WHERE c.statut = 'en_attente' AND (c.reglement->>'ouvert')::boolean
         AND ($1::bigint IS NULL OR (c.reglement->>'montant')::bigint >= $1)
         AND ($2::bigint IS NULL OR (c.reglement->>'montant')::bigint <= $2)
         AND ($3::text IS NULL OR c.reglement->>'frequence' = $3)
         AND ($4::int IS NULL OR (c.reglement->>'nombreMembres')::int <= $4)
       ORDER BY c.cree_le DESC, c.id LIMIT 50`,
      [
        filtres.montantMin ?? null,
        filtres.montantMax ?? null,
        filtres.frequence ?? null,
        filtres.nombreMembresMax ?? null,
      ],
    );
    const { score, premieresPlacesFermees } = await this.score.consulter(demandeurId);
    return lignes.map((l) => ({
      id: l.id,
      reglement: l.reglement,
      statut: l.statut,
      placesRestantes: Math.max(0, l.reglement.nombreMembres - Number(l.inscrits)),
      premierePlaceAutorisee: premierePlaceAutorisee(score, l.reglement.nombreMembres, {
        exclusDuDebut: premieresPlacesFermees,
      }),
      scoreSuffisant: score >= (l.reglement.scoreMinimum ?? 0),
    }));
  }

  /**
   * Invitation par numéro (US4) : un SMS avec l'identifiant du cercle, par la file. Réservée à l'organisateur,
   * tant que le cercle cherche des membres. Le numéro n'est pas gardé : seulement son empreinte salée par le
   * cercle, pour ne pas solliciter deux fois la même personne. On ne dit jamais si le numéro a un compte.
   */
  async inviter(cercleId: string, organisateurId: string, numero: string) {
    const cercle = await this.trouver(cercleId);
    if (cercle.organisateurId !== organisateurId) throw new ForbiddenException("Réservé à l'organisateur du cercle");
    if (cercle.statut !== "en_attente") throw new BadRequestException("Le cercle ne cherche plus de membres");
    const organisateur = await this.comptes.trouver(organisateurId);
    if (organisateur.numero === numero) throw new BadRequestException("Vous êtes déjà dans ce cercle");
    const plafond = INVITATIONS_PAR_PLACE * cercle.reglement.nombreMembres;
    const empreinte = createHash("sha256").update(`${cercleId}:${numero}`).digest("hex");
    // Plafond et écriture en une instruction : deux invitations simultanées ne le dépassent pas.
    const ajoutee = await this.base.requete(
      `INSERT INTO cercles.invitations (cercle_id, empreinte_numero)
       SELECT $1, $2 WHERE (SELECT count(*) FROM cercles.invitations WHERE cercle_id = $1) < $3
       ON CONFLICT DO NOTHING RETURNING empreinte_numero`,
      [cercleId, empreinte, plafond],
    );
    const [{ n }] = (await this.base.requete<{ n: string | number }>(
      "SELECT count(*) AS n FROM cercles.invitations WHERE cercle_id = $1",
      [cercleId],
    )) as [{ n: string | number }];
    if (ajoutee.length === 0) {
      const deja = await this.base.requete(
        "SELECT 1 FROM cercles.invitations WHERE cercle_id = $1 AND empreinte_numero = $2",
        [cercleId, empreinte],
      );
      if (deja.length === 0) {
        throw new HttpException(
          `Plafond atteint : ${plafond} invitations pour ce cercle`,
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      return { invitationsEnvoyees: Number(n), plafond };
    }
    const r = cercle.reglement;
    await this.sms.mettreEnFile(
      `invitation:${cercleId}:${empreinte}`,
      numero,
      `MonDo : ${organisateur.nom} vous invite dans son cercle de ${fcfa(r.montant)} (${r.nombreMembres} membres). ` +
        `Ouvrez MonDo et saisissez l'identifiant ${cercleId}.`,
    );
    this.sms.declencher();
    return { invitationsEnvoyees: Number(n), plafond };
  }

  /** Rang et signature d'un membre : rang 1 = organisateur, qui a signé le règlement lui-même. */
  async adhesion(
    cercleId: string,
    membreId: string,
  ): Promise<{ rang: number; signature: string; placeSouhaitee?: number } | undefined> {
    const [l] = await this.base.requete<{ rang: number; signature: string; place_souhaitee: number | null }>(
      "SELECT rang, signature, place_souhaitee FROM cercles.adhesions WHERE cercle_id = $1 AND membre_id = $2",
      [cercleId, membreId],
    );
    if (!l) return undefined;
    return {
      rang: l.rang,
      signature: l.signature,
      ...(l.place_souhaitee ? { placeSouhaitee: l.place_souhaitee } : {}),
    };
  }

  /**
   * Place comprise dans le cercle, et pas plus tôt que ce que permet le score du membre (on peut toujours plus
   * tard). Ordre fixé par l'organisateur : seuls les membres prévus entrent, chacun à la place écrite dans le
   * règlement ; le score n'intervient pas, puisque tous signent l'ordre en le connaissant.
   */
  private async verifierPlace(membreId: string, place: number, reglement: Reglement): Promise<void> {
    const { nombreMembres, ordreFixe } = reglement;
    if (place > nombreMembres) throw new BadRequestException(`Place entre 1 et ${nombreMembres}`);
    if (ordreFixe) {
      const fixee = ordreFixe.indexOf(membreId) + 1;
      if (fixee === 0) throw new ForbiddenException("Ce cercle est réservé aux membres prévus par l'organisateur");
      if (place !== fixee) {
        throw new BadRequestException(`L'organisateur vous a fixé la place ${fixee} : c'est celle à signer`);
      }
      return;
    }
    const { score, premieresPlacesFermees } = await this.score.consulter(membreId);
    const plusTot = premierePlaceAutorisee(score, nombreMembres, { exclusDuDebut: premieresPlacesFermees });
    if (place < plusTot) {
      throw new BadRequestException(
        premieresPlacesFermees
          ? `Après un défaut, les premières places sont fermées jusqu'à deux cycles terminés sans défaut : place à partir de la ${plusTot}e`
          : `Votre score permet une place à partir de la ${plusTot}e (une place plus tardive reste possible)`,
      );
    }
  }

  private async membres(ex: Executeur, cercleId: string): Promise<string[]> {
    const lignes = await ex.requete<{ membre_id: string }>(
      "SELECT membre_id FROM cercles.adhesions WHERE cercle_id = $1 AND parti_le IS NULL ORDER BY rang",
      [cercleId],
    );
    return lignes.map((l) => l.membre_id);
  }

  /**
   * Ordre figé dès que le cercle est complet. Places souhaitées signées (depuis le 08/11) : attribution par
   * `attribuerLesPlaces` ; cercles d'avant, sans place souhaitée : zones, score, ordre d'inscription.
   * Calculé hors de la transaction d'adhésion, qui ne doit pas attendre le module Score.
   */
  private async figerOrdre(cercleId: string, membres: string[]): Promise<PlaceOrdre[]> {
    const scores = await Promise.all(membres.map((id) => this.score.consulter(id)));
    const places = await this.base.requete<{ membre_id: string; place_souhaitee: number | null }>(
      "SELECT membre_id, place_souhaitee FROM cercles.adhesions WHERE cercle_id = $1",
      [cercleId],
    );
    const souhait = new Map(places.map((l) => [l.membre_id, l.place_souhaitee]));
    const { ordreFixe } = (await this.trouver(cercleId)).reglement;
    const ordre: PlaceOrdre[] = ordreFixe
      ? ordreFixe.map((membreId, i) => ({
          position: i + 1,
          zone: zoneDe(i + 1, ordreFixe.length),
          membreId,
          placeSouhaitee: i + 1,
        }))
      : membres.every((id) => souhait.get(id))
        ? attribuerLesPlaces(
            membres.map((id, i) => ({
              id,
              score: scores[i]!.score,
              rangInscription: i + 1,
              exclusDuDebut: scores[i]!.premieresPlacesFermees,
              placeSouhaitee: souhait.get(id)!,
            })),
          ).map((p) => ({
            position: p.position,
            zone: p.zone,
            membreId: p.membre.id,
            placeSouhaitee: p.membre.placeSouhaitee,
          }))
        : calculerOrdreDePassage(
            membres.map((id, i) => ({
              id,
              score: scores[i]!.score,
              rangInscription: i + 1,
              exclusDuDebut: scores[i]!.premieresPlacesFermees,
            })),
          ).map((p) => ({ position: p.position, zone: p.zone, membreId: p.membre.id }));
    await this.base.requete("UPDATE cercles.cercles SET ordre = $2 WHERE id = $1", [cercleId, JSON.stringify(ordre)]);
    return ordre;
  }
}
