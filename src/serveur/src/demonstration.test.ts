import "reflect-metadata";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { AppModule } from "./app.module.js";
import type { MesuresAssistant } from "./assistant/mesures.js";
import type { Cercle } from "./modules/cercles/cercles.service.js";
import { creerClient, type Identite } from "./testing/client.js";
import { cotisationsDe, creerCercle, reglementDeTest } from "./testing/cercles.js";

let app: INestApplication;
let client: Awaited<ReturnType<typeof creerClient>>;

beforeAll(async () => {
  app = (await Test.createTestingModule({ imports: [AppModule] }).compile()).createNestApplication();
  await app.listen(0);
  client = await creerClient(app);
});
afterAll(() => app.close());
afterEach(() => vi.unstubAllEnvs());

const json = async <T>(r: Response) => (await r.json()) as T;

/** Le membre du téléphone crée un cercle de quatre ; les trois autres places sont pour des membres fictifs. */
async function cercleDeDemo() {
  const org = await client.inscrire();
  const cree = await json<Cercle>(await creerCercle(client, org, reglementDeTest({ nombreMembres: 4 })));
  const remplir = (qui?: Identite) =>
    client.requete("POST", `/demonstration/cercles/${cree.id}/membres-fictifs`, undefined, qui);
  const suite = (qui?: Identite) => client.requete("POST", `/demonstration/cercles/${cree.id}/suite`, undefined, qui);
  const avancer = (jours: number, qui?: Identite) =>
    client.requete("POST", `/demonstration/cercles/${cree.id}/avance`, { jours }, qui);
  const lire = () => client.requete("GET", `/cercles/${cree.id}`, undefined, org).then((r) => json<Cercle>(r));
  const score = async () =>
    json<{ score: number; defauts: number }>(await client.requete("GET", `/score/${org.id}`, undefined, org));
  return { org, id: cree.id, remplir, suite, avancer, lire, score };
}

