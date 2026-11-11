import { Inject, Injectable } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";

export type MotifBlocage = "essais_rates" | "opposition";

/** Durée du blocage après trop de codes secrets faux (valeur de sécurité, choix prudent). */
export const DUREE_BLOCAGE_ESSAIS_MS = 24 * 60 * 60 * 1000;

/**
 * Compte bloqué (règle validée par David le 03/11) : seulement (1) un temps, après trop d'essais ratés, levé
 * par le temps ; (2) quand le titulaire s'oppose à une récupération, levé par l'Administrateur. Tant qu'il est
 * bloqué, le membre ne peut plus agir : ses dates limites et son délai de grâce sont suspendus, et les autres
 * membres de ses cercles sont prévenus. Les autres modules l'apprennent par les événements `compte_bloque` et
 * `compte_debloque`.
 */
@Injectable()
export class BlocagesService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
  ) {}

  /** Sans effet si le compte est déjà bloqué : un seul blocage en cours par compte. */
  async bloquer(compteId: string, motif: MotifBlocage, maintenant = new Date()): Promise<void> {
    const finLe = motif === "essais_rates" ? new Date(maintenant.getTime() + DUREE_BLOCAGE_ESSAIS_MS) : null;
    const cree = await this.base.requete(
      `INSERT INTO comptes.blocages (id, compte_id, motif, bloque_le, fin_le) VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (compte_id) WHERE leve_le IS NULL DO NOTHING RETURNING id`,
      [randomUUID(), compteId, motif, maintenant.toISOString(), finLe?.toISOString() ?? null],
    );
    if (cree.length === 0) return;
    await this.evenements.publier({ type: "compte_bloque", membreId: compteId, bloqueLe: maintenant.toISOString() });
  }

  /** Lève le blocage en cours, s'il y en a un, et prévient les autres modules une seule fois. */
  async lever(compteId: string, maintenant = new Date()): Promise<void> {
    const [l] = await this.base.requete<{ bloque_le: Date | string }>(
      "UPDATE comptes.blocages SET leve_le = $2 WHERE compte_id = $1 AND leve_le IS NULL RETURNING bloque_le",
      [compteId, maintenant.toISOString()],
    );
    if (!l) return;
    await this.evenements.publier({
      type: "compte_debloque",
      membreId: compteId,
      bloqueLe: new Date(l.bloque_le).toISOString(),
      debloqueLe: maintenant.toISOString(),
    });
  }

  /** Blocages temporaires arrivés à leur terme : levés à la date prévue. Rejouable. */
  async leverEchus(maintenant = new Date()): Promise<number> {
    const echus = await this.base.requete<{ compte_id: string; fin_le: Date | string }>(
      "SELECT compte_id, fin_le FROM comptes.blocages WHERE leve_le IS NULL AND fin_le IS NOT NULL AND fin_le <= $1",
      [maintenant.toISOString()],
    );
    for (const b of echus) await this.lever(b.compte_id, new Date(b.fin_le));
    return echus.length;
  }

  /** Un blocage temporaire dont le terme est passé ne bloque plus, même avant le passage du planificateur. */
  async estBloque(compteId: string, maintenant = new Date()): Promise<boolean> {
    const lignes = await this.base.requete(
      "SELECT 1 FROM comptes.blocages WHERE compte_id = $1 AND leve_le IS NULL AND (fin_le IS NULL OR fin_le > $2)",
      [compteId, maintenant.toISOString()],
    );
    return lignes.length > 0;
  }

  /** Comptes dont le blocage n'est pas encore levé, pour le planificateur (après `leverEchus`). */
  async comptesBloques(): Promise<Set<string>> {
    const lignes = await this.base.requete<{ compte_id: string }>(
      "SELECT compte_id FROM comptes.blocages WHERE leve_le IS NULL",
    );
    return new Set(lignes.map((l) => l.compte_id));
  }
}
