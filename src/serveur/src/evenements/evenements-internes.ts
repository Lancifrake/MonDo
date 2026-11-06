import { Injectable } from "@nestjs/common";
import type { Frequence } from "../modules/cotisations/calendrier.js";

/** Ce que le module Cotisations doit savoir pour planifier les tours, copié du règlement signé et de l'ordre figé. */
export interface CercleComplet {
  cercleId: string;
  /** Identifiants des membres dans l'ordre de passage. */
  ordre: string[];
  montant: number;
  frequence: Frequence;
  periodeJours?: number;
  delaiGraceJours: number;
  datePremierTour: string;
  completLe: string;
}

/** Événements que les modules s'échangent (décision 02, règle 2). Aucun module n'appelle les tables d'un autre. */
export type EvenementInterne =
  | { type: "cotisation_confirmee"; cercleId: string; membreId: string; cotisationId: string; aTemps: boolean }
  | { type: "confirmation_manquante"; cercleId: string; membreId: string; cotisationId: string }
  | { type: "cercle_termine"; cercleId: string; termineLe: string }
  | { type: "defaut_constate"; cercleId: string; membreId: string; tour: number; constateLe: string }
  | { type: "cycle_termine"; cercleId: string; membreId: string }
  | { type: "adhesion_enregistree"; cercleId: string; membreId: string }
  | ({ type: "cercle_complet" } & CercleComplet)
  | { type: "echeance_proche"; cercleId: string; membreId: string; cotisationId: string; joursRestants: number }
  | { type: "echeance_depassee"; cercleId: string; membreId: string; cotisationId: string; joursDeRetard: number };

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
