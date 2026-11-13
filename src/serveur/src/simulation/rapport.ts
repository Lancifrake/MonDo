import { mesurerAssistant } from "../assistant/mesures.js";
import { HYPOTHESES, simulerScenario, type Profil, type ResultatScenario, type Scenario } from "./simulation.js";

/** Trois couleurs hors texte, comme le demande la grille du poster : MonDo, référence, neutre. */
const VERT = "#0B6B4A";
const AMBRE = "#B86E00";
const NOIR = "#1B1D1C";

const fcfa = (v: number) => `${Math.round(v).toLocaleString("fr-FR").replace(/ | /g, " ")} FCFA`;
const pourcent = (v: number) => `${(v * 100).toFixed(1).replace(".", ",")} %`;
const echapper = (t: string) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;");

interface Serie {
  nom: string;
  couleur: string;
  valeurs: number[];
}

/** Barres groupées en SVG, sans bibliothèque : lisibles à distance, valeur écrite au-dessus de chaque barre. */
function barres(titre: string, categories: string[], series: Serie[], formater: (v: number) => string): string {
  const largeur = Math.max(960, categories.length * 170);
  const hauteur = 480;
  const marge = { haut: 70, bas: 90, gauche: 30, droite: 30 };
  const zoneL = largeur - marge.gauche - marge.droite;
  const zoneH = hauteur - marge.haut - marge.bas;
  const max = Math.max(1e-9, ...series.flatMap((s) => s.valeurs));
  const groupe = zoneL / categories.length;
  const barre = Math.min(64, (groupe * 0.8) / series.length);
  const elements: string[] = [];
  categories.forEach((cat, i) => {
    const x0 = marge.gauche + i * groupe + (groupe - barre * series.length) / 2;
    series.forEach((s, j) => {
      const v = s.valeurs[i]!;
      const h = (v / max) * zoneH;
      const x = x0 + j * barre;
      const y = marge.haut + zoneH - h;
      elements.push(
        `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${(barre - 4).toFixed(1)}" height="${h.toFixed(1)}" fill="${s.couleur}"/>`,
      );
      elements.push(
        `<text x="${(x + (barre - 4) / 2).toFixed(1)}" y="${(y - 6).toFixed(1)}" font-size="12" text-anchor="middle" fill="${NOIR}">${echapper(formater(v))}</text>`,
      );
    });
    elements.push(
      `<text x="${(marge.gauche + i * groupe + groupe / 2).toFixed(1)}" y="${hauteur - marge.bas + 24}" font-size="14" text-anchor="middle" fill="${NOIR}">${echapper(cat)}</text>`,
    );
  });
  const legende = series
    .map(
      (s, j) =>
        `<rect x="${marge.gauche + j * 220}" y="${hauteur - 34}" width="16" height="16" fill="${s.couleur}"/>` +
        `<text x="${marge.gauche + j * 220 + 24}" y="${hauteur - 21}" font-size="15" fill="${NOIR}">${echapper(s.nom)}</text>`,
    )
    .join("");
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${largeur} ${hauteur}" font-family="Helvetica, Arial, sans-serif">` +
    `<title>${echapper(titre)}</title><rect width="100%" height="100%" fill="#FFFFFF"/>` +
    `<text x="${marge.gauche}" y="38" font-size="24" font-weight="700" fill="${NOIR}">${echapper(titre)}</text>` +
    `<line x1="${marge.gauche}" y1="${marge.haut + zoneH}" x2="${largeur - marge.droite}" y2="${marge.haut + zoneH}" stroke="${NOIR}" stroke-width="1"/>` +
    elements.join("") +
    legende +
    "</svg>\n"
  );
}

export interface Rapport {
  resultats: ResultatScenario[];
  csv: string;
  resume: string;
  figures: Record<string, string>;
}

const COURT: Record<string, string> = {
  "S1-tontine-saine": "S1 saine",
  "S2-retards": "S2 retards",
  "S3-defaut-apres-reception": "S3 défaut",
  "S4-cercle-de-nouveaux": "S4 nouveaux",
  "S5-mixte": "S5 mixte",
  "S6-grande-tontine": "S6 50 membres",
  "S7-connus-sous-le-seuil": "S7 sous le seuil",
};

