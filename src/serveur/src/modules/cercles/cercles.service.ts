import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { calculerOrdreDePassage, type PlaceAttribuee } from "../../score/ordre-de-passage.js";
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
}

export interface Cercle {
  id: string;
  organisateurId: string;
  reglement: Reglement;
  empreinteReglement: string;
  membres: string[];
  statut: "en_attente" | "complet";
  ordre?: { position: number; zone: string; membreId: string }[];
}

export const messageReglement = (organisateurId: string, r: Reglement) =>
  canonique({ objet: "reglement", organisateurId, reglement: r });
export const messageEngagement = (cercleId: string, empreinteReglement: string, membreId: string) =>
  canonique({ objet: "engagement", cercleId, empreinteReglement, membreId });

@Injectable()
export class CerclesService {
  private readonly cercles = new Map<string, Cercle>();

  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
  ) {}

  creer(d: { organisateurId: string; reglement: Reglement; signature: string }): Cercle {
    const r = d.reglement; // forme validée en amont (schemaReglement)
    const organisateur = this.comptes.trouver(d.organisateurId);
    const message = messageReglement(d.organisateurId, r);
    if (!verifierSignature(organisateur.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature du règlement invalide");
    }
    const cercle: Cercle = {
      id: randomUUID(),
      organisateurId: d.organisateurId,
      reglement: r,
      empreinteReglement: this.registre.enregistrer(message),
      membres: [d.organisateurId],
      statut: "en_attente",
    };
    this.cercles.set(cercle.id, cercle);
    return cercle;
  }

  rejoindre(cercleId: string, d: { membreId: string; signature: string }): Cercle {
    const cercle = this.trouver(cercleId);
    if (cercle.statut === "complet") throw new BadRequestException("Cercle complet");
    if (cercle.membres.includes(d.membreId)) throw new BadRequestException("Déjà membre");
    const membre = this.comptes.trouver(d.membreId);
    if (cercle.reglement.ouvert && membre.niveau < 2) {
      throw new ForbiddenException("Identité vérifiée (niveau 2) requise pour un cercle ouvert");
    }
    const message = messageEngagement(cercle.id, cercle.empreinteReglement, d.membreId);
    if (!verifierSignature(membre.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature de l'engagement invalide");
    }
    this.registre.enregistrer(message);
    cercle.membres.push(d.membreId);
    if (cercle.membres.length === cercle.reglement.nombreMembres) this.completer(cercle);
    return cercle;
  }

  trouver(id: string): Cercle {
    const c = this.cercles.get(id);
    if (!c) throw new NotFoundException("Cercle introuvable");
    return c;
  }

  /** Ordre figé au moment où le cercle est complet, puis empreinte inscrite au registre. */
  private completer(cercle: Cercle): void {
    const places: PlaceAttribuee[] = calculerOrdreDePassage(
      cercle.membres.map((id, i) => ({ id, score: this.score.consulter(id).score, rangInscription: i + 1 })),
    );
    cercle.ordre = places.map((p) => ({ position: p.position, zone: p.zone, membreId: p.membre.id }));
    cercle.statut = "complet";
    this.registre.enregistrer(canonique({ objet: "ordre", cercleId: cercle.id, ordre: cercle.ordre }));
    this.evenements.publier({ type: "cercle_complet", cercleId: cercle.id });
  }
}
