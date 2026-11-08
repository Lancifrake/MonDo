import { ForbiddenException, Inject, Injectable, NotFoundException, type OnModuleInit } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";
import { hacher, type EtapePreuve } from "../../registre/merkle.js";
import { RegistreService } from "../../registre/registre.service.js";
import { canonique } from "../../signature/canonique.js";
import { CerclesService, messageEngagement, messageReglement, type Reglement } from "../cercles/cercles.service.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { CotisationsService, type Cotisation } from "../cotisations/cotisations.service.js";
import { calculerMontantDu, type MontantDu } from "./montants.js";

export interface MiseEnDemeure {
  id: string;
  cercleId: string;
  membreId: string;
  tour: number;
  emiseLe: string;
  montantDu: MontantDu;
  cotisationsDues: string[];
  /** Préparée par le module Preuve, envoyée par l'assistant (décision 04). Canal simulé au prototype. */
  envoi: "a_envoyer" | "envoyee";
  envoyeeLe: string | null;
  empreinte: string;
}

export interface PieceSignee {
  message: string;
  signature: string;
  empreinte: string;
  /** Preuve d'inscription au registre ; null tant que le lot n'est pas fermé. */
  preuveRegistre: { racine: string; etapes: EtapePreuve[] } | null;
}

export interface DossierDePreuve {
  genereLe: string;
  cercleId: string;
  debiteur: { id: string; nom: string; numero: string; niveauIdentite: 1 | 2; clePublique: JsonWebKey };
  reglement: PieceSignee & { contenu: Reglement; organisateurId: string; clePubliqueOrganisateur: JsonWebKey };
  engagement: PieceSignee;
  releveCotisations: Cotisation[];
  misesEnDemeure: MiseEnDemeure[];
  /** Non générée : créancier et formule du montant restent à trancher avec un juriste (recours-legaux.md, section 5). */
  reconnaissanceDeDette: null;
  avertissements: string[];
}

const AVERTISSEMENTS = [
  "Dossier prêt pour le recouvrement : il ne garantit aucun remboursement.",
  "Valeur légale à confirmer par un avocat camerounais avant tout usage réel.",
  "Reconnaissance de dette non générée : le créancier et le montant restent à trancher avec un juriste.",
];

