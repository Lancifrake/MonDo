import type { NestExpressApplication } from "@nestjs/platform-express";
import type { IncomingMessage, ServerResponse } from "node:http";

/** Seule route qui reçoit des images : recto, verso et selfie en base64, 2 Mo chacune au plus. */
export const CHEMIN_DEPOT_IDENTITE = "/comptes/moi/identite";
export const TAILLE_MAX_DEPOT_IDENTITE = 9 * 1024 * 1024;

type Suite = (erreur?: unknown) => void;
type RequeteBrute = IncomingMessage & { body?: unknown; _body?: boolean };

/**
 * Lit un corps JSON plus gros que la limite ordinaire (100 ko), pour une seule route. Écrit sans dépendance
 * nouvelle. Au-delà de la taille permise, la requête est refusée (413) et plus rien n'est gardé en mémoire.
 */
function lireGrosCorpsJson(tailleMax: number) {
  return (req: RequeteBrute, res: ServerResponse, suite: Suite) => {
    if (req.method !== "POST" || !/^application\/json/i.test(req.headers["content-type"] ?? "")) return suite();
    // Taille annoncée trop grande : refus immédiat, sans lire ni garder un seul octet du corps.
    if (Number(req.headers["content-length"] ?? 0) > tailleMax) {
      res.writeHead(413, { "content-type": "application/json" });
      res.end(JSON.stringify({ statusCode: 413, message: "Corps trop volumineux" }));
      // Ce que le client envoie encore est jeté au fur et à mesure, sans couper la connexion sous ses pieds.
      req.resume();
      return;
    }
    const morceaux: Buffer[] = [];
    let taille = 0;
    let refuse = false;
    req.on("data", (morceau: Buffer) => {
      if (refuse) return;
      taille += morceau.length;
      if (taille > tailleMax) {
        // On répond tout de suite et on ne garde plus rien en mémoire ; le reste de l'envoi est ignoré sans
        // couper la connexion, pour que le client lise bien le refus.
        refuse = true;
        morceaux.length = 0;
        res.writeHead(413, { "content-type": "application/json" });
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
  const grosCorps = lireGrosCorpsJson(TAILLE_MAX_DEPOT_IDENTITE);
  app.use(CHEMIN_DEPOT_IDENTITE, grosCorps);
  // Pièces d'une récupération sans contact : /comptes/recuperation/<id>/pieces, et seulement ce chemin.
  app.use("/comptes/recuperation", (req: RequeteBrute, res: ServerResponse, suite: Suite) =>
    /^\/[0-9a-f-]{36}\/pieces\/?$/i.test(req.url ?? "") ? grosCorps(req, res, suite) : suite(),
  );
  app.useBodyParser("json");
  app.useBodyParser("urlencoded", { extended: true });
}
