import type { NestExpressApplication } from "@nestjs/platform-express";
import type { IncomingMessage, ServerResponse } from "node:http";

/** Seule route qui reçoit des images : recto, verso et selfie en base64, 2 Mo chacune au plus. */
export const CHEMIN_DEPOT_IDENTITE = "/comptes/moi/identite";
export const TAILLE_MAX_DEPOT_IDENTITE = 9 * 1024 * 1024;

type Suite = (erreur?: unknown) => void;

/**
 * Lit un corps JSON plus gros que la limite ordinaire (100 ko), pour une seule route. Écrit sans dépendance
 * nouvelle. Au-delà de la taille permise, la lecture s'arrête et la requête est refusée (413).
 */
function lireGrosCorpsJson(tailleMax: number) {
  return (req: IncomingMessage & { body?: unknown; _body?: boolean }, res: ServerResponse, suite: Suite) => {
    if (req.method !== "POST" || !/^application\/json/i.test(req.headers["content-type"] ?? "")) return suite();
    const morceaux: Buffer[] = [];
    let taille = 0;
    let refuse = false;
    req.on("data", (morceau: Buffer) => {
      if (refuse) return;
      taille += morceau.length;
      if (taille > tailleMax) {
        refuse = true;
        res.writeHead(413, { "content-type": "application/json", connection: "close" });
        res.end(JSON.stringify({ statusCode: 413, message: "Corps trop volumineux" }));
        return;
      }
      morceaux.push(morceau);
    });
    req.on("end", () => {
      if (refuse) return;
      try {
        req.body = JSON.parse(Buffer.concat(morceaux).toString("utf8")) as unknown;
      } catch {
        res.writeHead(400, { "content-type": "application/json" });
        res.end(JSON.stringify({ statusCode: 400, message: "JSON invalide" }));
        return;
      }
      // Marque comprise par l'analyseur ordinaire, qui ne relit pas un corps déjà lu.
      req._body = true;
      suite();
    });
    req.on("error", suite);
  };
}

/**
 * Réglages communs au serveur réel (`main.ts`) et aux tests qui en ont besoin. L'application doit être créée
 * avec `bodyParser: false` : la limite ordinaire reste à 100 ko partout, sauf pour le dépôt des pièces.
 */
export function configurerApplication(app: NestExpressApplication): void {
  // Ne pas annoncer le framework (en-tête « X-Powered-By: Express ») : rien à offrir à un attaquant.
  app.disable("x-powered-by");
  app.use(CHEMIN_DEPOT_IDENTITE, lireGrosCorpsJson(TAILLE_MAX_DEPOT_IDENTITE));
  app.useBodyParser("json");
  app.useBodyParser("urlencoded", { extended: true });
}
