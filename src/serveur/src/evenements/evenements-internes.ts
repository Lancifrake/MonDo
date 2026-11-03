import { Injectable } from "@nestjs/common";

/** Événements que les modules s'échangent (décision 02, règle 2). Aucun module n'appelle les tables d'un autre. */
export type EvenementInterne =
  | { type: "cotisation_confirmee"; cercleId: string; membreId: string; aTemps: boolean }
  | { type: "defaut_constate"; cercleId: string; membreId: string }
  | { type: "cycle_termine"; cercleId: string; membreId: string }
  | { type: "cercle_complet"; cercleId: string };

export type TypeEvenementInterne = EvenementInterne["type"];

type Ecouteur = (e: EvenementInterne) => void | Promise<void>;

@Injectable()
export class EvenementsInternes {
  private readonly ecouteurs = new Map<TypeEvenementInterne, Ecouteur[]>();

  ecouter<T extends TypeEvenementInterne>(
    type: T,
    ecouteur: (e: Extract<EvenementInterne, { type: T }>) => void | Promise<void>,
  ): void {
    const liste = this.ecouteurs.get(type) ?? [];
    liste.push(ecouteur as Ecouteur);
    this.ecouteurs.set(type, liste);
  }

  /** Attend chaque écouteur : quand publier() rend la main, les modules abonnés ont tous enregistré l'événement. */
  async publier(e: EvenementInterne): Promise<void> {
    for (const ecouteur of this.ecouteurs.get(e.type) ?? []) await ecouteur(e);
  }
}
