import { ForbiddenException, Inject, Injectable } from "@nestjs/common";
import { estAdministrateur, identifiantsAdministrateurs } from "../../administration/administrateurs.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { RegistreService } from "../../registre/registre.service.js";
import { FileSms } from "../../sms/file-sms.js";

/** Un compte vu par l'Administrateur. Aucune pièce d'identité, aucune clé : seulement de quoi s'y retrouver. */
export interface CompteListe {
  id: string;
  nom: string;
  numero: string;
  /** 1 : identité non vérifiée ; 2 : pièce d'identité validée. */
  niveau: 1 | 2;
  creeLe: string;
  /** Cercles où le compte est membre et n'est pas parti. */
  cerclesActifs: number;
  /** Blocage en cours (essais de code secret ratés, ou opposition à une récupération). */
  blocage: { motif: "essais_rates" | "opposition"; bloqueLe: string } | null;
  /** Une pièce d'identité attend la décision d'un Administrateur. */
  verificationEnAttente: boolean;
  /** Ce compte est dans la liste des administrateurs : il gère la plateforme, il n'est pas un utilisateur. */
  administrateur: boolean;
}

/** Un cercle vu par l'Administrateur. Un cercle n'a pas de nom : on le reconnaît à son organisateur et à son montant. */
export interface CercleListe {
  id: string;
  statut: "en_attente" | "complet" | "termine";
  creeLe: string;
  termineLe: string | null;
  organisateur: { nom: string; numero: string } | null;
  reglement: { montant: number; frequence: string; periodeJours: number | null; nombreMembres: number };
  /** Membres inscrits qui ne sont pas partis. */
  membres: number;
  /** Tours qui ont des cotisations, toutes confirmées, sur le nombre de tours du cercle. */
  toursTermines: number;
  toursTotal: number;
  litigesOuverts: number;
}

/** Un indicateur : sa valeur, ce qu'il a gagné sur 30 jours, et un point par jour sur 30 jours (le plus récent en dernier). */
export interface Indicateur {
  valeur: number;
  derniers30Jours: number;
  serie: number[];
}

export interface TableauDeBord {
  comptes: Indicateur & { verifies: number };
  cercles: Indicateur & { enCours: number; enAttente: number; termines: number };
  /** Cotisations confirmées, en FCFA. */
  cotisations: Indicateur;
  identitesEnAttente: Indicateur;
  litiges: Indicateur & { ouverts: number };
  defauts: Indicateur & { aEnvoyer: number };
  /** Cotisations confirmées par mois, les six derniers mois, en FCFA. */
  volumeParMois: { mois: string; montant: number }[];
  /** Ce qui attend une décision de l'administrateur : alimente les compteurs du menu. */
  aTraiter: { litiges: number; recuperations: number; identites: number; sommesDues: number; defauts: number };
  /** Derniers événements inscrits au registre : un type, un cercle, une date, jamais de donnée personnelle. */
  activite: { objet: string; cercleId: string | null; enregistreLe: string }[];
}

export interface EvenementJournal {
  id: number;
  objet: string;
  empreinte: string;
  enregistreLe: string;
  cercle: { id: string; organisateur: string | null } | null;
  /** en_attente : pas encore dans un lot ; non_inscrite : lot figé, racine pas sur la chaîne ; inscrite : sur la chaîne. */
  statut: "en_attente" | "non_inscrite" | "inscrite";
  /** Le lot qui contient l'empreinte : sa racine et la référence de l'inscription (transaction, ou « simule-n »). Absent tant que l'empreinte attend. */
  lot: { id: number; racine: string; referenceInscription: string | null; fermeLe: string } | null;
}

export interface SanteSysteme {
  base: "ok";
  environnement: string;
  /** Vrai : le connecteur est un simulateur de développement, rien ne part vraiment. */
  simules: { sms: boolean; registre: boolean };
  sms: { enFile: number; echecs: number; plusAncienneLe: string | null; envoyes24h: number };
  registre: {
    empreintes: number;
    empreintesEnAttente: number;
    plusAncienneEnAttenteLe: string | null;
    lots: number;
    dernierLotLe: string | null;
  };
}

