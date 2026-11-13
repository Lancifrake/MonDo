import { mkdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { genererRapport } from "./rapport.js";
import { SCENARIOS } from "./scenarios.js";

/** `corepack pnpm simulation [dossier]` : écrit le rapport de mesures (docs/mesures par défaut). */
const dossier = resolve(process.argv[2] ?? "../../docs/mesures");
mkdirSync(dossier, { recursive: true });
const rapport = genererRapport(SCENARIOS);
writeFileSync(join(dossier, "resultats.csv"), rapport.csv);
writeFileSync(join(dossier, "rapport.md"), rapport.resume);
for (const [nom, svg] of Object.entries(rapport.figures)) writeFileSync(join(dossier, nom), svg);
process.stdout.write(
  `Rapport écrit dans ${dossier} : resultats.csv, rapport.md et ${Object.keys(rapport.figures).length} figures.\n`,
);
