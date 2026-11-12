import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees, type Executeur } from "../../base/base-de-donnees.js";
import { EvenementsInternes, type FraisDeTour } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { attribuerLesPlaces, premierePlaceAutorisee, zoneDe } from "../../score/attribution-des-places.js";
import { baremeExact, taillesDesZones, type LigneBareme } from "../../score/frais.js";
import { calculerOrdreDePassage } from "../../score/ordre-de-passage.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { FileSms } from "../../sms/file-sms.js";
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
};

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
    d: { organisateurId: string; reglement: Reglement; placeSouhaitee: number; signature: string },
    maintenant: Date = new Date(),
  ): Promise<Cercle> {
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
    const empreinte = await this.registre.enregistrer(message);
    const id = randomUUID();
    await this.base.transaction(async (tx) => {
      await tx.requete(
        `INSERT INTO cercles.cercles (id, organisateur_id, reglement, empreinte_reglement, statut)
         VALUES ($1, $2, $3, $4, 'en_attente')`,
        [id, d.organisateurId, JSON.stringify(d.reglement), empreinte],
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
    await this.base.requete(
      "UPDATE cercles.adhesions SET parti_le = $3 WHERE cercle_id = $1 AND membre_id = $2 AND parti_le IS NULL",
      [cercleId, membreId, partiLe],
    );
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
    if (ordreFixe) {
      // Un membre prévu lit l'ordre qu'il va signer ; un inconnu qui a le lien ne voit pas qui est attendu.
      const placeFixee = ordreFixe.indexOf(demandeurId) + 1;
      return placeFixee > 0
        ? { ...cercle, placesRestantes, ordreFixeParOrganisateur: true, placeFixee }
        : { ...cercle, reglement: reglementSansOrdre, placesRestantes, ordreFixeParOrganisateur: true };
    }
    const { score } = await this.score.consulter(demandeurId);
    return {
      ...cercle,
      placesRestantes,
      premierePlaceAutorisee: premierePlaceAutorisee(score, cercle.reglement.nombreMembres),
    };
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
    const { score } = await this.score.consulter(membreId);
    const plusTot = premierePlaceAutorisee(score, nombreMembres);
    if (place < plusTot) {
      throw new BadRequestException(
        `Votre score permet une place à partir de la ${plusTot}e (une place plus tardive reste possible)`,
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
              placeSouhaitee: souhait.get(id)!,
            })),
          ).map((p) => ({
            position: p.position,
            zone: p.zone,
            membreId: p.membre.id,
            placeSouhaitee: p.membre.placeSouhaitee,
          }))
        : calculerOrdreDePassage(membres.map((id, i) => ({ id, score: scores[i]!.score, rangInscription: i + 1 }))).map(
            (p) => ({ position: p.position, zone: p.zone, membreId: p.membre.id }),
          );
    await this.base.requete("UPDATE cercles.cercles SET ordre = $2 WHERE id = $1", [cercleId, JSON.stringify(ordre)]);
    return ordre;
  }
}
