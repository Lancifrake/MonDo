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
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { RegistreService } from "../../registre/registre.service.js";
import { premierePlaceAutorisee } from "../../score/attribution-des-places.js";
import { canonique } from "../../signature/canonique.js";
import { verifierSignature } from "../../signature/signature.js";
import { FileSms } from "../../sms/file-sms.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { RecuperationService } from "../comptes/recuperation.service.js";
import { CotisationsService } from "../cotisations/cotisations.service.js";
import { ScoreService } from "../score/score.service.js";
import { CerclesService, messageEchange, type Cercle } from "./cercles.service.js";

/** Sans seconde signature, la proposition expire (flow 5, choix de David). */
export const VALIDITE_ECHANGE_MS = 48 * 60 * 60 * 1000;
/** Propositions par demandeur et par cercle sur 24 h : chaque proposition envoie un SMS au membre visé. */
export const PROPOSITIONS_MAX_PAR_JOUR = 3;

export interface EchangePlace {
  id: string;
  cercleId: string;
  demandeurId: string;
  cedantId: string;
  placeDemandeur: number;
  placeCedant: number;
  proposeLe: string;
  expireLe: string;
  statut: "propose" | "signe" | "refuse" | "expire";
}

interface LigneEchange extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  demandeur_id: string;
  cedant_id: string;
  place_demandeur: number;
  place_cedant: number;
  signature_demandeur: string;
  propose_le: Date | string;
  expire_le: Date | string;
  statut: EchangePlace["statut"];
}

const versEchange = (l: LigneEchange): EchangePlace => ({
  id: l.id,
  cercleId: l.cercle_id,
  demandeurId: l.demandeur_id,
  cedantId: l.cedant_id,
  placeDemandeur: l.place_demandeur,
  placeCedant: l.place_cedant,
  proposeLe: new Date(l.propose_le).toISOString(),
  expireLe: new Date(l.expire_le).toISOString(),
  statut: l.statut,
});

const UUID = /^[0-9a-f-]{36}$/i;

/**
 * Échange de places après complétion (choix de David, 11/11) : gratuit au prototype, signé par les deux
 * membres, expiré au bout de 48 h sans seconde signature, jamais vers une place plus tôt que ce que permet le
 * score de celui qui avance, suspendu tant qu'un des deux comptes est en récupération. Jamais dans un cercle à
 * ordre fixé, que tous ont signé. Les deux tours ne doivent pas avoir commencé.
 */
