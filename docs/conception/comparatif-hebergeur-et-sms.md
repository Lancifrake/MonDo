# Comparatif : hébergeur et fournisseur SMS

Date : 12/11/2026. Statut : **proposition, rien n'est choisi**. Aucune inscription n'a été faite, aucun devis demandé. Les prix et les offres changent vite : tout chiffre marqué « à vérifier » vient de sources secondaires ou de mémoire, et se contrôle sur la page de tarifs du fournisseur avant de décider.

## Ce que le serveur demande
- Une image Docker (`src/serveur/Dockerfile`, utilisateur non root, contrôle de santé sur `/sante`), un port HTTP, HTTPS devant.
- Un PostgreSQL (`DATABASE_URL`).
- Un disque ou un stockage d'objets durable pour les pièces d'identité chiffrées (`MONDO_STOCKAGE_DOSSIER`, `MONDO_STOCKAGE_CLE`).
- Un processus qui tourne en continu : le planificateur passe toutes les heures dans le serveur lui-même. Un hébergement qui endort le serveur retarde rappels et constats de défaut ; ils sont rattrapés au réveil (tâches rejouables), mais en retard.
- Une limite par adresse IP sur `POST /comptes/otp`, `POST /comptes` et `POST /comptes/recuperation` (audit de sécurité).
- En production, le serveur refuse de démarrer sans vrai fournisseur SMS, sans registre réel et sans stockage configuré.

## La contrainte qui pèse le plus : l'article 32 de la loi 2024/017
La loi camerounaise n° 2024/017 du 23/12/2024 sur les données personnelles est applicable depuis le 23/06/2026 (date donnée par la presse spécialisée, texte officiel non lu). D'après ces sources, le transfert de données personnelles hors du Cameroun demande une autorisation préalable de l'Autorité de protection des données, et suppose un niveau de protection au moins équivalent dans le pays de destination ; un transfert sans autorisation expose à de lourdes amendes. La procédure d'autorisation n'est pas encore décrite dans ce que nous avons lu.

Conséquences pour MonDo :
- Tout hébergeur hors du Cameroun est un transfert, y compris un centre de données en Afrique du Sud ou en Europe. « En Afrique » ne suffit pas.
- Un fournisseur SMS étranger reçoit le numéro et le texte du message : c'est aussi un transfert.
- Les pièces d'identité et le selfie (donnée biométrique, donc sensible) sont le cas le plus strict.
- **Le prototype n'utilise que des données fictives : il n'est pas concerné.** La question se pose au premier membre réel.

## Hébergeur
| Option | Coût (à vérifier) | Où sont les données | Pour | Contre |
|---|---|---|---|---|
| Ordinateur de l'équipe avec Docker | 0 | sur place | parfait pour la démonstration, rien à configurer | pas accessible depuis les téléphones hors du réseau local, pas un hébergement |
| Render (offre gratuite) + PostgreSQL gratuit (Neon ou Supabase) | 0 | États-Unis ou Europe | déploie l'image Docker telle quelle, HTTPS fourni | le serveur s'endort après environ 15 minutes sans requête (planificateur en retard), pas de disque durable (pièces perdues au redémarrage), base gratuite limitée (environ 0,5 Go, mise en pause possible chez Supabase) |
| Render ou Railway payant | environ 5 à 10 USD par mois le serveur, autant la base | États-Unis ou Europe | toujours allumé, disque durable possible | payant, transfert hors du Cameroun |
| Fly.io | plus d'offre gratuite pour les nouveaux comptes ; quelques USD par mois | régions au choix, dont une en Afrique du Sud (à vérifier) | proche des utilisateurs, volumes durables | payant, toujours hors du Cameroun |
| Serveur privé virtuel en Europe (OVH, Hetzner, etc.) avec Docker et PostgreSQL sur la même machine | environ 5 à 10 EUR par mois | France ou Allemagne | tout au même endroit, disque durable, coût fixe, crédits étudiants possibles | à administrer soi-même (mises à jour, sauvegardes, pare-feu), transfert hors du Cameroun |
| Grand nuage avec région africaine (AWS Le Cap, Azure, Google Johannesburg) | crédits étudiants, puis à l'usage | Afrique du Sud | services gérés, chiffrement au repos | complexe pour une petite équipe, toujours hors du Cameroun |
| Hébergeur au Cameroun (centre de données de Camtel, ST Digital à Douala : noms à vérifier) | sur devis | Cameroun | pas de transfert au sens de l'article 32, argument de confiance | prix et qualité inconnus, pas d'offre gratuite connue, délais commerciaux |

