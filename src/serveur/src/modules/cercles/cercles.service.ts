import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees, type Executeur } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { calculerOrdreDePassage } from "../../score/ordre-de-passage.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { ScoreService } from "../score/score.service.js";

export interface Reglement {
  montant: number;
  frequence: "hebdomadaire" | "mensuelle";
  nombreMembres: number;
  penaliteRetard: number;
  delaiGraceJours: number;
  /** Ouvert à des inconnus : exige l'identité vérifiée (niveau 2). */
  ouvert: boolean;
  /** Jours avant la date limite où l'assistant peut rappeler. Absent : aucun rappel avant l'échéance. */
  rappelsAvantEcheanceJours?: number[];
}

export interface PlaceOrdre {
  position: number;
  zone: string;
  membreId: string;
}

export interface Cercle {
  id: string;
  organisateurId: string;
  reglement: Reglement;
  empreinteReglement: string;
  membres: string[];
  statut: "en_attente" | "complet";
  ordre?: PlaceOrdre[];
}

interface LigneCercle extends Record<string, unknown> {
  id: string;
  organisateur_id: string;
  reglement: Reglement;
  empreinte_reglement: string;
  statut: Cercle["statut"];
  ordre: PlaceOrdre[] | null;
}

export const messageReglement = (organisateurId: string, r: Reglement) =>
  canonique({ objet: "reglement", organisateurId, reglement: r });
export const messageEngagement = (cercleId: string, empreinteReglement: string, membreId: string) =>
  canonique({ objet: "engagement", cercleId, empreinteReglement, membreId });

const UUID = /^[0-9a-f-]{36}$/i;

@Injectable()
export class CerclesService {
  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {}

  async creer(d: { organisateurId: string; reglement: Reglement; signature: string }): Promise<Cercle> {
    const organisateur = await this.comptes.trouver(d.organisateurId);
    const message = messageReglement(d.organisateurId, d.reglement); // forme validée en amont (schemaReglement)
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
      await tx.requete("INSERT INTO cercles.adhesions (cercle_id, membre_id, rang, signature) VALUES ($1, $2, 1, $3)", [
        id,
        d.organisateurId,
        d.signature,
      ]);
    });
    return this.trouver(id);
  }

  async rejoindre(cercleId: string, d: { membreId: string; signature: string }): Promise<Cercle> {
    const cercle = await this.trouver(cercleId);
    const membre = await this.comptes.trouver(d.membreId);
    if (cercle.reglement.ouvert && membre.niveau < 2) {
      throw new ForbiddenException("Identité vérifiée (niveau 2) requise pour un cercle ouvert");
    }
    const message = messageEngagement(cercle.id, cercle.empreinteReglement, d.membreId);
    if (!verifierSignature(membre.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature de l'engagement invalide");
    }

    // Verrou sur la ligne du cercle : deux adhésions simultanées ne dépassent jamais le nombre de places.
    const complet = await this.base.transaction(async (tx) => {
      const [verrou] = await tx.requete<LigneCercle>("SELECT * FROM cercles.cercles WHERE id = $1 FOR UPDATE", [
        cercleId,
      ]);
      if (verrou!.statut === "complet") throw new BadRequestException("Cercle complet");
      const membres = await this.membres(tx, cercleId);
      if (membres.includes(d.membreId)) throw new BadRequestException("Déjà membre");
      membres.push(d.membreId);
      await tx.requete(
        "INSERT INTO cercles.adhesions (cercle_id, membre_id, rang, signature) VALUES ($1, $2, $3, $4)",
        [cercleId, d.membreId, membres.length, d.signature],
      );
      if (membres.length < cercle.reglement.nombreMembres) return undefined;
      await tx.requete("UPDATE cercles.cercles SET statut = 'complet' WHERE id = $1", [cercleId]);
      return membres;
    });

    await this.registre.enregistrer(message);
    if (complet) {
      const ordre = await this.figerOrdre(cercleId, complet);
      await this.registre.enregistrer(canonique({ objet: "ordre", cercleId, ordre }));
      await this.evenements.publier({ type: "cercle_complet", cercleId });
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
    };
  }

  /** Rang et signature d'un membre : rang 1 = organisateur, qui a signé le règlement lui-même. */
  async adhesion(cercleId: string, membreId: string): Promise<{ rang: number; signature: string } | undefined> {
    const [l] = await this.base.requete<{ rang: number; signature: string }>(
      "SELECT rang, signature FROM cercles.adhesions WHERE cercle_id = $1 AND membre_id = $2",
      [cercleId, membreId],
    );
    return l;
  }

  private async membres(ex: Executeur, cercleId: string): Promise<string[]> {
    const lignes = await ex.requete<{ membre_id: string }>(
      "SELECT membre_id FROM cercles.adhesions WHERE cercle_id = $1 ORDER BY rang",
      [cercleId],
    );
    return lignes.map((l) => l.membre_id);
  }

  /**
   * Ordre figé dès que le cercle est complet : zones, score, ordre d'inscription.
   * Calculé hors de la transaction d'adhésion, qui ne doit pas attendre le module Score.
   */
  private async figerOrdre(cercleId: string, membres: string[]): Promise<PlaceOrdre[]> {
    const scores = await Promise.all(membres.map((id) => this.score.consulter(id)));
    const ordre = calculerOrdreDePassage(
      membres.map((id, i) => ({ id, score: scores[i]!.score, rangInscription: i + 1 })),
    ).map((p) => ({ position: p.position, zone: p.zone, membreId: p.membre.id }));
    await this.base.requete("UPDATE cercles.cercles SET ordre = $2 WHERE id = $1", [cercleId, JSON.stringify(ordre)]);
    return ordre;
  }
}
