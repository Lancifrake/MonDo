# Recours légaux : ce que MonDo doit produire pour qu'un litige se plaide

Date : 27/10/2026. Statut : cadrage de travail, **pas un avis juridique**. Chaque point est marqué Vérifié (source lue en ligne), Partiel ou À vérifier par un avocat camerounais.

## 1. Le problème
Une tontine classique n'est pas une institution financière : un défaut se règle par la pression sociale. Un inconnu n'a pas ce levier, donc personne n'accepte de cotiser avec lui. MonDo doit transformer la promesse en créance que le droit sait recouvrer.

## 2. Le levier : l'injonction de payer OHADA
- Le Cameroun applique l'Acte uniforme OHADA sur les procédures simplifiées de recouvrement et les voies d'exécution. Le recouvrement d'une créance **certaine, liquide et exigible** peut se demander par injonction de payer (art. 1) ; la procédure s'ouvre notamment quand la créance a une **cause contractuelle** (art. 2). Statut : Vérifié via [ohada.com](https://www.ohada.com/documentation/jurisprudence/ohadata/J-06-107.html), texte intégral de l'Acte non relu.
- Leçon d'une décision camerounaise (Cour d'appel du Centre, 7 mars 2003) : des factures **non établies d'un commun accord** ont fait annuler l'injonction. Statut : Partiel, une seule décision ancienne, lue en résumé.
- Conséquence de conception : un montant calculé par MonDo ne suffit pas. Il doit avoir été **accepté à l'avance par le débiteur** dans un document signé.

