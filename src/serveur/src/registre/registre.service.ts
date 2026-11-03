import { Injectable } from "@nestjs/common";
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
 */
@Injectable()
export class RegistreService {
  private enAttente: string[] = [];
  private readonly lots: LotFerme[] = [];

  constructor(private readonly connecteur: ConnecteurRegistre) {}

  /** Empreinte d'un événement ou d'un document. Retourne l'empreinte inscrite. */
  enregistrer(contenu: string): string {
    const empreinte = hacher(contenu);
    this.enAttente.push(empreinte);
    return empreinte;
  }

  async fermerLot(): Promise<LotFerme | undefined> {
    if (this.enAttente.length === 0) return undefined;
    const empreintes = this.enAttente;
    this.enAttente = [];
    const r = racine(empreintes);
    const { referenceInscription } = await this.connecteur.inscrireRacine(r);
    const lot = { racine: r, referenceInscription, empreintes };
    this.lots.push(lot);
    return lot;
  }

  /** Preuve qu'une empreinte fait partie d'un lot inscrit, vérifiable sans MonDo. */
  preuvePour(empreinte: string): { racine: string; etapes: EtapePreuve[] } | undefined {
    for (const lot of this.lots) {
      const index = lot.empreintes.indexOf(empreinte);
      if (index >= 0) return { racine: lot.racine, etapes: preuve(lot.empreintes, index) };
    }
    return undefined;
  }
}
