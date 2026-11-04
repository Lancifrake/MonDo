import type { Cotisation } from "../modules/cotisations/cotisations.service.js";
import {
  messageEngagement,
  messageReglement,
  type Cercle,
  type Reglement,
} from "../modules/cercles/cercles.service.js";
import type { creerClient, Identite } from "./client.js";

type Client = Awaited<ReturnType<typeof creerClient>>;

const JOUR_MS = 24 * 60 * 60 * 1000;

export const dansJours = (jours: number, depuis = Date.now()) => new Date(depuis + jours * JOUR_MS).toISOString();

/** Règlement fictif de test : trois membres, hebdomadaire, premier tour dans une semaine. */
export const reglementDeTest = (extra: Partial<Reglement> = {}): Reglement => ({
  montant: 10000,
  frequence: "hebdomadaire",
  nombreMembres: 3,
  penaliteRetard: 500,
  delaiGraceJours: 2,
  ouvert: false,
  datePremierTour: dansJours(7),
  ...extra,
});

export async function creerCercle(client: Client, org: Identite, r: Reglement) {
  return client.requete(
    "POST",
    "/cercles",
    { reglement: r, signature: await org.signer(messageReglement(org.id, r)) },
    org,
  );
}

export async function adherer(client: Client, cercle: Cercle, m: Identite) {
  const signature = await m.signer(messageEngagement(cercle.id, cercle.empreinteReglement, m.id));
  return client.requete("POST", `/cercles/${cercle.id}/adhesions`, { signature }, m);
}

/** Cercle complet : l'organisateur puis les autres membres, dans l'ordre d'inscription. Rend le cercle avec son ordre figé. */
export async function cercleComplet(client: Client, r: Reglement = reglementDeTest()) {
  const membres: Identite[] = [];
  for (let i = 0; i < r.nombreMembres; i++) membres.push(await client.inscrire());
  const [org, ...autres] = membres;
  const cree = (await (await creerCercle(client, org!, r)).json()) as Cercle;
  for (const m of autres) await adherer(client, cree, m);
  const cercle = (await (await client.requete("GET", `/cercles/${cree.id}`, undefined, org)).json()) as Cercle;
  return { membres, org: org!, cercle };
}

/** Cotisations où le membre est payeur ou bénéficiaire, dans ce cercle. */
export async function cotisationsDe(client: Client, cercleId: string, membre: Identite): Promise<Cotisation[]> {
  return (await (
    await client.requete("GET", `/cotisations?cercleId=${cercleId}`, undefined, membre)
  ).json()) as Cotisation[];
}