## 3. La preuve électronique
- Droit camerounais : la [loi 2010/021 du 21 décembre 2010](https://www.mincommerce.gov.cm/sites/default/files/documents/loi-n-2010-021-du-21-decembre-2010-regissant-le-commerce-electronique-au-cameroun.pdf) régit le commerce électronique. Un commentaire la cite, avec l'art. 5 de l'Acte uniforme sur le droit commercial général, pour l'équivalence entre écrit électronique et écrit papier ([Kalieu Elongo](https://kalieu-elongo.com/le-regime-de-la-preuve-electronique-au-cameroun-entre-reglementation-nationale-et-droit-uniforme-ohada/)). Statut : Partiel. Je n'ai pas lu le texte exact de l'art. 10 ni les conditions de fiabilité de la signature, ni la notion de certificat qualifié.
- **Lu dans le texte même de la loi 2010/021** (extrait dans `loi-2010-021-commerce-electronique.txt`, interprétation de ma part, pas d'un juriste) :
  - Art. 2 : la signature électronique est définie comme obtenue par un **algorithme de chiffrement asymétrique** qui authentifie l'émetteur et vérifie l'intégrité. Un simple code OTP SMS ne correspond pas à cette définition ; une paire de clés par utilisateur y correspond.
  - Art. 10 : le régime des contrats écrits s'applique aux contrats électroniques (volonté, validité, effets, exécution). Exceptions notamment : droits sur les biens immobiliers, contrats exigeant un tribunal ou une autorité publique.
  - Art. 13 : un écrit exigé peut être électronique selon les articles 1317 et suivants du Code civil. **Exception : les actes sous seing privé relatifs aux sûretés personnelles ou réelles** (cautionnement, gage), sauf s'ils sont passés pour les besoins de la profession de la personne. Une caution signée par un particulier ne peut donc pas l'être électroniquement.
  - Art. 14 : pour un contrat électronique au-delà d'un montant fixé par règlement, le contractant professionnel doit **conserver l'écrit** pendant un délai fixé par règlement et en garantir l'accès à l'autre partie.
  - Art. 35 et 38 : les conditions d'usage de la signature et d'exercice des autorités de certification relèvent d'un **texte particulier**, absent de cette loi. Les conditions exactes de la signature fiable restent donc non lues.
- La blockchain ne crée pas de valeur légale en soi. Elle sert à prouver qu'un document n'a pas été modifié depuis une date (empreinte horodatée). La force probante reste celle du document signé et des relevés Mobile Money.

## 4. Les pièces que MonDo doit générer (dossier de preuve)
0. **Identité vérifiée du débiteur** (niveau 2 : carte d'identité et selfie) : sans elle, la reconnaissance de dette ne désigne qu'un numéro de téléphone.
1. **Règlement du cercle** accepté et signé par chaque membre : montant, fréquence, ordre calculé selon une règle écrite, **pénalités chiffrées**, mode de constat du défaut, droit de recouvrement.
2. **Reconnaissance de dette** signée à l'entrée, formulée pour que le montant devienne certain et liquide au moment du défaut (ex. somme des cotisations restantes + pénalité plafonnée définies d'avance).
3. **Relevé des cotisations** : qui a payé quoi et quand, avec référence de la transaction Mobile Money et confirmation du bénéficiaire.
4. **Mise en demeure** horodatée, envoyée par canal tracé, avant tout recours.
5. **Empreinte** (hash) de ces pièces ancrée dans le registre, plus export PDF daté remis au créancier.

## 5. Qui est le créancier ?
MonDo n'est pas partie (il ne détient pas de fonds). La dette naît entre membres : celui qui a reçu la cagnotte et cesse de cotiser doit aux membres encore en attente. Il faut décider avec un juriste si la reconnaissance de dette vise chaque membre individuellement, le cercle collectivement, ou un mandataire désigné pour agir. Statut : À vérifier.

## 6. Risques à instruire
- **Clause pénale et frais de première place** : peuvent être requalifiés (intérêts, usure, activité de crédit). Un juge peut aussi réduire une pénalité jugée excessive. Statut : À vérifier.
- **Statut réglementaire** : la collecte d'épargne du public sans agrément est assimilée à une activité bancaire illégale, et la microfinance sans agrément est interdite en CEMAC (sources secondaires : [LeFisk](https://lefisk.cm/blog/creer-microfinance-cameroun-2026-agrement-cobac-dossier-categories), [Financial Afrik](https://www.financialafrik.com/2021/04/12/cameroun-les-etablissements-de-microfinance-sommes-de-se-conformer-au-nouveau-dispositif-prudentiel-de-la-cobac)). Je n'ai pas trouvé de texte sur le statut de la tontine entre membres. Les seuils de capital cités se contredisent d'une source à l'autre : ne pas les utiliser. Le risque grandit en phase 2 (retenue, fonds de garantie).
- **Coût contre montant** : un recours qui coûte plus que la créance (cotisations de 10 000 à 50 000 FCFA) ne dissuade personne. Le vrai effet est la dissuasion : prévenir à l'inscription que le dossier est constitué, et réserver le recours judiciaire aux gros montants.
- **Données personnelles** : le dossier de preuve contient des pièces d'identité et des numéros. Droit camerounais applicable à vérifier.

## 7. Questions pour l'avocat (à faire valider avant toute pilote réel)
1. OTP SMS : signature simple recevable ? Quelles exigences pour la rendre opposable ?
2. Reconnaissance de dette électronique entre particuliers : forme minimale, mention du montant, risque de nullité.
3. Injonction de payer sur la base de ce dossier : tribunal compétent, délais, coût, seuil.
4. Le statut « logiciel de gestion » tient-il si MonDo constate le défaut et calcule les pénalités ?
5. Frais de première place et bonus : conformes ou requalifiables en intérêts ?
6. Médiation ou arbitrage prévu par clause : utile avant le tribunal ?

## 8. Impact sur le produit
- Les user stories de signature (règlement et reconnaissance de dette) restent MVP et deviennent le cœur de la promesse, pas un détail.
- Ajouter une user story MVP : **export du dossier de preuve** par cercle et par défaut.
- Le prototype simule ; la valeur légale réelle exige l'avis de l'avocat avant la phase 1.

## 9. Décisions prises sans avocat (27/10/2026, proposées, à valider par David)
Principe : décider par défaut prudent, et marquer ce qu'on ne peut pas trancher comme porte à franchir avant un pilote réel.

1. **Signature en deux couches** : l'OTP SMS authentifie la session, mais le règlement et la reconnaissance de dette sont signés avec une **clé propre à l'utilisateur** (signature asymétrique, au sens de l'art. 2), et l'empreinte du document est ancrée dans le registre. L'OTP seul ne signe jamais un engagement.
2. **Le parrainage n'est pas une caution** : il donne un bonus de réputation, sans responsabilité financière du parrain. Sinon l'art. 13 (sûretés personnelles) interdirait la signature électronique pour un particulier. À réexaminer pour la retenue et le fonds de garantie de la phase 2.
3. **Promesse produit prudente** : le prototype et la phase 1 promettent « un dossier de preuve prêt pour le recouvrement », jamais « vous serez remboursé ».
4. **Conservation et accès** (art. 14) : MonDo conserve les pièces signées et les rend accessibles au membre sur demande.
5. **Montants plafonnés au pilote** : cotisations petites, pour limiter le dommage si une pièce s'avère non opposable.

## 10. Porte avant tout pilote réel
Sans avocat, rien n'est prouvé : seulement défendable. Avant d'encaisser un seul client ou de promettre un recours, une validation humaine est requise sur les points 1 à 3 de la section 7. Pistes à tester, non vérifiées : clinique juridique ou enseignants de droit d'une faculté (Yaoundé, Douala), consultation à l'ordre des avocats, ANTIC pour le texte sur la signature et les autorités de certification. Pour le prototype et la soutenance, aucun avocat n'est nécessaire.
