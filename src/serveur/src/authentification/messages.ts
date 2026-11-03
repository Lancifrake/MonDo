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
