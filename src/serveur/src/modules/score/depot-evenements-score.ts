import type { EvenementScore } from "../../score/evenements.js";

export const DEPOT_EVENEMENTS_SCORE = Symbol("DEPOT_EVENEMENTS_SCORE");

/** Interface d'accès aux tables du module Score. L'implémentation PostgreSQL remplacera la mémoire. */
export interface DepotEvenementsScore {
  ajouter(membreId: string, evenement: EvenementScore): void;
  lister(membreId: string): readonly EvenementScore[];
}

export class DepotEvenementsScoreMemoire implements DepotEvenementsScore {
  private readonly parMembre = new Map<string, EvenementScore[]>();
  ajouter(membreId: string, evenement: EvenementScore): void {
    const liste = this.parMembre.get(membreId) ?? [];
    liste.push(evenement);
    this.parMembre.set(membreId, liste);
  }
  lister(membreId: string): readonly EvenementScore[] {
    return this.parMembre.get(membreId) ?? [];
  }
}
