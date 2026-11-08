import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees, type Executeur } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { attribuerLesPlaces, premierePlaceAutorisee } from "../../score/attribution-des-places.js";
import { calculerOrdreDePassage } from "../../score/ordre-de-passage.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { ComptesService } from "../comptes/comptes.service.js";
import type { Frequence } from "../cotisations/calendrier.js";
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
  membres: string[];
  /** terminé : fin de grâce du dernier tour passée ; défauts, litiges et dossier de preuve continuent. */
  statut: "en_attente" | "complet" | "termine";
  ordre?: PlaceOrdre[];
  termineLe?: string;
}

/** Ce qu'un non-membre voit avec le lien d'invitation : de quoi décider et signer, jamais qui est dedans. */
export type CerclePourNonMembre = Omit<Cercle, "membres" | "ordre"> & {
  placesRestantes: number;
  /** Place la plus tôt que le score du demandeur lui permet de demander. */
  premierePlaceAutorisee: number;
};

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

@Injectable()
export class CerclesService {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {
    this.evenements.ecouter("cercle_termine", (e) => this.terminer(e.cercleId, e.termineLe));
  }

  /** Une seule fois : un cercle déjà terminé garde sa date. */
  private async terminer(cercleId: string, termineLe: string): Promise<void> {
    const fini = await this.base.requete(
      "UPDATE cercles.cercles SET statut = 'termine', termine_le = $2 WHERE id = $1 AND statut = 'complet' RETURNING id",
      [cercleId, termineLe],
    );
    if (fini.length > 0) await this.registre.enregistrer(canonique({ objet: "fin_cercle", cercleId, termineLe }));
  }

  async creer(
    d: { organisateurId: string; reglement: Reglement; placeSouhaitee: number; signature: string },
    maintenant: Date = new Date(),
  ): Promise<Cercle> {
    if (Date.parse(d.reglement.datePremierTour) <= maintenant.getTime()) {
      throw new BadRequestException("La date du premier tour doit être dans le futur");
    }
    const organisateur = await this.comptes.trouver(d.organisateurId);
    await this.verifierPlace(d.organisateurId, d.placeSouhaitee, d.reglement.nombreMembres);
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
    await this.evenements.publier({ type: "adhesion_enregistree", cercleId: id, membreId: d.organisateurId });
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
    await this.verifierPlace(d.membreId, d.placeSouhaitee, cercle.reglement.nombreMembres);
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
    await this.evenements.publier({ type: "adhesion_enregistree", cercleId, membreId: d.membreId });
    if (complet) {
      const completLe = new Date().toISOString();
      const ordre = await this.figerOrdre(cercleId, complet);
      await this.registre.enregistrer(canonique({ objet: "ordre", cercleId, ordre }));
      const { montant, frequence, periodeJours, delaiGraceJours, datePremierTour } = cercle.reglement;
      await this.evenements.publier({
        type: "cercle_complet",
        cercleId,
        ordre: ordre.map((p) => p.membreId),
        montant,
        frequence,
        ...(periodeJours ? { periodeJours } : {}),
        delaiGraceJours,
        datePremierTour,
        completLe,
      });
    }
    return this.trouver(cercleId);
  }

  async trouver(id: string): Promise<Cercle> {
    if (!UUID.test(id)) throw new NotFoundException("Cercle introuvable");
    const [l] = await this.base.requete<LigneCercle>("SELECT * FROM cercles.cercles WHERE id = $1", [id]);
    if (!l) throw new NotFoundException("Cercle introuvable");
    return {
      id: l.id,
      organisateurId: l.organisateur_id,
      reglement: l.reglement,
      empreinteReglement: l.empreinte_reglement,
      membres: await this.membres(this.base, id),
      statut: l.statut,
      ...(l.ordre ? { ordre: l.ordre } : {}),
      ...(l.termine_le ? { termineLe: new Date(l.termine_le).toISOString() } : {}),
    };
  }

  /**
   * Règlement public, membres privés (choix de David, 06/11) : avec le lien, un non-membre voit le règlement,
   * le statut et les places restantes ; la liste des membres et l'ordre de passage sont réservés aux membres.
   */
  async consulterPour(id: string, demandeurId: string): Promise<Cercle | CerclePourNonMembre> {
    const { membres, ordre, ...cercle } = await this.trouver(id);
    const placesRestantes = Math.max(0, cercle.reglement.nombreMembres - membres.length);
    if (membres.includes(demandeurId)) return { ...cercle, membres, ...(ordre ? { ordre } : {}), placesRestantes };
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

  /** Place comprise dans le cercle, et pas plus tôt que ce que permet le score du membre (on peut toujours plus tard). */
  private async verifierPlace(membreId: string, place: number, nombreMembres: number): Promise<void> {
    if (place > nombreMembres) throw new BadRequestException(`Place entre 1 et ${nombreMembres}`);
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
      "SELECT membre_id FROM cercles.adhesions WHERE cercle_id = $1 ORDER BY rang",
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
    const ordre: PlaceOrdre[] = membres.every((id) => souhait.get(id))
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
