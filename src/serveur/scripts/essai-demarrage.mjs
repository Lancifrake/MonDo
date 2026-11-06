// Essai de démarrage du serveur compilé (dist/) : il démarre, répond sur /sante sans révéler son framework, refuse une requête
// non signée, puis s'arrête proprement sur SIGTERM. Base embarquée, aucune donnée réelle.
import { spawn } from "node:child_process";

const PORT = process.env.PORT ?? "3999";
const base = `http://localhost:${PORT}`;
const ecrire = (m) => process.stdout.write(`${m}\n`);
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

const env = { ...process.env, PORT, MONDO_PLANIFICATEUR_MINUTES: "1" };
delete env.DATABASE_URL;
const serveur = spawn(process.execPath, ["--enable-source-maps", "dist/main.js"], { env, stdio: "inherit" });
const fin = new Promise((r) => serveur.on("exit", (code, signal) => r({ code, signal })));

async function verifier() {
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(`${base}/sante`);
      if (r.ok) break;
    } catch {
      // pas encore prêt
    }
    await attendre(500);
  }
  const sante = await fetch(`${base}/sante`);
  if (sante.status !== 200) throw new Error(`/sante a répondu ${sante.status}`);
  if (sante.headers.has("x-powered-by")) throw new Error("l'en-tête x-powered-by révèle le framework");
  const nonSignee = await fetch(`${base}/cercles/inconnu`);
  if (nonSignee.status !== 401) throw new Error(`requête non signée : ${nonSignee.status} au lieu de 401`);
}

try {
  await verifier();
  serveur.kill("SIGTERM");
  const { code, signal } = await Promise.race([fin, attendre(10_000).then(() => ({ code: "délai dépassé" }))]);
  if (code !== 0 && signal !== "SIGTERM") throw new Error(`arrêt anormal : ${code ?? signal}`);
  ecrire("Essai de démarrage réussi : santé 200 sans x-powered-by, requête non signée 401, arrêt propre.");
} catch (e) {
  serveur.kill("SIGKILL");
  ecrire(`Essai de démarrage en échec : ${e.message}`);
  process.exit(1);
}