@Injectable()
export class PreuveService implements OnModuleInit {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CerclesService) private readonly cercles: CerclesService,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(RegistreService) private readonly registre: RegistreService,
  ) {}

  onModuleInit(): void {
    this.evenements.ecouter("defaut_constate", async (e) => {
      await this.emettreMiseEnDemeure(e.cercleId, e.membreId, e.tour, new Date(e.constateLe));
    });
  }

  /**
   * Mise en demeure datée du constat, aux montants du règlement signé. Une seule par défaut constaté
   * (cercle, membre, tour). Ne réclame que les cotisations échues à cette date, jamais les tours à venir.
   */
  async emettreMiseEnDemeure(
    cercleId: string,
    membreId: string,
    tour: number,
    constateLe: Date = new Date(),
  ): Promise<MiseEnDemeure | undefined> {
    const cercle = await this.cercles.trouver(cercleId);
    const dues = (await this.cotisations.listerPour(cercleId, membreId)).filter(
      (c) => c.statut !== "confirmee" && Date.parse(c.dateLimite) <= constateLe.getTime(),
    );
    const contenu = {
      objet: "mise_en_demeure",
      id: randomUUID(),
      cercleId,
      membreId,
      tour,
      emiseLe: constateLe.toISOString(),
      montantDu: calculerMontantDu(
        dues.map((c) => c.montant),
        cercle.reglement.penaliteRetard,
      ),
      cotisationsDues: dues.map((c) => c.id),
    };
    const empreinte = hacher(canonique(contenu));
    const inseree = await this.base.requete(
      `INSERT INTO preuve.mises_en_demeure (id, cercle_id, membre_id, tour, contenu, empreinte, envoi, emise_le)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT (cercle_id, membre_id, tour) DO NOTHING RETURNING id`,
      [contenu.id, cercleId, membreId, tour, JSON.stringify(contenu), empreinte, "a_envoyer", contenu.emiseLe],
    );
    if (inseree.length === 0) return undefined;
    await this.registre.enregistrer(canonique(contenu));
    const { objet: _objet, ...miseEnDemeure } = contenu;
    return { ...miseEnDemeure, envoi: "a_envoyer", envoyeeLe: null, empreinte };
  }

  /** Mises en demeure préparées et pas encore envoyées, pour que l'assistant en rédige le SMS. */
  async aEnvoyer(cercleId: string, membreId: string): Promise<MiseEnDemeure[]> {
    return (await this.misesEnDemeure(cercleId, membreId)).filter((m) => m.envoi === "a_envoyer");
  }

  /** Marque comme envoyées les mises en demeure préparées pour ce membre. Le contenu daté, lui, ne change pas. */
  async marquerEnvoyees(cercleId: string, membreId: string): Promise<number> {
    const lignes = await this.base.requete(
      `UPDATE preuve.mises_en_demeure SET envoi = 'envoyee', envoyee_le = now()
       WHERE cercle_id = $1 AND membre_id = $2 AND envoi = 'a_envoyer' RETURNING id`,
      [cercleId, membreId],
    );
    return lignes.length;
  }

  /** Réservé aux membres lésés : membres du cercle autres que le débiteur (flow 7). */
  async exporterDossier(
    cercleId: string,
    debiteurId: string,
    demandeurId: string,
  ): Promise<DossierDePreuve & { empreinte: string }> {
    const cercle = await this.cercles.trouver(cercleId);
    if (demandeurId === debiteurId || !cercle.membres.includes(demandeurId)) {
      throw new ForbiddenException("Seuls les autres membres du cercle peuvent exporter ce dossier");
    }
    const misesEnDemeure = await this.misesEnDemeure(cercleId, debiteurId);
    if (misesEnDemeure.length === 0) throw new NotFoundException("Aucun défaut constaté pour ce membre");

    const [debiteur, organisateur, adhesionDebiteur, adhesionOrganisateur] = await Promise.all([
      this.comptes.trouver(debiteurId),
      this.comptes.trouver(cercle.organisateurId),
      this.cercles.adhesion(cercleId, debiteurId),
      this.cercles.adhesion(cercleId, cercle.organisateurId),
    ]);
    const msgReglement = messageReglement(
      cercle.organisateurId,
      cercle.reglement,
      adhesionOrganisateur!.placeSouhaitee,
    );
    const msgEngagement =
      adhesionDebiteur!.rang === 1
        ? msgReglement
        : messageEngagement(cercleId, cercle.empreinteReglement, debiteurId, adhesionDebiteur!.placeSouhaitee);

    const dossier: DossierDePreuve = {
      genereLe: new Date().toISOString(),
      cercleId,
      debiteur: {
        id: debiteur.id,
        nom: debiteur.nom,
        numero: debiteur.numero,
        niveauIdentite: debiteur.niveau,
        clePublique: debiteur.clePublique,
      },
      reglement: {
        contenu: cercle.reglement,
        organisateurId: cercle.organisateurId,
        clePubliqueOrganisateur: organisateur.clePublique,
        ...(await this.piece(msgReglement, adhesionOrganisateur!.signature)),
      },
      engagement: await this.piece(msgEngagement, adhesionDebiteur!.signature),
      releveCotisations: await this.cotisations.listerPour(cercleId, debiteurId),
      misesEnDemeure,
      reconnaissanceDeDette: null,
      avertissements:
        debiteur.niveau === 2
          ? AVERTISSEMENTS
          : [...AVERTISSEMENTS, "Identité non vérifiée : le débiteur n'est désigné que par son numéro de téléphone."],
    };
    // L'export lui-même laisse une trace : on pourra prouver quel dossier a été remis, et quand.
    const empreinte = await this.registre.enregistrer(canonique(dossier));
    return { ...dossier, empreinte };
  }

  private async piece(message: string, signature: string): Promise<PieceSignee> {
    const empreinte = hacher(message);
    return { message, signature, empreinte, preuveRegistre: (await this.registre.preuvePour(empreinte)) ?? null };
  }

  private async misesEnDemeure(cercleId: string, membreId: string): Promise<MiseEnDemeure[]> {
    const lignes = await this.base.requete<{
      contenu: Omit<MiseEnDemeure, "empreinte" | "envoi" | "envoyeeLe"> & { objet?: string };
      empreinte: string;
      envoi: MiseEnDemeure["envoi"];
      envoyee_le: Date | string | null;
    }>(
      `SELECT contenu, empreinte, envoi, envoyee_le FROM preuve.mises_en_demeure
       WHERE cercle_id = $1 AND membre_id = $2 ORDER BY tour`,
      [cercleId, membreId],
    );
    return lignes.map(({ contenu: { objet: _objet, ...c }, empreinte, envoi, envoyee_le }) => ({
      ...c,
      envoi,
      envoyeeLe: envoyee_le ? new Date(envoyee_le).toISOString() : null,
      empreinte,
    }));
  }
}
