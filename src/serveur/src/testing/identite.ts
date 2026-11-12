import type { INestApplication } from "@nestjs/common";
import { VERSION_CONSENTEMENT } from "../modules/comptes/identite.service.js";
import { CONNECTEUR_SMS, type ConnecteurSmsSimule } from "../sms/connecteur-sms.js";
import { FileSms } from "../sms/file-sms.js";
import type { creerClient, Identite } from "./client.js";

type Client = Awaited<ReturnType<typeof creerClient>>;

let suivant = 0;

/** Image fictive : l'en-tête d'un JPEG suivi d'octets quelconques. Jamais une vraie pièce. */
export const imageFictive = (taille = 64, marque = 0) =>
  Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(taille, marque)]);

/** Désigne un contact fictif et enregistre son accord, comme le ferait le membre avec le code reçu par son contact. */
export async function avecContactConsentant(app: INestApplication, client: Client, membre: Identite): Promise<string> {
  const numero = `+2378${String(process.pid % 10000).padStart(4, "0")}${String(++suivant).padStart(4, "0")}`;
  await client.requete("POST", "/comptes/moi/contact-de-confiance", { nom: "Contact Fictif", numero }, membre);
  await app.get(FileSms).vider();
  const sms = [...app.get<ConnecteurSmsSimule>(CONNECTEUR_SMS).messages].reverse().find((m) => m.numero === numero);
  const code = /(\d{6})/.exec(sms!.texte)![1]!;
  const r = await client.requete("POST", "/comptes/moi/contact-de-confiance/accord", { code }, membre);
  if (r.status !== 201) throw new Error(`Accord du contact refusé : ${r.status}`);
  return numero;
}

export const dossierIdentite = (extra: Record<string, unknown> = {}) => ({
  typePiece: "cni",
  consentement: true,
  versionConsentement: VERSION_CONSENTEMENT,
  recto: imageFictive(64, 1).toString("base64"),
  verso: imageFictive(64, 2).toString("base64"),
  selfie: imageFictive(64, 3).toString("base64"),
  ...extra,
});
