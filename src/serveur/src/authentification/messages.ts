import { canonique } from "../signature/canonique.js";

/** Corps vide et absence de corps se signent pareil, quel que soit le client HTTP. */
export const normaliserCorps = (corps: unknown): unknown =>
  corps && typeof corps === "object" && Object.keys(corps).length > 0 ? corps : null;

/** Ce que le téléphone signe pour chaque requête authentifiée. */
export const messageRequete = (methode: string, chemin: string, horodatage: string, corps: unknown): string =>
  canonique({ methode: methode.toUpperCase(), chemin, horodatage, corps: normaliserCorps(corps) });

/** À l'inscription, le téléphone prouve qu'il détient la clé privée de la clé publique envoyée. */
export const messageInscription = (d: { numero: string; nom: string; clePublique: JsonWebKey }): string =>
  canonique({ objet: "inscription", numero: d.numero, nom: d.nom, clePublique: d.clePublique });

/** Récupération : le nouveau téléphone prouve qu'il détient la clé privée de la nouvelle clé publique. */
export const messageRecuperation = (d: { numero: string; clePublique: JsonWebKey }): string =>
  canonique({ objet: "recuperation", numero: d.numero, clePublique: d.clePublique });

/** Dépôt des pièces d'une récupération sans contact : signé par la nouvelle clé, valable 5 minutes. */
export const messagePiecesRecuperation = (recuperationId: string, horodatage: string): string =>
  canonique({ objet: "pieces_recuperation", recuperationId, horodatage });
