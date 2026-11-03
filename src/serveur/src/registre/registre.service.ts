import { Inject, Injectable } from "@nestjs/common";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../base/base-de-donnees.js";
import { hacher, preuve, racine, type EtapePreuve } from "./merkle.js";

export const CONNECTEUR_REGISTRE = Symbol("CONNECTEUR_REGISTRE");

/** Écrit une racine sur la chaîne. Simulé au prototype ; le contrat Solidity (Base Sepolia) viendra derrière cette interface. */
export interface ConnecteurRegistre {
  inscrireRacine(racine: string): Promise<{ referenceInscription: string }>;
}

export class ConnecteurRegistreSimule implements ConnecteurRegistre {
  readonly racinesInscrites: string[] = [];
  async inscrireRacine(r: string) {
    this.racinesInscrites.push(r);
    return { referenceInscription: `simule-${this.racinesInscrites.length}` };
  }
}

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

  /** Empreinte d'un événement ou d'un document. Retourne l'empreinte enregistrée. */
  async enregistrer(contenu: string): Promise<string> {
    const empreinte = hacher(contenu);
    await this.base.requete("INSERT INTO registre.empreintes (empreinte) VALUES ($1)", [empreinte]);
    return empreinte;
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
