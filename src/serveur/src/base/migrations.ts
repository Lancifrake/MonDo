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
