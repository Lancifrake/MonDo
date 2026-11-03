# User flows de MonDo

**Ce fichier est gelé depuis le 27/10/2026.** La source qui fait foi est `docs/conception/userflows/mondo-userflows.drawio` (draw.io, 8 pages). Ce texte Mermaid et les images PNG et SVG du dossier `userflows/` ne sont plus mis à jour : ils montrent l'état du 27/10. Toute modification des flows se fait dans le fichier draw.io.

Date : 27/10/2026. Source : user stories de `docs/cadrage/mondo-vision-v2.md`. Outil : Mermaid (texte versionné dans le dépôt, rendu en image avec mermaid-cli, vérifié dans un navigateur). Les maquettes d'écrans viendront ensuite, dans un outil de maquettage ; un user flow décrit les étapes, pas l'apparence.

Légende : rectangle = écran ou action de l'utilisateur ; losange = décision ou règle du système ; cylindre = ce que MonDo enregistre dans le registre. Les valeurs chiffrées (seuils, délais) sont des propositions de `docs/conception/score-et-places.md`.

## Vue d'ensemble : tout le parcours en un diagramme

```mermaid
flowchart TD
    A["Flow 1 : s'inscrire, niveau 1 puis niveau 2 si besoin"] --> B{"Organiser ou rejoindre ?"}
    L["Flow 2 : récupérer son compte après une perte de téléphone"] -.-> A
    B -->|Organiser| C["Flow 3 : créer une tontine, règlement signé"]
    B -->|Rejoindre| D["Flow 4 : rejoindre un cercle, engagements signés"]
    C --> E["Cercle complet"]
    D --> E
    E --> F["Flow 5 : ordre de passage, score, zones, échange de place"]
    F --> G["Flow 6 : cotiser par Mobile Money, confirmation du bénéficiaire"]
    G --> H{"Cotisation payée dans les délais ?"}
    H -->|Oui| I["Score en hausse, tour suivant"]
    I --> G
    I -->|"Dernier tour"| K["Cycle terminé, bonus de score"]
    H -->|Non| J["Flow 7 : défaut, pénalité de score, dossier de preuve"]
```

Les sept flows détaillés suivent, un par activité des user stories.

## 1. Inscription et vérification d'identité

```mermaid
flowchart TD
    A["Ouvrir MonDo"] --> B["Saisir numéro et nom complet"]
    B --> C["Recevoir et saisir le code SMS"]
    C --> D["Choisir un code secret"]
    D --> E["Le téléphone crée la clé de signature"]
    E --> F[("Registre : compte créé, clé enregistrée")]
    F --> G["Niveau 1 : parcourir le catalogue"]
    G --> H{"Veut rejoindre un cercle d'inconnus, recevoir une cagnotte ou dépasser le montant fixé ?"}
    H -->|"Non, cercle privé et petit montant"| I["Rester au niveau 1"]
    H -->|Oui| J["Photo de la carte d'identité, recto et verso"]
    J --> K["Selfie"]
    K --> L{"Vérification"}
    L -->|"Acceptée (simulée au prototype)"| M["Niveau 2 : identité vérifiée"]
    L -->|Refusée| N["Message clair et nouvel essai"]
    N --> J
    M --> O[("Registre : niveau 2 atteint")]
```

## 2. Récupération du compte après perte du téléphone

```mermaid
flowchart TD
    A["Ouvrir MonDo sur le nouveau téléphone"] --> B["Saisir son numéro"]
    B --> C["Code SMS"]
    C --> D["Code secret"]
    D --> E{"Les deux sont corrects ?"}
    E -->|Non| F["Refus, limite d'essais, blocage temporaire"]
    E -->|Oui| G["Message envoyé à l'ancien téléphone et au contact de confiance"]
    G --> H["Délai d'attente : 24 à 72 h selon l'enjeu"]
    H --> I{"Le titulaire s'y oppose ?"}
    I -->|Oui| J["Blocage, vérification d'identité renforcée"]
    I -->|Non| K["Le nouveau téléphone crée une nouvelle clé"]
    K --> L[("Registre : ancienne clé révoquée, nouvelle clé ajoutée")]
    L --> M["Numéro de réception de cagnotte gelé quelques jours"]
    M --> N["Compte récupéré, signatures passées toujours valables"]
```

## 3. Créer une tontine

```mermaid
flowchart TD
    A["Organisateur : Créer une tontine"] --> B["Montant, fréquence, nombre de membres"]
    B --> C["Pénalités de retard chiffrées"]
    C --> D["Délai de grâce, proposé selon la fréquence"]
    D --> E["Cercle privé ou ouvert à des inconnus"]
    E --> F["Aperçu du règlement généré"]
    F --> G["L'organisateur lit et signe avec sa clé"]
    G --> H[("Registre : cercle créé, empreinte du règlement")]
    H --> I["Inviter par lien ou numéro"]
    I --> J["Cercle en attente de membres"]
```

