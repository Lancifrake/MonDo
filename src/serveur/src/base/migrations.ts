import type { BaseDeDonnees } from "./base-de-donnees.js";

/**
 * Un schéma par module (décision 02). Aucune clé étrangère entre schémas : un module ne connaît
 * les données d'un autre que par identifiant, ce qui permettra d'en extraire un plus tard.
 * Une migration appliquée ne se modifie jamais : on en ajoute une nouvelle.
 */
export const MIGRATIONS: readonly { nom: string; sql: string }[] = [
  {
    nom: "001_comptes",
    sql: `
      CREATE SCHEMA IF NOT EXISTS comptes;
      CREATE TABLE comptes.comptes (
        id uuid PRIMARY KEY,
        numero text NOT NULL UNIQUE,
        nom text NOT NULL,
        niveau smallint NOT NULL CHECK (niveau IN (1, 2)),
        cle_publique jsonb NOT NULL,
        cree_le timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE comptes.signatures_vues (
        signature text PRIMARY KEY,
        expire_le timestamptz NOT NULL
      );`,
  },
  {
    nom: "002_cercles",
    sql: `
      CREATE SCHEMA IF NOT EXISTS cercles;
      CREATE TABLE cercles.cercles (
        id uuid PRIMARY KEY,
        organisateur_id uuid NOT NULL,
        reglement jsonb NOT NULL,
        empreinte_reglement text NOT NULL,
        statut text NOT NULL CHECK (statut IN ('en_attente', 'complet')),
        ordre jsonb,
        cree_le timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE cercles.adhesions (
        cercle_id uuid NOT NULL REFERENCES cercles.cercles (id),
        membre_id uuid NOT NULL,
        rang integer NOT NULL,
        signature text NOT NULL,
        PRIMARY KEY (cercle_id, membre_id),
        UNIQUE (cercle_id, rang)
      );`,
  },
  {
    nom: "003_cotisations",
    sql: `
      CREATE SCHEMA IF NOT EXISTS cotisations;
      CREATE TABLE cotisations.cotisations (
        id uuid PRIMARY KEY,
        cercle_id text NOT NULL,
        payeur_id uuid NOT NULL,
        beneficiaire_id uuid NOT NULL,
        montant bigint NOT NULL CHECK (montant > 0),
        date_limite timestamptz NOT NULL,
        reference_transaction text,
        statut text NOT NULL CHECK (statut IN ('due', 'declaree', 'confirmee'))
      );`,
  },
  {
    nom: "004_score",
    sql: `
      CREATE SCHEMA IF NOT EXISTS score;
      CREATE TABLE score.evenements (
        id bigserial PRIMARY KEY,
        membre_id uuid NOT NULL,
        type text NOT NULL,
        cercle_id text NOT NULL,
        date timestamptz NOT NULL
      );
      CREATE INDEX evenements_membre ON score.evenements (membre_id, id);`,
  },
  {
    nom: "005_planificateur",
    sql: `
      CREATE SCHEMA IF NOT EXISTS planificateur;
      CREATE TABLE planificateur.taches_traitees (
        id text PRIMARY KEY,
        traitee_le timestamptz NOT NULL DEFAULT now()
      );`,
  },
  {
    nom: "006_registre",
    sql: `
      CREATE SCHEMA IF NOT EXISTS registre;
      CREATE TABLE registre.lots (
        id serial PRIMARY KEY,
        racine text NOT NULL,
        reference_inscription text,
        ferme_le timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE registre.empreintes (
        id bigserial PRIMARY KEY,
        empreinte text NOT NULL,
        lot_id integer REFERENCES registre.lots (id)
      );
      CREATE INDEX empreintes_en_attente ON registre.empreintes (id) WHERE lot_id IS NULL;
      CREATE INDEX empreintes_valeur ON registre.empreintes (empreinte);`,
  },
  {
    nom: "007_preuve",
    sql: `
      CREATE SCHEMA IF NOT EXISTS preuve;
      CREATE TABLE preuve.mises_en_demeure (
        id uuid PRIMARY KEY,
        cercle_id uuid NOT NULL,
        membre_id uuid NOT NULL,
        tour integer NOT NULL,
        contenu jsonb NOT NULL,
        empreinte text NOT NULL,
        envoi text NOT NULL,
        emise_le timestamptz NOT NULL,
        UNIQUE (cercle_id, membre_id, tour)
      );`,
  },
  {
    nom: "008_envoi_mises_en_demeure_et_assistant",
    sql: `
      ALTER TABLE preuve.mises_en_demeure ADD COLUMN envoyee_le timestamptz;
      UPDATE preuve.mises_en_demeure SET envoi = 'a_envoyer' WHERE envoi = 'simule';
      ALTER TABLE preuve.mises_en_demeure ADD CONSTRAINT envoi_valide CHECK (envoi IN ('a_envoyer', 'envoyee'));
      CREATE SCHEMA IF NOT EXISTS assistant;
      CREATE TABLE assistant.reglages (
        cercle_id uuid PRIMARY KEY,
        mode text NOT NULL CHECK (mode IN ('autonome', 'manuel'))
      );
      CREATE TABLE assistant.actions (
        id uuid PRIMARY KEY,
        cercle_id uuid NOT NULL,
        type text NOT NULL,
        membre_id uuid NOT NULL,
        issue text NOT NULL CHECK (issue IN ('executee', 'en_attente', 'acceptee', 'refusee', 'hors_reglement')),
        creee_le timestamptz NOT NULL DEFAULT now(),
        tranchee_le timestamptz
      );
      CREATE INDEX actions_cercle ON assistant.actions (cercle_id, creee_le)`,
  },
  {
    nom: "009_codes_otp",
    sql: `
      CREATE TABLE comptes.codes_otp (
        numero text PRIMARY KEY,
        empreinte_code text NOT NULL,
        sel text NOT NULL,
        expire_le timestamptz NOT NULL,
        essais integer NOT NULL,
        consomme boolean NOT NULL,
        cree_le timestamptz NOT NULL
      )`,
  },
  {
    // tour et fin_grace restent vides pour les cotisations créées à la main avant le 05/11 (prototype).
    nom: "010_tours",
    sql: `
      CREATE TABLE cotisations.tours (
        cercle_id text NOT NULL,
        numero integer NOT NULL CHECK (numero > 0),
        beneficiaire_id uuid NOT NULL,
        date_limite timestamptz NOT NULL,
        PRIMARY KEY (cercle_id, numero)
      );
      ALTER TABLE cotisations.cotisations ADD COLUMN tour integer;
      ALTER TABLE cotisations.cotisations ADD COLUMN fin_grace timestamptz;
      CREATE UNIQUE INDEX cotisation_par_tour ON cotisations.cotisations (cercle_id, tour, payeur_id)`,
  },
  {
    // Litige sur un paiement déclaré non confirmé (choix de David, 05/11). Un seul litige ouvert par cotisation.
    nom: "011_litiges",
    sql: `
      ALTER TABLE cotisations.cotisations ADD COLUMN declaree_le timestamptz;
      CREATE SCHEMA IF NOT EXISTS litiges;
      CREATE TABLE litiges.litiges (
        id uuid PRIMARY KEY,
        cotisation_id uuid NOT NULL,
        cercle_id text NOT NULL,
        payeur_id uuid NOT NULL,
        beneficiaire_id uuid NOT NULL,
        ouvert_par text NOT NULL CHECK (ouvert_par IN ('payeur', 'beneficiaire', 'automatique')),
        motif text NOT NULL,
        ouvert_le timestamptz NOT NULL,
        statut text NOT NULL CHECK (statut IN ('ouvert', 'tranche', 'clos')),
        decision text CHECK (decision IN ('paiement_valide', 'paiement_refuse', 'confirme_par_beneficiaire')),
        motif_decision text,
        tranche_par uuid,
        tranche_le timestamptz
      );
      CREATE UNIQUE INDEX litige_ouvert_par_cotisation ON litiges.litiges (cotisation_id) WHERE statut = 'ouvert'`,
  },
  {
    // File d'envoi des SMS (décision 02, règle 4) : une panne de la passerelle ne bloque rien.
    nom: "012_file_sms",
    sql: `
      CREATE SCHEMA IF NOT EXISTS sms;
      CREATE TABLE sms.envois (
        id uuid PRIMARY KEY,
        cle text NOT NULL UNIQUE,
        numero text NOT NULL,
        texte text NOT NULL,
        statut text NOT NULL CHECK (statut IN ('a_envoyer', 'en_cours', 'envoye', 'echec')),
        tentatives integer NOT NULL DEFAULT 0,
        derniere_erreur text,
        cree_le timestamptz NOT NULL DEFAULT now(),
        reserve_le timestamptz,
        envoye_le timestamptz
      );
      CREATE INDEX envois_a_faire ON sms.envois (cree_le) WHERE statut IN ('a_envoyer', 'en_cours')`,
  },
  {
    // Cotisation visée par un rappel de l'assistant, pour rédiger le SMS au moment de l'envoi.
    nom: "013_cotisation_des_actions",
    sql: `ALTER TABLE assistant.actions ADD COLUMN cotisation_id uuid`,
  },
  {
    // Cercle terminé à la fin de grâce du dernier tour (choix de David, 05/11).
    nom: "014_cercle_termine",
    sql: `
      ALTER TABLE cercles.cercles DROP CONSTRAINT cercles_statut_check;
      ALTER TABLE cercles.cercles ADD CONSTRAINT cercles_statut_check
        CHECK (statut IN ('en_attente', 'complet', 'termine'));
      ALTER TABLE cercles.cercles ADD COLUMN termine_le timestamptz`,
  },
  {
    // Anti-rejeu sur l'empreinte du message signé, plus sur le texte de la signature : une même signature
    // s'écrit de plusieurs façons (padding base64, malléabilité ECDSA), le message signé d'une seule.
    nom: "015_requetes_vues",
    sql: `
      DROP TABLE comptes.signatures_vues;
      CREATE TABLE comptes.requetes_vues (
        empreinte text PRIMARY KEY,
        expire_le timestamptz NOT NULL
      )`,
  },
  {
    // Plafond de codes SMS par numéro sur 24 h (fraude au SMS, harcèlement d'un numéro).
    nom: "016_plafond_otp",
    sql: `
      ALTER TABLE comptes.codes_otp ADD COLUMN envois integer NOT NULL DEFAULT 1;
      ALTER TABLE comptes.codes_otp ADD COLUMN fenetre_debut timestamptz;
      UPDATE comptes.codes_otp SET fenetre_debut = cree_le;
      ALTER TABLE comptes.codes_otp ALTER COLUMN fenetre_debut SET NOT NULL`,
  },
  {
    // Déclaration gelée pendant un litige ouvert (choix de David, 06/11) : posé par Litiges, levé à la décision.
    nom: "017_cotisation_en_litige",
    sql: `ALTER TABLE cotisations.cotisations ADD COLUMN en_litige boolean NOT NULL DEFAULT false`,
  },
  {
    // Score visible par soi et les membres d'un cercle commun (choix de David, 06/11). Le module Score tient
    // sa propre copie des adhésions (événement adhesion_enregistree) ; reprise unique des adhésions existantes.
    nom: "018_score_membres_cercles",
    sql: `
      CREATE TABLE score.membres_cercles (
        cercle_id uuid NOT NULL,
        membre_id uuid NOT NULL,
        PRIMARY KEY (cercle_id, membre_id)
      );
      CREATE INDEX membres_cercles_membre ON score.membres_cercles (membre_id);
      INSERT INTO score.membres_cercles (cercle_id, membre_id) SELECT cercle_id, membre_id FROM cercles.adhesions`,
  },
  {
    // Choix de la place (choix de David, 08/11) : place souhaitée, signée dans l'engagement. Vide pour les
    // adhésions d'avant : ces cercles gardent l'ordre par score.
    nom: "019_place_souhaitee",
    sql: `ALTER TABLE cercles.adhesions ADD COLUMN place_souhaitee integer`,
  },
  {
    // Contact de confiance (flow 1) : un par compte, accord par un code envoyé au contact, gardé haché.
    nom: "020_contact_confiance",
    sql: `
      CREATE TABLE comptes.contacts_confiance (
        compte_id uuid PRIMARY KEY REFERENCES comptes.comptes (id),
        nom text NOT NULL,
        numero text NOT NULL,
        empreinte_code text NOT NULL,
        sel text NOT NULL,
        essais integer NOT NULL,
        expire_le timestamptz NOT NULL,
        demande_le timestamptz NOT NULL,
        consentement_le timestamptz,
        designations integer NOT NULL,
        fenetre_debut timestamptz NOT NULL
      )`,
  },
  {
    // Vérification d'identité interne (choix de David, 11/11). Les images sont dans le stockage d'objets
    // chiffré : la base ne garde que la clé de stockage et une empreinte. Un seul dossier en attente par compte.
    nom: "021_verification_identite",
    sql: `
      CREATE TABLE comptes.verifications_identite (
        id uuid PRIMARY KEY,
        compte_id uuid NOT NULL REFERENCES comptes.comptes (id),
        type_piece text NOT NULL,
        consentement_le timestamptz NOT NULL,
        version_consentement text NOT NULL,
        deposee_le timestamptz NOT NULL,
        statut text NOT NULL CHECK (statut IN ('en_attente', 'validee', 'refusee')),
        motif_decision text,
        decidee_par uuid,
        decidee_le timestamptz,
        dernier_cercle_termine_le timestamptz
      );
      CREATE UNIQUE INDEX verification_en_attente ON comptes.verifications_identite (compte_id)
        WHERE statut = 'en_attente';
      CREATE INDEX verifications_compte ON comptes.verifications_identite (compte_id, deposee_le);
      CREATE TABLE comptes.pieces_identite (
        verification_id uuid NOT NULL REFERENCES comptes.verifications_identite (id),
        nature text NOT NULL CHECK (nature IN ('recto', 'verso', 'selfie')),
        cle_stockage text NOT NULL,
        empreinte text NOT NULL,
        supprimee_le timestamptz,
        PRIMARY KEY (verification_id, nature)
      );
      CREATE TABLE comptes.acces_pieces (
        id bigserial PRIMARY KEY,
        verification_id uuid NOT NULL,
        nature text NOT NULL,
        administrateur_id uuid NOT NULL,
        consultee_le timestamptz NOT NULL DEFAULT now()
      )`,
  },
  {
    // Récupération de compte (flow 2) et compte bloqué (règle du 03/11). Une seule récupération en cours et
    // un seul blocage en cours par compte. Les clés remplacées sont gardées : les signatures passées restent
    // vérifiables. Les pièces d'une récupération sans contact passent par la même file que le niveau 2.
    nom: "022_recuperation_et_blocage",
    sql: `
      CREATE TABLE comptes.codes_secrets (
        compte_id uuid PRIMARY KEY REFERENCES comptes.comptes (id),
        empreinte text NOT NULL,
        sel text NOT NULL,
        echecs integer NOT NULL,
        fenetre_debut timestamptz
      );
      CREATE TABLE comptes.recuperations (
        id uuid PRIMARY KEY,
        compte_id uuid NOT NULL REFERENCES comptes.comptes (id),
        nouvelle_cle jsonb NOT NULL,
        demandee_le timestamptz NOT NULL,
        fin_delai_le timestamptz NOT NULL,
        avec_contact boolean NOT NULL,
        statut text NOT NULL CHECK (statut IN ('en_attente', 'opposee', 'acceptee', 'refusee', 'expiree')),
        decidee_par uuid,
        motif_decision text,
        close_le timestamptz
      );
      CREATE UNIQUE INDEX recuperation_en_cours ON comptes.recuperations (compte_id)
        WHERE statut IN ('en_attente', 'opposee');
      CREATE TABLE comptes.blocages (
        id uuid PRIMARY KEY,
        compte_id uuid NOT NULL REFERENCES comptes.comptes (id),
        motif text NOT NULL CHECK (motif IN ('essais_rates', 'opposition')),
        bloque_le timestamptz NOT NULL,
        fin_le timestamptz,
        leve_le timestamptz
      );
      CREATE UNIQUE INDEX blocage_en_cours ON comptes.blocages (compte_id) WHERE leve_le IS NULL;
      CREATE TABLE comptes.cles_revoquees (
        id bigserial PRIMARY KEY,
        compte_id uuid NOT NULL REFERENCES comptes.comptes (id),
        cle_publique jsonb NOT NULL,
        revoquee_le timestamptz NOT NULL
      );
      ALTER TABLE comptes.verifications_identite ADD COLUMN motif text NOT NULL DEFAULT 'niveau2'
        CHECK (motif IN ('niveau2', 'recuperation'));
      ALTER TABLE comptes.verifications_identite ADD COLUMN recuperation_id uuid;
      DROP INDEX comptes.verification_en_attente;
      CREATE UNIQUE INDEX verification_en_attente ON comptes.verifications_identite (compte_id, motif)
        WHERE statut = 'en_attente'`,
  },
  {
    // Sommes dues hors cotisations (choix de David, 11/11) : part de MonDo et remises du modèle A, puis
    // remboursements après un départ. Suivies comme une cotisation. creancier_id vide : la somme revient à MonDo.
    nom: "023_sommes_dues",
    sql: `
      CREATE TABLE cotisations.sommes_dues (
        id uuid PRIMARY KEY,
        cercle_id text NOT NULL,
        nature text NOT NULL CHECK (nature IN ('frais_mondo', 'remise', 'remboursement_depart')),
        debiteur_id uuid NOT NULL,
        creancier_id uuid,
        montant bigint NOT NULL CHECK (montant > 0),
        tour integer NOT NULL,
        exigible_le timestamptz NOT NULL,
        date_limite timestamptz NOT NULL,
        reference_transaction text,
        declaree_le timestamptz,
        confirmee_le timestamptz,
        origine_id uuid,
        statut text NOT NULL CHECK (statut IN ('due', 'declaree', 'confirmee', 'annulee'))
      );
      CREATE INDEX sommes_dues_debiteur ON cotisations.sommes_dues (debiteur_id);
      CREATE INDEX sommes_dues_creancier ON cotisations.sommes_dues (creancier_id);
      CREATE INDEX sommes_dues_cercle ON cotisations.sommes_dues (cercle_id)`,
  },
  {
    // Pénalité de retard due au bénéficiaire du tour (choix de David, 11/11) : montant du règlement copié sur
    // chaque cotisation, due une fois, à la fin de grâce. Reprise unique du montant pour les cercles existants.
    nom: "024_penalite_au_beneficiaire",
    sql: `
      ALTER TABLE cotisations.cotisations ADD COLUMN penalite bigint NOT NULL DEFAULT 0;
      ALTER TABLE cotisations.cotisations ADD COLUMN penalite_due_le timestamptz;
      UPDATE cotisations.cotisations c SET penalite = (x.reglement->>'penaliteRetard')::bigint
        FROM cercles.cercles x WHERE x.id::text = c.cercle_id AND c.tour > 0`,
  },
  {
    // Départ en cours de cycle (choix de David, 11/11) : cotisations annulées, départ tracé dans chaque module.
    nom: "025_depart",
    sql: `
      ALTER TABLE cotisations.cotisations DROP CONSTRAINT cotisations_statut_check;
      ALTER TABLE cotisations.cotisations ADD CONSTRAINT cotisations_statut_check
        CHECK (statut IN ('due', 'declaree', 'confirmee', 'annulee'));
      CREATE TABLE cotisations.departs (
        cercle_id text NOT NULL,
        membre_id uuid NOT NULL,
        parti_le timestamptz NOT NULL,
        PRIMARY KEY (cercle_id, membre_id)
      );
      ALTER TABLE cercles.adhesions ADD COLUMN parti_le timestamptz`,
  },
  {
    // Cercles privés à moitié de points (choix de David, 11/11). Le module Score retient quels cercles sont
    // privés (événement adhesion_enregistree) et marque chaque événement. Reprise unique de l'existant.
    nom: "026_score_cercles_prives",
    sql: `
      CREATE TABLE score.cercles (
        cercle_id uuid PRIMARY KEY,
        prive boolean NOT NULL
      );
      INSERT INTO score.cercles (cercle_id, prive)
        SELECT id, COALESCE(reglement->>'ouvert', 'false') <> 'true' FROM cercles.cercles;
      ALTER TABLE score.evenements ADD COLUMN cercle_prive boolean NOT NULL DEFAULT false;
      UPDATE score.evenements e SET cercle_prive = true
        FROM score.cercles c WHERE c.cercle_id::text = e.cercle_id AND c.prive`,
  },
  {
    // Échange de places après complétion (choix de David, 11/11) : signé par les deux, expire à 48 h.
    // Une seule proposition en cours par demandeur et par cercle.
    nom: "027_echanges_de_places",
    sql: `
      CREATE TABLE cercles.echanges (
        id uuid PRIMARY KEY,
        cercle_id uuid NOT NULL REFERENCES cercles.cercles (id),
        demandeur_id uuid NOT NULL,
        cedant_id uuid NOT NULL,
        place_demandeur integer NOT NULL,
        place_cedant integer NOT NULL,
        signature_demandeur text NOT NULL,
        signature_cedant text,
        propose_le timestamptz NOT NULL,
        expire_le timestamptz NOT NULL,
        conclu_le timestamptz,
        statut text NOT NULL CHECK (statut IN ('propose', 'signe', 'refuse', 'expire'))
      );
      CREATE UNIQUE INDEX echange_en_cours ON cercles.echanges (cercle_id, demandeur_id) WHERE statut = 'propose';
      CREATE INDEX echanges_cedant ON cercles.echanges (cercle_id, cedant_id)`,
  },
  {
    // Registre lisible par cercle (cahier des charges, M10) : type de l'événement et cercle concerné, à côté de
    // l'empreinte. Aucune donnée personnelle. Les empreintes d'avant restent sans cercle.
    nom: "028_registre_par_cercle",
    sql: `
      ALTER TABLE registre.empreintes ADD COLUMN objet text;
      ALTER TABLE registre.empreintes ADD COLUMN cercle_id uuid;
      ALTER TABLE registre.empreintes ADD COLUMN enregistree_le timestamptz NOT NULL DEFAULT now();
      CREATE INDEX empreintes_cercle ON registre.empreintes (cercle_id, id)`,
  },
  {
    // Invitations par numéro (US4) : on garde l'empreinte du numéro, salée par le cercle, jamais le numéro.
    nom: "029_invitations",
    sql: `
      CREATE TABLE cercles.invitations (
        cercle_id uuid NOT NULL REFERENCES cercles.cercles (id),
        empreinte_numero text NOT NULL,
        invitee_le timestamptz NOT NULL DEFAULT now(),
        PRIMARY KEY (cercle_id, empreinte_numero)
      )`,
  },
  {
    // Cycle suivant (cahier des charges, M2 et S3) : un cercle terminé relancé par son organisateur.
    nom: "030_cycle_suivant",
    sql: `ALTER TABLE cercles.cercles ADD COLUMN cercle_precedent_id uuid REFERENCES cercles.cercles (id)`,
  },
  {
    // Paiements Mobile Money simulés (cahier des charges, M4) : une seule tentative en attente par cotisation.
    nom: "031_paiements_simules",
    sql: `
      CREATE TABLE cotisations.paiements_simules (
        id uuid PRIMARY KEY,
        cotisation_id uuid NOT NULL,
        payeur_id uuid NOT NULL,
        operateur text NOT NULL CHECK (operateur IN ('orange_money', 'mtn_momo')),
        issue text NOT NULL CHECK (issue IN ('reussi', 'echoue', 'en_retard')),
        statut text NOT NULL CHECK (statut IN ('en_attente_operateur', 'reussi', 'echoue')),
        reference_operateur text,
        motif text,
        initie_le timestamptz NOT NULL,
        retour_prevu_le timestamptz NOT NULL,
        retour_le timestamptz
      );
      CREATE UNIQUE INDEX paiement_en_attente ON cotisations.paiements_simules (cotisation_id)
        WHERE statut = 'en_attente_operateur';
      CREATE INDEX paiements_a_traiter ON cotisations.paiements_simules (retour_prevu_le)
        WHERE statut = 'en_attente_operateur'`,
  },
  {
    // Notifications dans l'application (cahier des charges, M5) : chaque message adressé à un membre.
    nom: "032_notifications",
    sql: `
      CREATE TABLE sms.notifications (
        id uuid PRIMARY KEY,
        cle text NOT NULL UNIQUE,
        membre_id uuid NOT NULL,
        texte text NOT NULL,
        creee_le timestamptz NOT NULL DEFAULT now(),
        lue_le timestamptz
      );
      CREATE INDEX notifications_membre ON sms.notifications (membre_id, creee_le DESC)`,
  },
  {
    // Parrainage (US6) : un parrain accepté par filleul, une proposition en cours par couple.
    nom: "033_parrainages",
    sql: `
      CREATE TABLE comptes.parrainages (
        id uuid PRIMARY KEY,
        parrain_id uuid NOT NULL REFERENCES comptes.comptes (id),
        filleul_id uuid NOT NULL REFERENCES comptes.comptes (id),
        statut text NOT NULL CHECK (statut IN ('propose', 'accepte', 'refuse')),
        propose_le timestamptz NOT NULL,
        repondu_le timestamptz,
        CHECK (parrain_id <> filleul_id)
      );
      CREATE UNIQUE INDEX un_parrain_par_filleul ON comptes.parrainages (filleul_id) WHERE statut = 'accepte';
      CREATE UNIQUE INDEX une_proposition_par_couple ON comptes.parrainages (parrain_id, filleul_id)
        WHERE statut = 'propose';
      CREATE INDEX parrainages_parrain ON comptes.parrainages (parrain_id)`,
  },
];

export async function migrer(base: BaseDeDonnees): Promise<void> {
  await base.executerScript(
    "CREATE TABLE IF NOT EXISTS public.migrations (nom text PRIMARY KEY, appliquee_le timestamptz NOT NULL DEFAULT now())",
  );
  const appliquees = new Set(
    (await base.requete<{ nom: string }>("SELECT nom FROM public.migrations")).map((l) => l.nom),
  );
  for (const m of MIGRATIONS) {
    if (appliquees.has(m.nom)) continue;
    await base.transaction(async (tx) => {
      for (const instruction of m.sql
        .split(";")
        .map((s) => s.trim())
        .filter(Boolean))
        await tx.requete(instruction);
      await tx.requete("INSERT INTO public.migrations (nom) VALUES ($1)", [m.nom]);
    });
  }
}