@Injectable()
export class AdministrationService {
  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(RegistreService) private readonly registre: RegistreService,
    @Inject(FileSms) private readonly sms: FileSms,
  ) {}

  /**
   * Un point par jour sur 30 jours. `table`, `colonne`, `agregat` et `filtre` sont des constantes de ce fichier,
   * jamais une valeur venue d'une requête.
   */
  private async serie(
    table: string,
    colonne: string,
    agregat: string,
    filtre = "true",
    parametres: unknown[] = [],
  ): Promise<number[]> {
    const lignes = await this.base.requete<{ v: string | number }>(
      `SELECT coalesce(${agregat}, 0) AS v
       FROM generate_series(current_date - 29, current_date, interval '1 day') g(jour)
       LEFT JOIN ${table} t ON t.${colonne}::date = g.jour::date AND ${filtre}
       GROUP BY g.jour ORDER BY g.jour`,
      parametres,
    );
    return lignes.map((l) => Number(l.v));
  }

  private async nombre(sql: string, parametres: unknown[] = []): Promise<number> {
    const [l] = await this.base.requete<{ n: string | number | null }>(sql, parametres);
    return Number(l?.n ?? 0);
  }

  private exigerAdministrateur(membreId: string): void {
    if (!estAdministrateur(membreId)) throw new ForbiddenException("Réservé à l'administrateur");
  }

  /** Tous les comptes, du plus récent au plus ancien. Lecture seule. */
  async listerComptes(parMembreId: string): Promise<CompteListe[]> {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<{
      id: string;
      nom: string;
      numero: string;
      niveau: number;
      cree_le: Date | string;
      cercles_actifs: string | number;
      blocage_motif: CompteListe["blocage"] extends infer B ? (B extends { motif: infer M } ? M : never) : never;
      blocage_le: Date | string | null;
      verification: boolean;
    }>(
      `SELECT c.id, c.nom, c.numero, c.niveau, c.cree_le,
              (SELECT count(*) FROM cercles.adhesions a WHERE a.membre_id = c.id AND a.parti_le IS NULL) AS cercles_actifs,
              b.motif AS blocage_motif, b.bloque_le AS blocage_le,
              EXISTS (SELECT 1 FROM comptes.verifications_identite v WHERE v.compte_id = c.id AND v.statut = 'en_attente') AS verification
       FROM comptes.comptes c
       LEFT JOIN comptes.blocages b ON b.compte_id = c.id AND b.leve_le IS NULL
       ORDER BY c.cree_le DESC, c.id`,
    );
    return lignes.map((l) => ({
      id: l.id,
      nom: l.nom,
      numero: l.numero,
      niveau: l.niveau === 2 ? 2 : 1,
      creeLe: new Date(l.cree_le).toISOString(),
      cerclesActifs: Number(l.cercles_actifs),
      blocage: l.blocage_le ? { motif: l.blocage_motif, bloqueLe: new Date(l.blocage_le).toISOString() } : null,
      verificationEnAttente: l.verification,
      administrateur: estAdministrateur(l.id),
    }));
  }

  /** Tous les cercles, du plus récent au plus ancien. Lecture seule : ni membres ni ordre, réservés aux membres. */
  async listerCercles(parMembreId: string): Promise<CercleListe[]> {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<{
      id: string;
      statut: CercleListe["statut"];
      cree_le: Date | string;
      termine_le: Date | string | null;
      organisateur_nom: string | null;
      organisateur_numero: string | null;
      montant: string | number;
      frequence: string;
      periode_jours: number | null;
      nombre_membres: number;
      membres: string | number;
      tours_termines: string | number;
      litiges_ouverts: string | number;
    }>(
      `SELECT c.id, c.statut, c.cree_le, c.termine_le, o.nom AS organisateur_nom, o.numero AS organisateur_numero,
              (c.reglement ->> 'montant')::bigint AS montant, c.reglement ->> 'frequence' AS frequence,
              (c.reglement ->> 'periodeJours')::int AS periode_jours, (c.reglement ->> 'nombreMembres')::int AS nombre_membres,
              (SELECT count(*) FROM cercles.adhesions a WHERE a.cercle_id = c.id AND a.parti_le IS NULL) AS membres,
              (SELECT count(*) FROM cotisations.tours t WHERE t.cercle_id = c.id::text AND EXISTS (
                 SELECT 1 FROM cotisations.cotisations k
                 WHERE k.cercle_id = t.cercle_id AND k.tour = t.numero) AND NOT EXISTS (
                 SELECT 1 FROM cotisations.cotisations k
                 WHERE k.cercle_id = t.cercle_id AND k.tour = t.numero AND k.statut <> 'confirmee')) AS tours_termines,
              (SELECT count(*) FROM litiges.litiges l WHERE l.cercle_id = c.id::text AND l.statut = 'ouvert') AS litiges_ouverts
       FROM cercles.cercles c
       LEFT JOIN comptes.comptes o ON o.id = c.organisateur_id
       ORDER BY c.cree_le DESC, c.id`,
    );
    return lignes.map((l) => ({
      id: l.id,
      statut: l.statut,
      creeLe: new Date(l.cree_le).toISOString(),
      termineLe: l.termine_le ? new Date(l.termine_le).toISOString() : null,
      organisateur: l.organisateur_nom ? { nom: l.organisateur_nom, numero: l.organisateur_numero ?? "" } : null,
      reglement: {
        montant: Number(l.montant),
        frequence: l.frequence,
        periodeJours: l.periode_jours,
        nombreMembres: l.nombre_membres,
      },
      membres: Number(l.membres),
      toursTermines: Number(l.tours_termines),
      toursTotal: l.nombre_membres,
      litigesOuverts: Number(l.litiges_ouverts),
    }));
  }

  /** Chiffres de la plateforme pour la page d'accueil de l'administration. Aucune donnée personnelle. */
  async tableauDeBord(parMembreId: string): Promise<TableauDeBord> {
    this.exigerAdministrateur(parMembreId);
    const il30 = "now() - interval '30 days'";
    // Les administrateurs gèrent la plateforme : ils ne comptent pas parmi les utilisateurs.
    const admins = [identifiantsAdministrateurs()];
    const [comptes, verifies, comptes30, cercles, enCours, enAttente, termines, cercles30] = await Promise.all([
      this.nombre("SELECT count(*) AS n FROM comptes.comptes WHERE id <> ALL($1::uuid[])", admins),
      this.nombre("SELECT count(*) AS n FROM comptes.comptes WHERE niveau = 2 AND id <> ALL($1::uuid[])", admins),
      this.nombre(
        `SELECT count(*) AS n FROM comptes.comptes WHERE cree_le >= ${il30} AND id <> ALL($1::uuid[])`,
        admins,
      ),
      this.nombre("SELECT count(*) AS n FROM cercles.cercles"),
      this.nombre("SELECT count(*) AS n FROM cercles.cercles WHERE statut = 'complet'"),
      this.nombre("SELECT count(*) AS n FROM cercles.cercles WHERE statut = 'en_attente'"),
      this.nombre("SELECT count(*) AS n FROM cercles.cercles WHERE statut = 'termine'"),
      this.nombre(`SELECT count(*) AS n FROM cercles.cercles WHERE cree_le >= ${il30}`),
    ]);
    const [montant, montant30, identites, identites30, litigesTous, litiges30, litigesOuverts] = await Promise.all([
      this.nombre("SELECT sum(montant) AS n FROM cotisations.cotisations WHERE statut = 'confirmee'"),
      this.nombre(
        `SELECT sum(montant) AS n FROM cotisations.cotisations WHERE statut = 'confirmee' AND date_limite >= ${il30}`,
      ),
      this.nombre("SELECT count(*) AS n FROM comptes.verifications_identite WHERE statut = 'en_attente'"),
      this.nombre(`SELECT count(*) AS n FROM comptes.verifications_identite WHERE deposee_le >= ${il30}`),
      this.nombre("SELECT count(*) AS n FROM litiges.litiges"),
      this.nombre(`SELECT count(*) AS n FROM litiges.litiges WHERE ouvert_le >= ${il30}`),
      this.nombre("SELECT count(*) AS n FROM litiges.litiges WHERE statut = 'ouvert'"),
    ]);
    const [defauts, aEnvoyer, defauts30, recuperations, sommesDues] = await Promise.all([
      this.nombre("SELECT count(*) AS n FROM preuve.mises_en_demeure"),
      this.nombre("SELECT count(*) AS n FROM preuve.mises_en_demeure WHERE envoi = 'a_envoyer'"),
      this.nombre(`SELECT count(*) AS n FROM preuve.mises_en_demeure WHERE emise_le >= ${il30}`),
      this.nombre("SELECT count(*) AS n FROM comptes.recuperations WHERE statut = 'opposee'"),
      this.nombre(
        "SELECT count(*) AS n FROM cotisations.sommes_dues WHERE creancier_id IS NULL AND statut = 'declaree'",
      ),
    ]);
    const [serieComptes, serieCercles, serieMontant, serieIdentites, serieLitiges, serieDefauts] = await Promise.all([
      this.serie("comptes.comptes", "cree_le", "count(t.id)", "t.id <> ALL($1::uuid[])", admins),
      this.serie("cercles.cercles", "cree_le", "count(t.id)"),
      this.serie("cotisations.cotisations", "date_limite", "sum(t.montant)", "t.statut = 'confirmee'"),
      this.serie("comptes.verifications_identite", "deposee_le", "count(t.id)"),
      this.serie("litiges.litiges", "ouvert_le", "count(t.id)"),
      this.serie("preuve.mises_en_demeure", "emise_le", "count(t.id)"),
    ]);
    const mois = await this.base.requete<{ mois: string; montant: string | number }>(
      `SELECT to_char(g.m, 'YYYY-MM') AS mois, coalesce(sum(k.montant), 0) AS montant
       FROM generate_series(date_trunc('month', now()) - interval '5 months', date_trunc('month', now()), interval '1 month') g(m)
       LEFT JOIN cotisations.cotisations k ON date_trunc('month', k.date_limite) = g.m AND k.statut = 'confirmee'
       GROUP BY g.m ORDER BY g.m`,
    );
    const activite = await this.base.requete<{
      objet: string | null;
      cercle_id: string | null;
      enregistree_le: Date | string;
    }>("SELECT objet, cercle_id, enregistree_le FROM registre.empreintes ORDER BY id DESC LIMIT 6");
    return {
      comptes: { valeur: comptes, derniers30Jours: comptes30, serie: serieComptes, verifies },
      cercles: { valeur: cercles, derniers30Jours: cercles30, serie: serieCercles, enCours, enAttente, termines },
      cotisations: { valeur: montant, derniers30Jours: montant30, serie: serieMontant },
      identitesEnAttente: { valeur: identites, derniers30Jours: identites30, serie: serieIdentites },
      litiges: { valeur: litigesTous, derniers30Jours: litiges30, serie: serieLitiges, ouverts: litigesOuverts },
      defauts: { valeur: defauts, derniers30Jours: defauts30, serie: serieDefauts, aEnvoyer },
      volumeParMois: mois.map((m) => ({ mois: m.mois, montant: Number(m.montant) })),
      aTraiter: { litiges: litigesOuverts, recuperations, identites, sommesDues, defauts: aEnvoyer },
      activite: activite.map((a) => ({
        objet: a.objet ?? "evenement",
        cercleId: a.cercle_id,
        enregistreLe: new Date(a.enregistree_le).toISOString(),
      })),
    };
  }

  /** Événements du registre, du plus récent au plus ancien. Des empreintes : jamais de contenu ni de nom. */
  async journal(parMembreId: string, limite = 100): Promise<EvenementJournal[]> {
    this.exigerAdministrateur(parMembreId);
    const lignes = await this.base.requete<{
      id: string | number;
      objet: string | null;
      empreinte: string;
      enregistree_le: Date | string;
      lot_id: number | null;
      racine: string | null;
      reference_inscription: string | null;
      ferme_le: Date | string | null;
      cercle_id: string | null;
      organisateur_nom: string | null;
    }>(
      `SELECT e.id, e.objet, e.empreinte, e.enregistree_le, e.lot_id, l.racine, l.reference_inscription, l.ferme_le, e.cercle_id, o.nom AS organisateur_nom
       FROM registre.empreintes e
       LEFT JOIN registre.lots l ON l.id = e.lot_id
       LEFT JOIN cercles.cercles c ON c.id = e.cercle_id
       LEFT JOIN comptes.comptes o ON o.id = c.organisateur_id
       ORDER BY e.id DESC LIMIT $1`,
      [limite],
    );
    return lignes.map((l) => ({
      id: Number(l.id),
      objet: l.objet ?? "evenement",
      empreinte: l.empreinte,
      enregistreLe: new Date(l.enregistree_le).toISOString(),
      cercle: l.cercle_id ? { id: l.cercle_id, organisateur: l.organisateur_nom } : null,
      statut: l.lot_id === null ? "en_attente" : l.reference_inscription ? "inscrite" : "non_inscrite",
      lot:
        l.lot_id === null || l.racine === null || l.ferme_le === null
          ? null
          : {
              id: l.lot_id,
              racine: l.racine,
              referenceInscription: l.reference_inscription,
              fermeLe: new Date(l.ferme_le).toISOString(),
            },
    }));
  }

  /** Contrôle l'intégrité de tous les lots du registre. */
  verifierRegistre(parMembreId: string) {
    this.exigerAdministrateur(parMembreId);
    return this.registre.verifierTout();
  }

  /** Santé réelle : la base répond (sinon cette requête échoue), la file SMS, le registre, et ce qui est simulé. */
  async sante(parMembreId: string): Promise<SanteSysteme> {
    this.exigerAdministrateur(parMembreId);
    await this.base.requete("SELECT 1");
    const [sms] = await this.base.requete<{
      en_file: string | number;
      echecs: string | number;
      plus_ancienne: Date | string | null;
      envoyes: string | number;
    }>(
      `SELECT count(*) FILTER (WHERE statut IN ('a_envoyer', 'en_cours')) AS en_file,
              count(*) FILTER (WHERE statut = 'echec') AS echecs,
              min(cree_le) FILTER (WHERE statut IN ('a_envoyer', 'en_cours')) AS plus_ancienne,
              count(*) FILTER (WHERE statut = 'envoye' AND envoye_le >= now() - interval '24 hours') AS envoyes
       FROM sms.envois`,
    );
    const [reg] = await this.base.requete<{
      empreintes: string | number;
      en_attente: string | number;
      plus_ancienne: Date | string | null;
    }>(
      `SELECT count(*) AS empreintes, count(*) FILTER (WHERE lot_id IS NULL) AS en_attente,
              min(enregistree_le) FILTER (WHERE lot_id IS NULL) AS plus_ancienne
       FROM registre.empreintes`,
    );
    const [lots] = await this.base.requete<{ n: string | number; dernier: Date | string | null }>(
      "SELECT count(*) AS n, max(ferme_le) AS dernier FROM registre.lots",
    );
    const iso = (d: Date | string | null | undefined) => (d ? new Date(d).toISOString() : null);
    return {
      base: "ok",
      environnement: process.env.NODE_ENV ?? "development",
      simules: { sms: this.sms.simulee, registre: this.registre.simule },
      sms: {
        enFile: Number(sms?.en_file ?? 0),
        echecs: Number(sms?.echecs ?? 0),
        plusAncienneLe: iso(sms?.plus_ancienne),
        envoyes24h: Number(sms?.envoyes ?? 0),
      },
      registre: {
        empreintes: Number(reg?.empreintes ?? 0),
        empreintesEnAttente: Number(reg?.en_attente ?? 0),
        plusAncienneEnAttenteLe: iso(reg?.plus_ancienne),
        lots: Number(lots?.n ?? 0),
        dernierLotLe: iso(lots?.dernier),
      },
    };
  }
}