### Recommandation
1. **Prototype et démonstration (données fictives)** : l'ordinateur de l'équipe avec Docker pour la soutenance, et si un accès depuis les téléphones est nécessaire, Render gratuit avec une base Neon gratuite. Gratuit, conforme à la décision 03, et l'article 32 ne s'applique pas à des données fictives. Accepter que le serveur s'endorme.
2. **Pilote avec de vrais membres** : ne pas choisir avant l'avis d'un juriste. Demander un devis à un ou deux hébergeurs camerounais ; c'est la voie qui évite l'autorisation de transfert. Si elle est trop chère ou trop lente, un serveur privé virtuel en Europe avec chiffrement au repos, après autorisation de l'Autorité. Dans les deux cas, les pièces d'identité restent chiffrées par notre propre clé, gardée à part.
3. Ce qui ne dépend pas du choix : l'image Docker tourne partout, la base est un PostgreSQL standard, le stockage est derrière une interface.

## Fournisseur SMS
Ordre de grandeur du besoin : un code à l'inscription, puis rappels, relances et alertes. En comptant 6 à 10 SMS par membre et par mois, 1 000 membres font 6 000 à 10 000 SMS par mois. C'est le premier poste de coût du pilote, bien avant le serveur.

| Option | Prix par SMS vers le Cameroun (à vérifier) | Couverture | Pour | Contre |
|---|---|---|---|---|
| Twilio | élevé ; des comparatifs donnent de 0,08 à plus de 0,40 USD selon l'opérateur | MTN, Orange, Camtel | documentation, fiabilité, compte de test gratuit | cher à notre volume, SMS entrant non proposé pour le +237 (décision 03), données aux États-Unis |
| Infobip | sur devis, par opérateur et par volume | présent en Afrique, connexions directes aux opérateurs annoncées | nom d'expéditeur « MonDo » possible, bonne délivrabilité annoncée | pas de prix public, contrat à négocier, données hors du Cameroun |
| Africa's Talking | portefeuille prépayé, prix par pays | Afrique de l'Est et de l'Ouest surtout ; Cameroun à confirmer | simple, pensé pour l'Afrique, pas d'engagement | couverture du Cameroun non confirmée |
| Termii | prix par pays | Nigeria d'abord ; Cameroun à confirmer | API simple, codes de vérification | couverture non confirmée |
| Agrégateur camerounais (plusieurs sociétés vendent du SMS en nombre avec une API HTTP ; noms et sérieux à vérifier sur place) | souvent annoncé entre 10 et 25 FCFA le SMS, soit 0,02 à 0,04 USD | MTN, Orange, Camtel, parfois Nexttel | de loin le moins cher, données qui restent au pays, facturation en FCFA, nom d'expéditeur | qualité inégale, API parfois sommaire, pas d'accusé de réception fiable chez tous |
| Contrat direct avec MTN et Orange | sur devis | leur propre réseau | le plus fiable | deux contrats, démarches longues, réservé à un volume établi |

À 10 000 SMS par mois : environ 150 000 à 250 000 FCFA avec un agrégateur local, contre plusieurs fois cette somme avec un fournisseur international au tarif public.

### Recommandation
1. **Prototype** : garder le connecteur simulé. Aucun SMS réel, aucun coût, aucun numéro réel.
2. **Pilote** : un agrégateur camerounais, choisi après un essai de délivrabilité sur les trois opérateurs avec deux ou trois candidats (délai de réception du code, taux d'échec, accusés de réception). Critères : API HTTP documentée, nom d'expéditeur « MonDo », accusé de réception, facture en FCFA, engagement écrit sur la confidentialité.
3. Garder un fournisseur international en secours pour les codes de connexion seulement, si l'autorisation de transfert le permet.
4. Le serveur est prêt : il suffit d'écrire une classe qui réalise `ConnecteurSms` (`src/serveur/src/sms/connecteur-sms.ts`). La file d'envoi, les reprises et l'abandon après 5 échecs existent déjà.

## À faire par l'équipe
- Vérifier chaque prix et chaque offre gratuite sur le site du fournisseur le jour du choix.
- Demander les devis (hébergeur camerounais, deux ou trois agrégateurs SMS).
- Poser au juriste les questions de `docs/juridique/protection-des-donnees.md` sur le transfert et la sous-traitance.

## Sources consultées le 12/11/2026
Sources secondaires, à recouper :
- https://www.twilio.com/en-us/sms/pricing/cm
- https://www.sent.dm/resources/cameroon-sms-pricing
- https://www.courier.com/integrations/compare/africas-talking-vs-infobip
- https://render.com/articles/platforms-with-a-real-free-tier-for-developers-in-2026.md
- https://swyftstack.com/blog/free-postgresql-hosting
- https://droitmediasfinance.com/index.php/actualites/droit-tech-fintech/1297-cameroun-la-loi-sur-la-protection-des-donnees-a-caractere-personnel-entre-en-vigueur-ce-23-juin-2026
- https://www.digitalbusiness.africa/cameroun-bientot-des-peines-damende-d-un-milliard-de-francs-cfa-pour-violation-des-donnees-personnelles/
- https://pollicy.org/?p=2322
