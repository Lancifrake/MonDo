import { messageInscription, messageRequete } from "../authentification/messages.js";
import { nouveauTelephone } from "./telephone.js";

export interface Identite {
  id: string;
  signer: (message: string) => Promise<string>;
}

/** Client HTTP de test qui signe ses requêtes comme le fera l'application mobile. */
export function creerClient(base: string) {
  let compteur = 0;

  async function requete(
    methode: "GET" | "POST",
    chemin: string,
    corps?: unknown,
    identite?: Identite,
    options: { horodatage?: string; signature?: string } = {},
  ): Promise<Response> {
    const headers: Record<string, string> = { "content-type": "application/json" };
    if (identite) {
      const horodatage = options.horodatage ?? new Date().toISOString();
      headers["x-mondo-membre"] = identite.id;
      headers["x-mondo-horodatage"] = horodatage;
      headers["x-mondo-signature"] =
        options.signature ?? (await identite.signer(messageRequete(methode, chemin, horodatage, corps)));
    }
    return fetch(base + chemin, {
      method: methode,
      headers,
      body: corps === undefined ? undefined : JSON.stringify(corps),
    });
  }

  async function inscrire(): Promise<Identite & { niveau2: () => Promise<Response> }> {
    const tel = await nouveauTelephone();
    const n = ++compteur;
    const donnees = {
      numero: `+2376${String(Date.now()).slice(-4)}${String(n).padStart(4, "0")}`,
      nom: `Membre ${n}`,
      clePublique: tel.clePublique,
    };
    const r = await requete("POST", "/comptes", { ...donnees, preuve: await tel.signer(messageInscription(donnees)) });
    if (r.status !== 201) throw new Error(`Inscription refusée : ${r.status} ${await r.text()}`);
    const { id } = (await r.json()) as { id: string };
    const identite = { id, signer: tel.signer };
    return { ...identite, niveau2: () => requete("POST", `/comptes/${id}/niveau2`, undefined, identite) };
  }

  return { requete, inscrire };
}
