import { Inject, Injectable } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../base/base-de-donnees.js";
import type { ConnecteurRegistre } from "./connecteur.js";
import { hacher, preuve, racine, type EtapePreuve } from "./merkle.js";

export const CONNECTEUR_REGISTRE = Symbol("CONNECTEUR_REGISTRE");

export type { ConnecteurRegistre };

export class ConnecteurRegistreSimule implements ConnecteurRegistre {
  readonly racinesInscrites: string[] = [];
  async inscrireRacine(r: string) {
    this.racinesInscrites.push(r);
    return { referenceInscription: `simule-${this.racinesInscrites.length}` };
  }
  async estInscrite(r: string) {
    return this.racinesInscrites.includes(r);
  }
}

/** Contexte non personnel d'une empreinte, pour retrouver les événements d'un cercle. */
export interface ContexteEmpreinte {
  cercleId?: string;
  objet?: string;
}

export type StatutEvenement = "en_attente" | "non_inscrite" | "inscrite" | "alteree";

export interface EvenementDuRegistre {
  id: number;
  objet: string;
  empreinte: string;
  enregistreLe: string;
  /** en_attente : pas encore dans un lot ; non_inscrite : lot figé, pas encore sur la chaîne ; alteree : le lot ne
   * correspond plus à sa racine, ou sa racine n'est pas celle de la chaîne. */
  statut: StatutEvenement;
  lot?: {
    id: number;
    racine: string;
    referenceInscription: string | null;
    intact: boolean;
    inscritSurLaChaine: boolean;
  };
  /** Preuve d'inclusion, vérifiable sans MonDo avec la racine et le contrat. */
  preuve?: { racine: string; etapes: EtapePreuve[] };
}

export interface RegistreDuCercle {
  cercleId: string;
  evenements: EvenementDuRegistre[];
  /** Les documents du cercle tels qu'ils sont en base correspondent-ils encore aux empreintes inscrites ? */
  documents: { objet: string; conforme: boolean }[];
  integre: boolean;
}

/** Objet et cercle lus dans un contenu JSON canonique, quand il en a. Jamais de donnée personnelle. */
function contexteDe(contenu: string): ContexteEmpreinte {
  try {
    const v = JSON.parse(contenu) as { objet?: unknown; cercleId?: unknown };
    return {
      ...(typeof v.objet === "string" ? { objet: v.objet } : {}),
      ...(typeof v.cercleId === "string" ? { cercleId: v.cercleId } : {}),
    };
  } catch {
    return {};
  }
}

const UUID = /^[0-9a-f-]{36}$/i;

export interface LotFerme {
  racine: string;
  referenceInscription: string;
  empreintes: readonly string[];
}

/**
 * Le registre ne reçoit que des empreintes : jamais de donnée personnelle.
 * Les empreintes s'accumulent, puis une racine par lot part sur la chaîne.
 * Un lot est d'abord figé en base, puis inscrit : si la chaîne est en panne, il attend la reprise.
 */
@Injectable()
export class RegistreService {
  constructor(
    @Inject(CONNECTEUR_REGISTRE) private readonly connecteur: ConnecteurRegistre,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
  ) {}

  /**
   * Empreinte d'un événement ou d'un document. Retourne l'empreinte enregistrée. Le contenu n'est jamais gardé :
   * seulement son empreinte, son type et l'identifiant du cercle concerné (lus dans le contenu ou fournis).
   */
  async enregistrer(contenu: string, contexte: ContexteEmpreinte = {}): Promise<string> {
    const empreinte = hacher(contenu);
    const { objet, cercleId } = { ...contexteDe(contenu), ...contexte };
    await this.base.requete("INSERT INTO registre.empreintes (empreinte, objet, cercle_id) VALUES ($1, $2, $3)", [
      empreinte,
      objet ?? null,
      cercleId && UUID.test(cercleId) ? cercleId : null,
    ]);
    return empreinte;
  }

  /** L'empreinte de ce contenu figure-t-elle parmi celles du cercle ? */
  async contientPour(cercleId: string, contenu: string): Promise<boolean> {
    const lignes = await this.base.requete(
      "SELECT 1 FROM registre.empreintes WHERE cercle_id = $1 AND empreinte = $2 LIMIT 1",
      [cercleId, hacher(contenu)],
    );
    return lignes.length > 0;
  }