describe("démonstration : membres fictifs et avance du temps (hors production)", () => {
  it("les membres fictifs complètent le cercle, par les vrais services : adhésions signées, ordre figé", async () => {
    const { org, remplir, lire } = await cercleDeDemo();
    const r = await remplir(org);
    expect(r.status).toBe(201);
    expect(await json(r)).toMatchObject({ membresFictifs: 3 });
    const cercle = await lire();
    expect(cercle.statut).toBe("complet");
    expect(cercle.membres).toHaveLength(4);
    // Le membre réel, premier inscrit, garde la dernière place qu'il a signée.
    expect(cercle.ordre!.at(-1)!.membreId).toBe(org.id);
    // Rejouer ne crée personne de plus.
    expect(await json(await remplir(org))).toMatchObject({ membresFictifs: 0 });
  });

  it("la suite : les membres fictifs paient le tour en cours et confirment ce que le membre réel a payé", async () => {
    const { org, id, remplir, suite } = await cercleDeDemo();
    await remplir(org);
    const maDue = (await cotisationsDe(client, id, org)).find((c) => c.tour === 1 && c.payeurId === org.id)!;
    await client.requete("POST", `/cotisations/${maDue.id}/paiement`, { referenceTransaction: "OM-DEMO" }, org);
    const r = await suite(org);
    expect(r.status).toBe(201);
    expect(await json(r)).toMatchObject({ tour: 1, paiementsDeclares: 2, confirmations: 3 });
    const apres = (await cotisationsDe(client, id, org)).find((c) => c.id === maDue.id)!;
    expect(apres.statut).toBe("confirmee");
  });

  it("le membre fictif défaillant ne paie plus à partir du tour 2 ; l'avance du temps fait constater son défaut", async () => {
    const { org, id, remplir, suite, avancer, score } = await cercleDeDemo();
    await remplir(org);
    const payer = async (tour: number) => {
      const c = (await cotisationsDe(client, id, org)).find((x) => x.tour === tour && x.payeurId === org.id)!;
      await client.requete("POST", `/cotisations/${c.id}/paiement`, { referenceTransaction: `OM-${tour}` }, org);
    };
    await payer(1);
    await suite(org);
    await payer(2);
    expect(await json(await suite(org))).toMatchObject({ tour: 2, paiementsDeclares: 1 });
    // 17 jours plus tard : la fin de grâce du tour 2 (jour 16) est passée, celle du tour 3 (jour 23) non.
    // Le défaillant est en défaut ; moi, en retard sur le tour 3, je suis encore dans le délai de grâce.
    const a = await avancer(17, org);
    expect(a.status).toBe(201);
    expect((await json<{ tachesTraitees: number }>(a)).tachesTraitees).toBeGreaterThan(0);
    expect(await score()).toMatchObject({ defauts: 0 });
    const dossiers = await client.requete("GET", "/cercles/" + id, undefined, org).then((x) => json<Cercle>(x));
    const autres = dossiers.membres.filter((m) => m !== org.id);
    const statuts = await Promise.all(
      autres.map((m) =>
        client.requete("GET", `/preuve/cercles/${id}/membres/${m}/dossier`, undefined, org).then((x) => x.status),
      ),
    );
    expect(statuts.filter((s) => s === 200)).toHaveLength(1);
  });

  it("réservé à l'organisateur du cercle, par requête signée ; corps strict", async () => {
    const { org, id, remplir, suite, avancer } = await cercleDeDemo();
    const autre = await client.inscrire();
    for (const appel of [() => remplir(autre), () => suite(autre), () => avancer(7, autre)]) {
      expect((await appel()).status).toBe(403);
    }
    for (const appel of [() => remplir(), () => suite(), () => avancer(7)]) expect((await appel()).status).toBe(401);
    expect((await avancer(0, org)).status).toBe(400);
    expect((await avancer(1000, org)).status).toBe(400);
    expect((await client.requete("POST", `/demonstration/cercles/${id}/avance`, { jours: 7, x: 1 }, org)).status).toBe(
      400,
    );
    // Avant d'être complet, il n'y a rien à jouer.
    expect((await suite(org)).status).toBe(400);
  });

  it("refusé en production : aucun membre fictif, aucune manipulation du temps", async () => {
    const { org, remplir, suite, avancer, lire } = await cercleDeDemo();
    vi.stubEnv("NODE_ENV", "production");
    for (const appel of [() => remplir(org), () => suite(org), () => avancer(7, org)]) {
      const r = await appel();
      expect(r.status).toBe(403);
      expect((await json<{ message: string }>(r)).message).toMatch(/production/);
    }
    vi.unstubAllEnvs();
    expect((await lire()).membres).toHaveLength(1);
  });
});

describe("mesures de l'assistant multi-agents (grille d'évaluation)", () => {
  it("cycles, messages, durée sous 2 secondes, même résultat à chaque lancement, mémoire bornée", async () => {
    const qui = await client.inscrire();
    const r = await client.requete("GET", "/assistant/mesures?lancements=50", undefined, qui);
    expect(r.status).toBe(200);
    const m = await json<MesuresAssistant>(r);
    expect(m.lancements).toBe(50);
    for (const mode of [m.autonome, m.manuel]) {
      expect(mode).toMatchObject({ cycles: 3, messages: 58, identiques: true });
      expect(mode.dureeMaxMs).toBeLessThan(2000);
    }
    expect(m.autonome.actions).toMatchObject({ executee: 12 });
    expect(m.manuel.actions).toMatchObject({ en_attente: 12 });
    expect(m.memoire.lignesDeJournalParLancement).toBeLessThanOrEqual(m.memoire.evenementsDuScenario);
  });

  it("nombre de lancements borné ; requête signée", async () => {
    const qui = await client.inscrire();
    expect(await json(await client.requete("GET", "/assistant/mesures", undefined, qui))).toMatchObject({
      lancements: 100,
    });
    expect((await client.requete("GET", "/assistant/mesures?lancements=100000", undefined, qui)).status).toBe(400);
    expect((await client.requete("GET", "/assistant/mesures?lancements=abc", undefined, qui)).status).toBe(400);
    expect((await client.requete("GET", "/assistant/mesures")).status).toBe(401);
  });
});
