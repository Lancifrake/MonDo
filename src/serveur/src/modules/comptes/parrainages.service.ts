import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, estDoublon, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { FileSms } from "../../sms/file-sms.js";
import { ScoreService } from "../score/score.service.js";
import { ComptesService } from "./comptes.service.js";

// Choix prudents (13/11), à valider : le cahier des charges dit seulement « parrainage par un membre fiable ».
/** Score minimum pour parrainer : le seuil du milieu de l'ordre de passage. */
export const SCORE_MINIMUM_PARRAIN = 30;
/** Filleuls proposés ou acceptés par parrain. */
export const FILLEULS_MAX = 3;

export interface Parrainage {
  id: string;
  parrainId: string;
  filleulId: string;
  statut: "propose" | "accepte" | "refuse";
  proposeLe: string;
  reponduLe?: string;
}

interface LigneParrainage extends Record<string, unknown> {
  id: string;
  parrain_id: string;
  filleul_id: string;
  statut: Parrainage["statut"];
  propose_le: Date | string;
  repondu_le: Date | string | null;
}

const versParrainage = (l: LigneParrainage): Parrainage => ({
  id: l.id,
  parrainId: l.parrain_id,
  filleulId: l.filleul_id,
  statut: l.statut,
  proposeLe: new Date(l.propose_le).toISOString(),
  ...(l.repondu_le ? { reponduLe: new Date(l.repondu_le).toISOString() } : {}),
});

/**
 * Parrainage (cahier des charges, US6). Un membre fiable propose de parrainer un proche, qui accepte lui-même.
 * Le parrainage n'est jamais une caution (loi 2010/021, article 13) : le parrain ne doit rien et ne perd rien si
 * son filleul fait défaut. Il gagne 2 points quand son filleul termine un cycle sans défaut. Dans un cercle dont
 * le règlement signé accepte le parrainage, un filleul entre sous le seuil de score si son parrain en est membre.
 */
@Injectable()
export class ParrainagesService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(ScoreService) private readonly score: ScoreService,
    @Inject(FileSms) private readonly sms: FileSms,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
  ) {
    // Le cycle terminé arrive une seule fois par membre et par cercle : le bonus ne se rejoue pas.
    evenements.ecouter("cycle_termine", async (e) => {
      const parrainId = await this.parrainDe(e.membreId);
      if (parrainId) {
        await this.evenements.publier({
          type: "parrainage_reussi",
          parrainId,
          filleulId: e.membreId,
          cercleId: e.cercleId,
        });
      }
    });
  }

  async proposer(parrainId: string, filleulId: string, maintenant = new Date()): Promise<Parrainage> {
    if (parrainId === filleulId) throw new BadRequestException("On ne se parraine pas soi-même");
    await this.comptes.trouver(filleulId);
    const { score, premieresPlacesFermees } = await this.score.consulter(parrainId);
    if (score < SCORE_MINIMUM_PARRAIN || premieresPlacesFermees) {
      throw new ForbiddenException(
        `Pour parrainer, il faut un score d'au moins ${SCORE_MINIMUM_PARRAIN} et aucun défaut récent`,
      );
    }
    // Plafond et écriture en une instruction : deux propositions simultanées ne le dépassent pas.
    let ligne: LigneParrainage | undefined;
    try {
      [ligne] = await this.base.requete<LigneParrainage>(
        `INSERT INTO comptes.parrainages (id, parrain_id, filleul_id, statut, propose_le)
         SELECT $1, $2, $3, 'propose', $4
         WHERE (SELECT count(*) FROM comptes.parrainages WHERE parrain_id = $2 AND statut IN ('propose', 'accepte')) < $5
         RETURNING *`,
        [randomUUID(), parrainId, filleulId, maintenant.toISOString(), FILLEULS_MAX],
      );
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Ce parrainage est déjà proposé");
      throw e;
    }
    if (!ligne) throw new ConflictException(`Un parrain a au plus ${FILLEULS_MAX} filleuls`);
    const [parrain, filleul] = [await this.comptes.trouver(parrainId), await this.comptes.trouver(filleulId)];
    await this.sms.mettreEnFile(
      `parrainage:${ligne.id}:proposition`,
      filleul.numero,
      `MonDo : ${parrain.nom} propose de vous parrainer. Ce n'est pas une caution : personne ne paie pour l'autre. ` +
        "Répondez dans l'application.",
      filleulId,
    );
    this.sms.declencher();
    return versParrainage(ligne);
  }

  async repondre(id: string, filleulId: string, reponse: "accepte" | "refuse", maintenant = new Date()) {
    const avant = await this.trouver(id);
    if (avant.filleul_id !== filleulId) throw new ForbiddenException("Seul le filleul répond à ce parrainage");
    try {
      const [l] = await this.base.requete<LigneParrainage>(
        "UPDATE comptes.parrainages SET statut = $2, repondu_le = $3 WHERE id = $1 AND statut = 'propose' RETURNING *",
        [id, reponse, maintenant.toISOString()],
      );
      if (!l) throw new BadRequestException("Ce parrainage a déjà reçu une réponse");
      return versParrainage(l);
    } catch (e) {
      if (estDoublon(e)) throw new ConflictException("Vous avez déjà un parrain");
      throw e;
    }
  }

  async lesMiens(membreId: string) {
    const lignes = await this.base.requete<LigneParrainage>(
      "SELECT * FROM comptes.parrainages WHERE parrain_id = $1 OR filleul_id = $1 ORDER BY propose_le DESC, id",
      [membreId],
    );
    const tous = lignes.map(versParrainage);
    return {
      commeParrain: tous.filter((p) => p.parrainId === membreId),
      commeFilleul: tous.filter((p) => p.filleulId === membreId),
    };
  }

  /** Parrain accepté du membre, s'il en a un. */
  async parrainDe(filleulId: string): Promise<string | undefined> {
    const [l] = await this.base.requete<{ parrain_id: string }>(
      "SELECT parrain_id FROM comptes.parrainages WHERE filleul_id = $1 AND statut = 'accepte'",
      [filleulId],
    );
    return l?.parrain_id;
  }

  private async trouver(id: string): Promise<LigneParrainage> {
    const [l] = /^[0-9a-f-]{36}$/i.test(id)
      ? await this.base.requete<LigneParrainage>("SELECT * FROM comptes.parrainages WHERE id = $1", [id])
      : [];
    if (!l) throw new NotFoundException("Parrainage introuvable");
    return l;
  }
}