  /**
   * Événements d'un cercle et vérification de chaque lot : la racine recalculée à partir des empreintes en base
   * doit être celle du lot, et cette racine doit être inscrite sur la chaîne. Une empreinte ou une racine
   * retouchée à la main est ainsi détectée (cahier des charges, scénario S8).
   */
  async consulterCercle(cercleId: string): Promise<EvenementDuRegistre[]> {
    const lignes = await this.base.requete<{
      id: string | number;
      empreinte: string;
      objet: string | null;
      lot_id: number | null;
      enregistree_le: Date | string;
    }>(
      "SELECT id, empreinte, objet, lot_id, enregistree_le FROM registre.empreintes WHERE cercle_id = $1 ORDER BY id",
      [cercleId],
    );
    const lots = new Map<number, Awaited<ReturnType<RegistreService["verifierLot"]>>>();
    for (const id of new Set(lignes.flatMap((l) => (l.lot_id === null ? [] : [l.lot_id])))) {
      lots.set(id, await this.verifierLot(id));
    }
    return lignes.map((l) => {
      const base = {
        id: Number(l.id),
        objet: l.objet ?? "evenement",
        empreinte: l.empreinte,
        enregistreLe: new Date(l.enregistree_le).toISOString(),
      };
      const lot = l.lot_id === null ? undefined : lots.get(l.lot_id)!;
      if (!lot) return { ...base, statut: "en_attente" as const };
      const statut: StatutEvenement =
        !lot.intact || (lot.referenceInscription && !lot.inscritSurLaChaine)
          ? "alteree"
          : lot.referenceInscription
            ? "inscrite"
            : "non_inscrite";
      const index = lot.feuilles.indexOf(l.empreinte);
      return {
        ...base,
        statut,
        lot: {
          id: lot.id,
          racine: lot.racine,
          referenceInscription: lot.referenceInscription,
          intact: lot.intact,
          inscritSurLaChaine: lot.inscritSurLaChaine,
        },
        ...(index >= 0 && lot.intact ? { preuve: { racine: lot.racine, etapes: preuve(lot.feuilles, index) } } : {}),
      };
    });
  }

  private async verifierLot(id: number) {
    const [l] = await this.base.requete<{ racine: string; reference_inscription: string | null }>(
      "SELECT racine, reference_inscription FROM registre.lots WHERE id = $1",
      [id],
    );
    const feuilles = (
      await this.base.requete<{ empreinte: string }>(
        "SELECT empreinte FROM registre.empreintes WHERE lot_id = $1 ORDER BY id",
        [id],
      )
    ).map((x) => x.empreinte);
    const intact = feuilles.length > 0 && racine(feuilles) === l!.racine;
    const inscritSurLaChaine =
      l!.reference_inscription !== null && this.connecteur.estInscrite
        ? await this.connecteur.estInscrite(l!.racine)
        : l!.reference_inscription !== null;
    return {
      id,
      racine: l!.racine,
      referenceInscription: l!.reference_inscription,
      feuilles,
      intact,
      inscritSurLaChaine,
    };
  }

  async fermerLot(): Promise<LotFerme | undefined> {
    const lot = await this.base.transaction(async (tx) => {
      const lignes = await tx.requete<{ id: string; empreinte: string }>(
        "SELECT id, empreinte FROM registre.empreintes WHERE lot_id IS NULL ORDER BY id FOR UPDATE",
      );
      if (lignes.length === 0) return undefined;
      const empreintes = lignes.map((l) => l.empreinte);
      const r = racine(empreintes);
      const [{ id }] = (await tx.requete<{ id: number }>(
        "INSERT INTO registre.lots (racine) VALUES ($1) RETURNING id",
        [r],
      )) as [{ id: number }];
      await tx.requete("UPDATE registre.empreintes SET lot_id = $1 WHERE id = ANY($2::bigint[])", [
        id,
        lignes.map((l) => l.id),
      ]);
      return { id, racine: r, empreintes };
    });
    if (!lot) return undefined;
    const referenceInscription = await this.inscrire(lot.id, lot.racine);
    return { racine: lot.racine, referenceInscription, empreintes: lot.empreintes };
  }

  /** Inscrit les lots figés dont l'inscription a échoué. Retourne le nombre de lots inscrits. */
  async reprendreInscriptions(): Promise<number> {
    const enAttente = await this.base.requete<{ id: number; racine: string }>(
      "SELECT id, racine FROM registre.lots WHERE reference_inscription IS NULL ORDER BY id",
    );
    for (const lot of enAttente) await this.inscrire(lot.id, lot.racine);
    return enAttente.length;
  }

  /** Preuve qu'une empreinte fait partie d'un lot inscrit, vérifiable sans MonDo. */
  async preuvePour(empreinte: string): Promise<{ racine: string; etapes: EtapePreuve[] } | undefined> {
    const [cible] = await this.base.requete<{ id: string; lot_id: number; racine: string }>(
      `SELECT e.id, e.lot_id, l.racine FROM registre.empreintes e JOIN registre.lots l ON l.id = e.lot_id
       WHERE e.empreinte = $1 AND l.reference_inscription IS NOT NULL ORDER BY e.id LIMIT 1`,
      [empreinte],
    );
    if (!cible) return undefined;
    const lot = await this.base.requete<{ id: string; empreinte: string }>(
      "SELECT id, empreinte FROM registre.empreintes WHERE lot_id = $1 ORDER BY id",
      [cible.lot_id],
    );
    const index = lot.findIndex((l) => String(l.id) === String(cible.id));
    return {
      racine: cible.racine,
      etapes: preuve(
        lot.map((l) => l.empreinte),
        index,
      ),
    };
  }

  private async inscrire(lotId: number, r: string): Promise<string> {
    const { referenceInscription } = await this.connecteur.inscrireRacine(r);
    await this.base.requete("UPDATE registre.lots SET reference_inscription = $2 WHERE id = $1", [
      lotId,
      referenceInscription,
    ]);
    return referenceInscription;
  }
}
