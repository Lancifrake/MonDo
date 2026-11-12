# Protection des données personnelles : ce que la loi 2024/017 impose à MonDo

Date : 12/11/2026. **Ce document n'est pas un avis juridique.** Il est écrit par l'équipe, sans juriste, à partir de sources secondaires (presse spécialisée, cabinets, formations) : le texte officiel de la loi n'a pas été lu, et les numéros d'articles viennent de ces sources. Il sert à préparer un rendez-vous avec un juriste camerounais, obligatoire avant tout pilote avec de vrais membres. Le prototype n'utilise que des données fictives.

## La loi en bref
Loi n° 2024/017 du 23 décembre 2024 relative à la protection des données à caractère personnel au Cameroun. Un délai de 18 mois a été laissé pour se mettre en conformité : elle s'applique depuis le 23 juin 2026 (date reprise par la presse, à confirmer). Elle crée une Autorité de protection des données (article 53) ; nous ne savons pas si elle fonctionne déjà ni comment la saisir. Les sanctions annoncées sont lourdes : amendes jusqu'à des centaines de millions de FCFA, voire un milliard pour une personne morale selon une source, et peines de prison.

## Les données que MonDo traite
| Donnée | Où | Sensibilité |
|---|---|---|
| Numéro de téléphone, nom | base, schéma `comptes` | personnelle |
| Clé publique de signature | base | technique, liée à la personne |
| Carte d'identité (recto, verso), selfie | stockage chiffré hors base | la plus sensible ; le selfie sert à reconnaître un visage, donc donnée biométrique |
| Contact de confiance : nom et numéro d'un tiers | base | personnelle, d'une personne qui n'est pas membre |
| Cotisations, montants, références Mobile Money, sommes dues, défauts, litiges | base | financière |
| Score de fiabilité, nombre de défauts | calculé | profilage qui a des effets sur la personne (places, accès aux cercles) |
| Mises en demeure, dossier de preuve | base, export | données sur un manquement, transmises à d'autres membres |
| Contenu des SMS (numéro, texte) | file d'envoi, puis fournisseur SMS | personnelle, confiée à un tiers |
| Empreintes inscrites au registre | blockchain | aucune donnée personnelle : seulement des empreintes |