## 4. Rejoindre un cercle

```mermaid
flowchart TD
    A["Membre : parcourir le catalogue"] --> B["Filtrer par montant, durée, date de cagnotte"]
    B --> C["Ouvrir la fiche d'un cercle"]
    C --> D["Voir la règle, la zone de passage proposée et les frais éventuels"]
    D --> E{"Niveau d'identité suffisant ?"}
    E -->|Non| F["Vérifier son identité, niveau 2"]
    F --> G
    E -->|Oui| G{"Score suffisant pour la zone voulue ?"}
    G -->|Non| H["Proposer une zone accessible, par défaut la fin de cycle"]
    G -->|Oui| I["Zone de passage confirmée"]
    H --> I
    I --> J["Lire le règlement et la reconnaissance de dette"]
    J --> K["Signer avec la clé, confirmer par le code secret"]
    K --> L[("Registre : membre admis, empreinte des documents signés")]
    L --> M["Documents conservés et copie remise au membre"]
    M --> N["Associer un objectif personnel, visible par lui seul"]
```

## 5. Ordre de passage et échange de place

```mermaid
flowchart TD
    A["Le cercle est complet"] --> B["MonDo calcule l'ordre : zones, puis score, puis ordre d'inscription"]
    B --> C[("Registre : ordre figé et publié")]
    C --> D["Chaque membre voit l'ordre et pourquoi"]
    D --> E{"Un membre veut passer plus tôt ?"}
    E -->|Non| F["Le cycle suit l'ordre"]
    E -->|Oui| G{"Éligible à la zone visée ?"}
    G -->|Non| H["Refus : un score trop bas ne s'achète pas"]
    G -->|Oui| I["Choisir un membre de la même zone et voir les frais"]
    I --> J{"Le membre visé accepte de céder sa place ?"}
    J -->|Non| K["Aucun changement"]
    J -->|Oui| L["Les deux signent l'échange"]
    L --> M[("Registre : échange, frais, part pour celui qui cède")]
    M --> F
```

## 6. Cotiser

```mermaid
flowchart TD
    A["Rappel avant la date limite"] --> B["Membre : ouvrir la cotisation"]
    B --> C["Voir à qui envoyer sa part et combien"]
    C --> D["Payer par Orange Money ou MoMo, hors de MonDo"]
    D --> E["Indiquer la référence de la transaction"]
    E --> F["Le bénéficiaire reçoit la demande de confirmation"]
    F --> G{"Le bénéficiaire confirme ?"}
    G -->|Oui| H[("Registre : cotisation confirmée")]
    H --> I["Score : plus 4 si avant la date limite"]
    G -->|"Non, ou pas de réponse"| J["Rappel au bénéficiaire, puis signalement"]
    J --> K{"Le payeur peut-il prouver le paiement ?"}
    K -->|Oui| L["Référence vérifiée, cotisation confirmée"]
    K -->|Non| M["Cotisation reste due, délai de grâce en cours"]
    L --> H
    I --> N["Tableau du tour mis à jour pour tous"]
```

## 7. Défaut et dossier de preuve

```mermaid
flowchart TD
    A["Date limite dépassée"] --> B["Pénalité de retard et score moins 1"]
    B --> C["Rappels automatiques pendant le délai de grâce"]
    C --> D{"Cotisation payée avant la fin du délai ?"}
    D -->|Oui| E["Retard réglé, aucun défaut"]
    D -->|Non| F[("Registre : défaut constaté")]
    F --> G["Score moins 30, plus de première place au cycle suivant"]
    G --> H["Mise en demeure datée envoyée au membre"]
    H --> I{"Régularisation ?"}
    I -->|Oui| J["Cotisation et pénalité réglées, dossier clos"]
    I -->|Non| K["Les membres lésés peuvent exporter le dossier de preuve"]
    K --> L["Identité, règlement signé, reconnaissance de dette, relevé, mise en demeure"]
    L --> M["Le membre lésé décide d'agir ou non"]
```

## Points que les flows font ressortir

- **Flow 6 :** si le bénéficiaire ne répond pas, tout le tour peut se bloquer. La règle de repli (référence de transaction, délai, signalement) reste à fixer.
- **Flow 5 :** un échange de place nécessite deux signatures. Il faut décider de ce qui se passe si l'un des deux n'a plus de téléphone accessible.
- **Flow 2 :** le contact de confiance est désigné à l'inscription. Le flow 1 ne le demande pas encore : à ajouter ou à rendre facultatif.
- **Flow 7 :** les montants de pénalité et de mise en demeure sont ceux du règlement signé, pas calculés après coup (voir `docs/juridique/recours-legaux.md`).
