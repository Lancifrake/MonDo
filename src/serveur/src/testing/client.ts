import type { INestApplication } from "@nestjs/common";
import { messageInscription, messageRequete } from "../authentification/messages.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "../sms/connecteur-sms.js";
import { nouveauTelephone } from "./telephone.js";

export interface Identite {
  id: string;
  signer: (message: string) => Promise<string>;
}

let numeroSuivant = 0;

/** Client HTTP de test qui signe ses requêtes comme le fera l'application mobile. */
export async function creerClient(app: INestApplication) {
  const base = await app.getUrl();
  const sms = app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS);

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

  /** Demande un code SMS et le lit dans le connecteur simulé, comme le ferait le membre sur son téléphone. */
  async function codeOtp(numero: string): Promise<string> {
    const r = await requete("POST", "/comptes/otp", { numero });
    if (r.status !== 201) throw new Error(`Code SMS refusé : ${r.status} ${await r.text()}`);
    const message = [...sms.messages].reverse().find((m) => m.numero === numero);
    return /(\d{6})/.exec(message?.texte ?? "")![1]!;
  }

  async function inscrire(): Promise<Identite & { niveau2: () => Promise<Response> }> {
    const tel = await nouveauTelephone();
    const n = ++numeroSuivant;
    const donnees = {
      numero: `+2376${String(process.pid % 10000).padStart(4, "0")}${String(n).padStart(4, "0")}`,
      nom: `Membre ${n}`,
      clePublique: tel.clePublique,
    };
    const r = await requete("POST", "/comptes", {
      ...donnees,
      preuve: await tel.signer(messageInscription(donnees)),
      codeOtp: await codeOtp(donnees.numero),
    });
    if (r.status !== 201) throw new Error(`Inscription refusée : ${r.status} ${await r.text()}`);
    const { id } = (await r.json()) as { id: string };
    const identite = { id, signer: tel.signer };
    return { ...identite, niveau2: () => requete("POST", `/comptes/${id}/niveau2`, undefined, identite) };
  }

  return { requete, inscrire, codeOtp };
}