/** Rapport de mesures (cahier des charges, M16) : tableur, résumé lisible et trois figures pour le poster. */
export function genererRapport(scenarios: readonly Scenario[]): Rapport {
  const resultats = scenarios.flatMap((s) => [simulerScenario(s, "mondo"), simulerScenario(s, "traditionnel")]);
  const colonnes = [
    "scenario",
    "mode",
    "cycles",
    "du_fcfa",
    "impaye_fcfa",
    "taux_impayes",
    "pertes_membres_honnetes_fcfa",
    "retards",
    "defauts",
    "relances_a_la_main",
    "actions_de_l_assistant",
    "messages_entre_agents",
    "duree_max_decision_ms",
  ];
  const lignes = resultats.map((r) =>
    [
      r.scenario,
      r.mode,
      r.cycles.length,
      r.totaux.du,
      r.totaux.impaye,
      r.totaux.tauxImpayes.toFixed(4),
      r.totaux.pertesHonnetes,
      r.totaux.retards,
      r.totaux.defauts,
      r.totaux.relancesManuelles,
      r.totaux.actionsAssistant,
      r.totaux.messagesAgents,
      r.totaux.dureeMaxDecisionMs.toFixed(3),
    ].join(";"),
  );
  const csv = [colonnes.join(";"), ...lignes].join("\n") + "\n";

  const paire = (nom: string) => ({
    mondo: resultats.find((r) => r.scenario === nom && r.mode === "mondo")!,
    trad: resultats.find((r) => r.scenario === nom && r.mode === "traditionnel")!,
  });
  const noms = scenarios.map((s) => s.nom);
  const categories = noms.map((n) => COURT[n] ?? n);

  const mixte = scenarios.find((s) => s.nom === "S5-mixte") ?? scenarios[0]!;
  const scoresMixte = paire(mixte.nom).mondo.scores;
  const profils: Profil[] = ["bon_payeur", "retardataire", "solde_insuffisant", "defaillant"];
  const moyenne = (p: Profil) => {
    const ids = mixte.membres.filter((m) => m.profil === p).map((m) => m.id);
    return ids.length === 0 ? 0 : ids.reduce((t, id) => t + scoresMixte[id]!, 0) / ids.length;
  };
  const libelleProfil: Record<Profil, string> = {
    bon_payeur: "bon payeur",
    retardataire: "retardataire",
    solde_insuffisant: "solde insuffisant",
    defaillant: "défaillant",
  };

  const figures = {
    "taux-impayes.svg": barres(
      "Part des cotisations jamais payées",
      categories,
      [
        { nom: "Avec MonDo", couleur: VERT, valeurs: noms.map((n) => paire(n).mondo.totaux.tauxImpayes) },
        { nom: "Tontine traditionnelle", couleur: AMBRE, valeurs: noms.map((n) => paire(n).trad.totaux.tauxImpayes) },
      ],
      pourcent,
    ),
    "pertes-membres-honnetes.svg": barres(
      "Argent perdu par les membres honnêtes (FCFA)",
      categories,
      [
        { nom: "Avec MonDo", couleur: VERT, valeurs: noms.map((n) => paire(n).mondo.totaux.pertesHonnetes) },
        {
          nom: "Tontine traditionnelle",
          couleur: AMBRE,
          valeurs: noms.map((n) => paire(n).trad.totaux.pertesHonnetes),
        },
      ],
      (v) => fcfa(v).replace(" FCFA", ""),
    ),
    "score-par-profil.svg": barres(
      `Score moyen après ${mixte.cycles} cycles, par profil (${COURT[mixte.nom] ?? mixte.nom})`,
      profils.map((p) => libelleProfil[p]),
      [{ nom: "Score MonDo sur 100", couleur: VERT, valeurs: profils.map(moyenne) }],
      (v) => String(Math.round(v)),
    ),
  };

  const agents = mesurerAssistant(10);
  const ligneTableau = (n: string) => {
    const { mondo, trad } = paire(n);
    return `| ${n} | ${pourcent(mondo.totaux.tauxImpayes)} | ${pourcent(trad.totaux.tauxImpayes)} | ${fcfa(mondo.totaux.pertesHonnetes)} | ${fcfa(trad.totaux.pertesHonnetes)} | ${mondo.totaux.retards} | ${trad.totaux.retards} | ${trad.totaux.relancesManuelles} |`;
  };
  const p = HYPOTHESES.probabilites;
  const resume = `# Rapport de mesures du simulateur MonDo

Généré par \`corepack pnpm simulation\` (src/serveur). Données synthétiques : aucun membre réel. Chaque scénario est rejoué avec MonDo et avec une tontine traditionnelle de référence, à graine fixe : relancer la commande redonne exactement les mêmes chiffres (sauf les durées).

## Résultats

| Scénario | Impayés MonDo | Impayés tradition | Pertes des honnêtes MonDo | Pertes des honnêtes tradition | Retards MonDo | Retards tradition | Relances à la main (tradition) |
|---|---|---|---|---|---|---|---|
${noms.map(ligneTableau).join("\n")}

${scenarios.map((s) => `- **${s.nom}** : ${s.description}, ${s.cycles} cycles, ${fcfa(s.montant)} par cotisation, graine ${s.graine}.`).join("\n")}

## Ce que montrent les chiffres

- Face à des membres bien établis (deux cycles derrière eux), un nouveau qui veut partir avec la cagnotte n'a rien à gagner avec MonDo : son score le place en dernier, il a tout payé avant de recevoir (S3 : aucune perte, contre 650 000 FCFA sans MonDo). Sans MonDo, l'ordre tiré au sort le met souvent en tête. Dans le scénario mixte (S5), les pertes qui restent viennent du membre au solde insuffisant, pas du défaillant, qui finit par tout payer faute de pouvoir passer devant (d'où son score de 70).
- Les rappels de l'assistant réduisent les retards ; l'organisateur n'a plus de relance à faire à la main (S2, S5).
- Après un défaut, le membre n'est plus jamais placé en tête (fermeture des premières places), ce qui limite le second coup.

## Points non résolus, à montrer tels quels

- **Cercle de nouveaux (S4)** : au premier cycle, personne n'a de score ; un défaillant peut encore recevoir une cagnotte avant d'avoir tout payé. MonDo perd moins que la tradition, mais pas zéro. Les parades étudiées (plafond de cagnotte, premier tour à l'organisateur, retenue) sont dans la décision 05, question 4.
- **Membres connus sous le seuil du début (S7)** : quand personne n'atteint le score des premières places (60), ces places restent vides, puis vont, selon la règle du 08/11, aux mieux classés de ceux qui n'ont rien trouvé ; un nouveau peut alors y tomber. Le cahier des charges demande au contraire « aucun nouveau membre dans les premières places ». À trancher : faire avancer les mieux classés de tout le cercle, ou baisser le seuil du début.
- **Fraudeur patient dans un grand cercle (S6)** : dans un cercle de 50, un seul cycle parfait rapporte 100 points (49 cotisations à temps, plafonné). Un défaillant qui joue honnêtement un premier cycle prend la place 1 au cycle suivant, puis s'arrête de payer : c'est l'essentiel des pertes de S6 avec MonDo. Parades étudiées dans la décision 05 (questions 4 et 11) : plafond de cagnotte selon les cagnottes déjà remboursées, points plafonnés par cycle ou dans le temps.

## Système multi-agents (grille d'évaluation)

Scénario de démonstration de l'assistant (10 membres, rappels, un retard puis un défaut), ${agents.lancements} lancements : ${agents.autonome.cycles} cycles, ${agents.autonome.messages} messages entre agents, durée la plus longue ${agents.autonome.dureeMaxMs.toFixed(3).replace(".", ",")} ms (cible : moins de 2 secondes), résultat ${agents.autonome.identiques ? "identique à chaque lancement" : "variable"}. Dans les scénarios ci-dessus, la décision la plus longue des agents sur un cycle complet a pris ${Math.max(
    ...resultats.map((r) => r.totaux.dureeMaxDecisionMs),
  )
    .toFixed(3)
    .replace(".", ",")} ms.

## Hypothèses du modèle de comportement

Ce sont des choix pour le prototype, pas des mesures sur de vraies tontines. Les changer change les chiffres.

- Bon payeur : ${pourcent(p.bon_payeur.aTemps)} à temps, ${pourcent(p.bon_payeur.retard)} en retard.
- Retardataire : ${pourcent(p.retardataire.aTemps)} à temps, ${pourcent(p.retardataire.retard)} en retard.
- Solde insuffisant : ${pourcent(p.solde_insuffisant.aTemps)} à temps, ${pourcent(p.solde_insuffisant.retard)} en retard, ${pourcent(p.solde_insuffisant.defaut)} jamais payé.
- Défaillant : ${HYPOTHESES.defaillant}.
- Avec MonDo, les rappels évitent ${pourcent(HYPOTHESES.retardsEvitesParLesRappels)} des retards.
- Tontine traditionnelle : ${HYPOTHESES.ordreTraditionnel} ; ${HYPOTHESES.relancesManuelles}.
- Les membres déjà connus ont un cycle complet dans MonDo avant le scénario ; chacun demande la place 1 et l'attribution tranche.

## Figures

- \`taux-impayes.svg\` : part des cotisations jamais payées, par scénario.
- \`pertes-membres-honnetes.svg\` : argent versé par les membres honnêtes sans le recevoir en retour.
- \`score-par-profil.svg\` : score moyen par profil après le scénario mixte.
`;
  return { resultats, csv, resume, figures };
}