@Injectable()
export class EchangesService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CerclesService) private readonly cercles: CerclesService,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(RecuperationService) private readonly recuperation: RecuperationService,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  async proposer(
    cercleId: string,
    demandeurId: string,
    d: { avecMembreId: string; signature: string },
    maintenant = new Date(),
  ): Promise<EchangePlace> {
    const cercle = await this.cercles.trouver(cercleId);
    if (!cercle.membres.includes(demandeurId)) throw new ForbiddenException("Réservé aux membres du cercle");
    const places = await this.verifier(cercle, demandeurId, d.avecMembreId, maintenant);
    const demandeur = await this.comptes.trouver(demandeurId);
    const message = messageEchange(cercleId, demandeurId, places.demandeur, d.avecMembreId, places.cedant);
    if (!verifierSignature(demandeur.clePublique, message, d.signature)) {
      throw new ForbiddenException("Signature de l'échange invalide");
    }
    await this.expirer(maintenant);
    const [{ n }] = (await this.base.requete<{ n: string | number }>(
      "SELECT count(*) AS n FROM cercles.echanges WHERE cercle_id = $1 AND demandeur_id = $2 AND propose_le > $3",
      [cercleId, demandeurId, new Date(maintenant.getTime() - 24 * 60 * 60 * 1000).toISOString()],
    )) as [{ n: string | number }];
    if (Number(n) >= PROPOSITIONS_MAX_PAR_JOUR) {
      throw new HttpException(
        "Trop de propositions d'échange aujourd'hui dans ce cercle",
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    let ligne: LigneEchange;
    try {
      [ligne] = (await this.base.requete<LigneEchange>(
        `INSERT INTO cercles.echanges
           (id, cercle_id, demandeur_id, cedant_id, place_demandeur, place_cedant, signature_demandeur, propose_le, expire_le, statut)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'propose') RETURNING *`,
        [
          randomUUID(),
          cercleId,
          demandeurId,
          d.avecMembreId,
          places.demandeur,
          places.cedant,
          d.signature,
          maintenant.toISOString(),
          new Date(maintenant.getTime() + VALIDITE_ECHANGE_MS).toISOString(),
        ],
      )) as [LigneEchange];
    } catch (e) {
      if (estDoublon(e))
        throw new ConflictException("Vous avez déjà une proposition d'échange en cours dans ce cercle");
      throw e;
    }
    await this.prevenir(
      ligne.id,
      "proposition",
      d.avecMembreId,
      `MonDo : un membre de votre cercle vous propose d'échanger sa place ${places.demandeur} contre votre place ${places.cedant}. Gratuit. Réponse dans l'application sous 48 h.`,
    );
    return versEchange(ligne);
  }

  /** Mes échanges dans ce cercle, proposés par moi ou à moi, du plus récent au plus ancien. */
  async listerPour(cercleId: string, membreId: string, maintenant = new Date()): Promise<EchangePlace[]> {
    await this.expirer(maintenant);
    const lignes = await this.base.requete<LigneEchange>(
      `SELECT * FROM cercles.echanges WHERE cercle_id = $1 AND (demandeur_id = $2 OR cedant_id = $2)
       ORDER BY propose_le DESC, id`,
      [UUID.test(cercleId) ? cercleId : null, membreId],
    );
    return lignes.map(versEchange);
  }

  async refuser(cercleId: string, id: string, parMembreId: string, maintenant = new Date()): Promise<EchangePlace> {
    const avant = await this.trouver(cercleId, id);
    if (avant.cedant_id !== parMembreId) throw new ForbiddenException("Seul le membre visé répond à la proposition");
    await this.expirer(maintenant);
    const [l] = await this.base.requete<LigneEchange>(
      "UPDATE cercles.echanges SET statut = 'refuse', conclu_le = $2 WHERE id = $1 AND statut = 'propose' RETURNING *",
      [id, maintenant.toISOString()],
    );
    if (!l) throw new BadRequestException("Proposition déjà conclue ou expirée");
    await this.prevenir(
      id,
      "refus",
      l.demandeur_id,
      "MonDo : votre proposition d'échange de place a été refusée. Rien ne change.",
    );
    return versEchange(l);
  }

  /**
   * Seconde signature. Les règles sont revérifiées à cet instant (le score ou les tours ont pu changer). La
   * proposition est d'abord prise (une seule acceptation possible), puis les tours sont échangés en une
   * transaction côté Cotisations ; si celle-ci refuse, la proposition redevient ouverte.
   */
  async accepter(
    cercleId: string,
    id: string,
    parMembreId: string,
    signature: string,
    maintenant = new Date(),
  ): Promise<EchangePlace> {
    const avant = await this.trouver(cercleId, id);
    if (avant.cedant_id !== parMembreId) throw new ForbiddenException("Seul le membre visé répond à la proposition");
    await this.expirer(maintenant);
    const message = messageEchange(
      cercleId,
      avant.demandeur_id,
      avant.place_demandeur,
      avant.cedant_id,
      avant.place_cedant,
    );
    const cedant = await this.comptes.trouver(parMembreId);
    if (!verifierSignature(cedant.clePublique, message, signature)) {
      throw new ForbiddenException("Signature de l'échange invalide");
    }
    for (const compteId of [avant.demandeur_id, avant.cedant_id]) {
      if (await this.recuperation.enRecuperation(compteId)) {
        throw new ConflictException("Échange suspendu : un des deux comptes est en récupération");
      }
    }
    const cercle = await this.cercles.trouver(cercleId);
    const places = await this.verifier(cercle, avant.demandeur_id, avant.cedant_id, maintenant, false);
    if (places.demandeur !== avant.place_demandeur || places.cedant !== avant.place_cedant) {
      throw new BadRequestException("Les places ont changé depuis la proposition : en proposer une nouvelle");
    }
    const [l] = await this.base.requete<LigneEchange>(
      `UPDATE cercles.echanges SET statut = 'signe', signature_cedant = $2, conclu_le = $3
       WHERE id = $1 AND statut = 'propose' RETURNING *`,
      [id, signature, maintenant.toISOString()],
    );
    if (!l) throw new BadRequestException("Proposition déjà conclue ou expirée");
    try {
      await this.cotisations.echangerTours(cercleId, avant.demandeur_id, avant.cedant_id, maintenant);
    } catch (e) {
      await this.base.requete(
        "UPDATE cercles.echanges SET statut = 'propose', signature_cedant = NULL, conclu_le = NULL WHERE id = $1",
        [id],
      );
      throw e;
    }
    await this.cercles.echangerPlaces(cercleId, avant.demandeur_id, avant.cedant_id);
    // Au registre : l'échange et les deux signatures, par leur empreinte.
    await this.registre.enregistrer(
      canonique({ objet: "echange_de_places", echangeId: id, message, signatures: [l.signature_demandeur, signature] }),
      { cercleId },
    );
    await this.prevenir(
      id,
      "acceptation",
      l.demandeur_id,
      `MonDo : échange accepté. Votre place est maintenant la ${avant.place_cedant}. Les tours et les cotisations ont été mis à jour.`,
    );
    return versEchange(l);
  }

  /**
   * Règles communes à la proposition et à l'acceptation. Rend les places actuelles des deux membres.
   * `verifierTours` : contrôle côté Cotisations que les deux tours n'ont pas commencé (fait de toute façon
   * dans la transaction d'échange, donc inutile juste avant elle).
   */
  private async verifier(
    cercle: Cercle,
    demandeurId: string,
    cedantId: string,
    maintenant: Date,
    verifierTours = true,
  ): Promise<{ demandeur: number; cedant: number }> {
    if (cercle.statut !== "complet" || !cercle.ordre) {
      throw new BadRequestException("L'échange de places n'est possible que dans un cercle complet, en cours");
    }
    if (cercle.reglement.ordreFixe) {
      throw new BadRequestException("Pas d'échange dans un cercle à ordre fixé : tous ont signé cet ordre");
    }
    if (demandeurId === cedantId || !cercle.membres.includes(cedantId)) {
      throw new BadRequestException("Choisir un autre membre actuel du cercle");
    }
    const place = (id: string) => cercle.ordre!.find((p) => p.membreId === id)!.position;
    const places = { demandeur: place(demandeurId), cedant: place(cedantId) };
    // Celui qui avance doit y avoir droit par son score ; reculer est toujours permis.
    const [quiAvance, vers] =
      places.demandeur > places.cedant ? [demandeurId, places.cedant] : [cedantId, places.demandeur];
    const { score, premieresPlacesFermees } = await this.score.consulter(quiAvance);
    const plusTot = premierePlaceAutorisee(score, cercle.reglement.nombreMembres, {
      exclusDuDebut: premieresPlacesFermees,
    });
    if (vers < plusTot) {
      throw new BadRequestException(
        `Échange refusé : le score de celui qui avance permet une place à partir de la ${plusTot}e, pas la ${vers}e`,
      );
    }
    if (verifierTours) await this.cotisations.echangerTours(cercle.id, demandeurId, cedantId, maintenant, true);
    return places;
  }

  /** Propositions restées sans seconde signature après 48 h. Paresseux : fait à chaque lecture ou action. */
  private async expirer(maintenant: Date): Promise<void> {
    await this.base.requete(
      "UPDATE cercles.echanges SET statut = 'expire', conclu_le = expire_le WHERE statut = 'propose' AND expire_le <= $1",
      [maintenant.toISOString()],
    );
  }

  private async prevenir(echangeId: string, etape: string, membreId: string, texte: string): Promise<void> {
    const compte = await this.comptes.chercher(membreId);
    if (!compte) return;
    await this.sms.mettreEnFile(`echange:${echangeId}:${etape}`, compte.numero, texte, membreId);
    this.sms.declencher();
  }

  private async trouver(cercleId: string, id: string): Promise<LigneEchange> {
    const [l] =
      UUID.test(id) && UUID.test(cercleId)
        ? await this.base.requete<LigneEchange>("SELECT * FROM cercles.echanges WHERE id = $1 AND cercle_id = $2", [
            id,
            cercleId,
          ])
        : [];
    if (!l) throw new NotFoundException("Proposition d'échange introuvable");
    return l;
  }
}
