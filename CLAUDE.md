# MonDo, instructions projet

> Ce fichier LOCAL prime sur `/Users/smcdavid/Downloads/CLAUDE.md` (parent) : ignorer le chemin mémoire « BAHAMAS » et celui de Trading AI.

## Projet
Tontine digitale sûre entre inconnus au Cameroun : score de fiabilité, ordre de passage par score, retenue et fonds de garantie (phase 2), paiement Mobile Money (simulé au prototype). MonDo ne détient jamais les fonds. Vision : `docs/cadrage/mondo-vision-partie-1-et-2.pdf`.

## Sauvegarde automatique de la mémoire
Après chaque tâche terminée, mettre à jour `/Users/smcdavid/.claude/projects/-Users-smcdavid-Downloads-MonDo/memory/` (fichier `project_*.md` concerné, nouveau fichier si info importante, `MEMORY.md` toujours à jour).

## Organisation
`docs/cadrage`, `docs/conception`, `docs/business`, `docs/juridique`, `src/`. Noms explicites et cohérents.

## Sources qui font foi
- User flows : `docs/conception/userflows/mondo-userflows.drawio` (draw.io). Le Mermaid `docs/conception/userflows.md` et les PNG/SVG sont gelés depuis le 27/10/2026, ne pas les mettre à jour.
- Cas d'utilisation : `docs/conception/cas-d-utilisation/User-Case.vpp` (Visual Paradigm, fichier de travail de David). Le XMI et le draw.io du cas d'utilisation ont été supprimés le 03/11/2026. Le PNG d'aperçu est une image de référence, plus mise à jour.
- Architecture : `docs/conception/architecture/mondo-architecture.excalidraw` (Excalidraw, à ouvrir sur excalidraw.com ou dans l'extension VS Code). Le PNG d'aperçu est une image de référence, pas le rendu Excalidraw. Zoom du serveur (liens entre modules) : `mondo-architecture-serveur.excalidraw`. Icônes : `mondo-icones.excalidrawlib` (23 icônes Lucide, licence ISC dans `LICENCE-lucide.txt`, à importer via le panneau Bibliothèque > Ouvrir).
- Document de vision : le doc Claude « MonDo, document de vision (version 2) », https://claude.ai/artifact/EQt6NDhWd68wDivegfVbip (créé le 27/10/2026, contenu identique à `docs/cadrage/mondo-vision-v2.md`). Le .md, le .docx et le PDF d'origine sont des copies gelées à cette date : on modifie le doc Claude.

- Diagramme de classes : à dessiner par David dans Visual Paradigm à partir de `docs/conception/diagramme-de-classes.md` (spécification) ; une fois dessiné, le fichier VP fait foi. Aide visuelle à recopier : `docs/conception/classes/mondo-diagramme-de-classes.drawio` (non tenue à jour ensuite).
- Décisions de conception : `docs/conception/decision-01-blockchain-registre-sans-fonds.md`, `docs/conception/decision-02-monolithe-modulaire.md` (serveur en monolithe modulaire, règles de propriété des données et de scalabilité).

## Conventions
- Git : commits `feat` / `fix` / `chore` / `docs`, jamais de co-auteur
- Langue de travail : français
- Pas de blockquote `>` dans les textes destinés à être copiés, pas de tirets cadratins