## Ce que la loi impose, et où en est le code
| Obligation (d'après nos sources) | Ce qui est fait dans le code | Ce qui manque |
|---|---|---|
| **Consentement** explicite, libre, éclairé, révocable | Dépôt des pièces : consentement explicite obligatoire (`consentement: true`), texte versionné, date gardée avec le dossier. Contact de confiance : accord du contact par un code qu'il transmet. | Consentement à l'inscription pour le reste des traitements (score, partage avec le cercle). Retrait du consentement par une route. Le contact ne peut pas retirer son accord lui-même. Politique de confidentialité à écrire. |
| **Données sensibles et biométrie** (articles 48 à 51) : interdites sauf exceptions | Selfie supprimé juste après la décision. Aucune reconnaissance faciale automatique : un Administrateur compare à l'œil. Images chiffrées (AES-256-GCM), hors de la base, jamais dans les journaux. | Savoir si notre usage du selfie entre dans une exception, et à quelles conditions. |
| **Minimisation** | Le registre ne reçoit que des empreintes. Les SMS de blocage et de relance ne nomment pas les membres. La clé publique n'est pas renvoyée par `GET /comptes/moi`. Un non-membre ne voit ni les membres ni l'ordre. | Le dossier de preuve contient le nom et le numéro du débiteur : à justifier. |
| **Durée de conservation** (article 28 : fixée par l'Autorité) | Carte : 5 ans après le dernier cercle du membre, puis suppression automatique (durée provisoire). Refus : tout est supprimé. Pièces d'une récupération : supprimées à la décision. Codes SMS et requêtes vues : expirent. | Durées pour le reste : comptes inactifs, cotisations, litiges, SMS en file, journaux. Aucune purge n'existe pour eux. |
| **Sécurité** | Requêtes signées, anti-rejeu, validation stricte, accès par rôle testé, chiffrement des pièces, journal des ouvertures de pièces par un Administrateur, codes hachés, audit interne (`docs/conception/audit-securite-2026-11-06.md`). | Chiffrement de la base au repos et sauvegardes (dépend de l'hébergeur). Test d'intrusion indépendant. Gestion de la clé de stockage (rotation, sauvegarde). |
| **Transfert hors du Cameroun** (article 32) : autorisation préalable | Rien n'est hébergé. Le stockage et le SMS sont derrière des interfaces : le choix reste libre. | Choisir un hébergeur et un fournisseur SMS compatibles, ou demander l'autorisation (`docs/conception/comparatif-hebergeur-et-sms.md`). |
| **Déclaration ou autorisation préalable** du traitement (article 19) | Rien. | Savoir quel régime s'applique à MonDo et comment faire la démarche. |
| **Notification des violations** (article 22) | Rien d'automatique. Les journaux ne contiennent pas de données personnelles. | Procédure écrite : qui prévient l'Autorité et les membres, sous quel délai. |
| **Analyse d'impact** si risque élevé (article 33) | Rien. | Probablement nécessaire : identité, biométrie, données financières et notation des personnes. |
| **Droits des personnes** : accès, rectification, opposition, effacement | `GET /comptes/moi`, `/cercles`, `/cotisations`, `/sommes-dues`, `/litiges/miens`, `/comptes/moi/identite` donnent au membre ses données. | Rectification du nom. Effacement d'un compte, qui se heurte au besoin de garder les engagements signés et les preuves : à arbitrer. Export complet des données d'un membre. |
| **Décision automatisée et profilage** | Le score est le rejeu d'événements, avec des règles publiques ; l'historique est visible du membre. Litiges et identité sont décidés par un humain. | Le droit de contester son score n'a pas de route : il passe par le litige sur un paiement. |
| **Sous-traitants** | Aucun en service. | Contrats avec l'hébergeur et le fournisseur SMS. |
| **Responsable du traitement** | Aucune entité juridique. | Qui est responsable : une société, une association, des personnes ? À régler avant tout pilote. |

## Questions à poser à un juriste
1. La loi 2024/017 s'applique-t-elle à un pilote gratuit de quelques dizaines de personnes, et à partir de quand faut-il une entité juridique responsable du traitement ?
2. Quel régime pour MonDo : déclaration, autorisation préalable (article 19), ou rien pour l'instant ? L'Autorité fonctionne-t-elle, et comment la saisir ?
3. Peut-on demander un selfie pour vérifier une identité à l'œil, sans reconnaissance automatique ? Est-ce une donnée biométrique au sens de la loi, et sous quelle exception ?
4. Combien de temps peut-on garder une carte d'identité après la fin du dernier cercle d'un membre ? Nos 5 ans sont provisoires. Et après un refus ?
5. Un hébergement hors du Cameroun (Europe ou Afrique du Sud) est-il possible avec une autorisation, et quelle est la procédure (article 32) ? Le chiffrement par une clé que nous gardons change-t-il la réponse ?
6. Un fournisseur SMS étranger est-il un transfert ? Faut-il un contrat de sous-traitance particulier ?
7. Sur quelle base traiter le numéro du contact de confiance, qui n'est pas membre ? L'accord par un code transmis au membre suffit-il comme consentement ?
8. Le score de fiabilité est-il un profilage soumis à des règles particulières ? Que doit-on dire au membre, et quel recours lui offrir ?
9. Peut-on remettre à d'autres membres un dossier de preuve qui contient l'identité et les manquements d'un débiteur ? Sous quelles conditions ?
10. Un membre peut-il exiger l'effacement de ses données alors que d'autres membres ont besoin de ses engagements signés comme preuve ? Que garder, et combien de temps ?
11. Les empreintes inscrites sur une blockchain publique, qu'on ne peut pas effacer, sont-elles des données personnelles ? Nous n'y mettons aucune donnée en clair.
12. Que doit contenir la politique de confidentialité, et comment recueillir le consentement à l'inscription (langue, case à cocher, version) ?
13. En cas de fuite, qui prévenir, sous quel délai, et sous quelle forme (article 22) ?
14. Faut-il une analyse d'impact (article 33) avant le pilote, et qui peut la faire ?
15. Les obligations de la loi de 2010 sur le commerce électronique (conservation des pièces, article 14) s'ajoutent-elles à celles-ci, et les durées sont-elles compatibles ?

## Ce que l'équipe peut faire sans juriste
- Garder le prototype sur des données fictives, comme l'exige SECURITY.md.
- Écrire une première politique de confidentialité à partir du tableau ci-dessus.
- Tenir un registre simple des traitements : quelle donnée, pourquoi, où, combien de temps, qui y accède.
- Prévoir la suppression d'un compte et les durées de conservation manquantes avant le pilote.

## Sources
Voir aussi `docs/juridique/recours-legaux.md` et `docs/conception/comparatif-hebergeur-et-sms.md`.
- https://droitmediasfinance.com/index.php/actualites/droit-tech-fintech/1297-cameroun-la-loi-sur-la-protection-des-donnees-a-caractere-personnel-entre-en-vigueur-ce-23-juin-2026
- https://www.digitalbusiness.africa/cameroun-bientot-des-peines-damende-d-un-milliard-de-francs-cfa-pour-violation-des-donnees-personnelles/
- https://www.digitalbusiness.africa/cameroun-lautorite-de-protection-des-donnees-a-caractere-personnel-creee/
- https://cio-mag.com/?p=59861
- https://pollicy.org/?p=2322
