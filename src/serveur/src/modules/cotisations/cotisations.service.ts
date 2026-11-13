import { BadRequestException, ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../../base/base-de-donnees.js";
import { EvenementsInternes, type CercleComplet } from "../../evenements/evenements-internes.js";
import { RegistreService } from "../../registre/registre.service.js";
import { canonique } from "../../signature/canonique.js";
import { FileSms } from "../../sms/file-sms.js";
import { fcfa } from "../../sms/montant.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { calendrierDesTours } from "./calendrier.js";
import type { NatureSomme } from "./sommes-dues.service.js";

const JOUR_MS = 24 * 60 * 60 * 1000;

export interface Cotisation {
  id: string;
  cercleId: string;
  payeurId: string;
  beneficiaireId: string;
  montant: number;
  /** Numéro du tour ; 0 pour une cotisation créée à la main avant le 05/11 (prototype). */
  tour: number;
  dateLimite: string;
  /** Au-delà, la cotisation non payée devient un défaut (délai de grâce du règlement). */
  finGrace: string;
  referenceTransaction?: string;
  /** Moment de la déclaration du paiement par le payeur. */
  declareeLe?: string;
  /** Litige ouvert : la déclaration est gelée et le bénéficiaire n'est plus relancé. */
  enLitige: boolean;
  /** Pénalité de retard du règlement pour cette cotisation, due au bénéficiaire du tour (11/11). */
  penalite: number;
  /** Ce qui est effectivement dû : la pénalité si la fin de grâce est passée sans paiement, sinon 0. */
  penaliteDue: number;
  /** Fin de grâce à laquelle la pénalité est devenue due. Une seule fois, même si le paiement arrive ensuite. */
  penaliteDueLe?: string;
  /** annulee : un membre a quitté le cercle, cette cotisation n'est plus due. */
  statut: "due" | "declaree" | "confirmee" | "annulee";
}

export interface BilanDeCycle {
  cercleId: string;
  membreId: string;
  /** Fin de grâce du dernier tour du cercle. */
  finCycle: string;
  toutConfirme: boolean;
}

interface LigneCotisation extends Record<string, unknown> {
  id: string;
  cercle_id: string;
  payeur_id: string;
  beneficiaire_id: string;
  montant: string | number;
  tour: number | null;
  date_limite: Date | string;
  fin_grace: Date | string | null;
  reference_transaction: string | null;
  declaree_le?: Date | string | null;
  en_litige?: boolean | null;
  penalite?: string | number | null;
  penalite_due_le?: Date | string | null;
  statut: Cotisation["statut"];
}

const versCotisation = (l: LigneCotisation): Cotisation => ({
  id: l.id,
  cercleId: l.cercle_id,
  payeurId: l.payeur_id,
  beneficiaireId: l.beneficiaire_id,
  montant: Number(l.montant),
  tour: l.tour ?? 0,
  dateLimite: new Date(l.date_limite).toISOString(),
  finGrace: new Date(l.fin_grace ?? l.date_limite).toISOString(),
  ...(l.reference_transaction ? { referenceTransaction: l.reference_transaction } : {}),
  ...(l.declaree_le ? { declareeLe: new Date(l.declaree_le).toISOString() } : {}),
  enLitige: l.en_litige === true,
  penalite: Number(l.penalite ?? 0),
  penaliteDue: l.penalite_due_le ? Number(l.penalite ?? 0) : 0,
  ...(l.penalite_due_le ? { penaliteDueLe: new Date(l.penalite_due_le).toISOString() } : {}),
  statut: l.statut,
});

/** Le bénéficiaire confirme la réception : le silence ne vaut jamais confirmation. */
@Injectable()
export class CotisationsService {
  constructor(
    @Inject(EvenementsInternes) private readonly evenements: EvenementsInternes,
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(FileSms) private readonly sms: FileSms,
    @Inject(RegistreService) private readonly registre: RegistreService,
  ) {
    this.evenements.ecouter("cercle_complet", (e) => this.planifierTours(e));
    this.evenements.ecouter("defaut_constate", async (e) => {
      await this.rendrePenaliteDue(e.cercleId, e.membreId, e.tour);
      // Le défaut est inscrit au registre (cahier des charges, M10) : une empreinte, sans donnée personnelle.
      await this.registre.enregistrer(
        canonique({
          objet: "defaut_constate",
          cercleId: e.cercleId,
          membreId: e.membreId,
          tour: e.tour,
          constateLe: e.constateLe,
        }),
      );
    });
    this.evenements.ecouter("compte_debloque", (e) => this.reporterEcheances(e.membreId, e.bloqueLe, e.debloqueLe));
    this.evenements.ecouter("confirmation_attendue", (e) => this.relancerBeneficiaire(e.cotisationId, e.palierHeures));
  }

  /**
   * Défaut constaté : la pénalité du règlement devient due au bénéficiaire du tour, datée de la fin de grâce.
   * Une seule fois par cotisation : un événement rejoué ne change rien, un paiement tardif ne l'efface pas.
   */
  private async rendrePenaliteDue(cercleId: string, payeurId: string, tour: number): Promise<void> {
    await this.base.requete(
      `UPDATE cotisations.cotisations SET penalite_due_le = fin_grace
       WHERE cercle_id = $1 AND payeur_id = $2 AND tour = $3 AND statut IN ('due', 'declaree') AND penalite_due_le IS NULL`,
      [cercleId, payeurId, tour],
    );
  }

  /**
   * Compte débloqué (règle du 03/11) : les dates limites et les fins de grâce des cotisations que le membre
   * devait encore, et dont la fin de grâce n'était pas passée au début du blocage, reculent de la durée du
   * blocage. Le temps bloqué ne compte ni comme retard ni comme défaut.
   */
  private async reporterEcheances(membreId: string, bloqueLe: string, debloqueLe: string): Promise<void> {
    const dureeMs = Date.parse(debloqueLe) - Date.parse(bloqueLe);
    if (!(dureeMs > 0)) return;
    await this.base.requete(
      `UPDATE cotisations.cotisations
       SET date_limite = date_limite + ($3 * interval '1 millisecond'),
           fin_grace = fin_grace + ($3 * interval '1 millisecond')
       WHERE payeur_id = $1 AND statut = 'due' AND tour > 0 AND fin_grace > $2`,
      [membreId, bloqueLe, dureeMs],
    );
  }

  /**
   * Rappel au bénéficiaire à 24 h puis à 48 h (flow 6) : son silence ne vaut pas confirmation. L'état est relu
   * au moment d'écrire : rien si le paiement a été confirmé ou si un litige s'est ouvert entre-temps. Le SMS ne
   * nomme pas le payeur et ne reprend pas la référence : le détail se lit dans l'application.
   */
  private async relancerBeneficiaire(cotisationId: string, palierHeures: 24 | 48): Promise<void> {
    const c = await this.trouver(cotisationId);
    if (c.statut !== "declaree" || c.enLitige) return;
    const beneficiaire = await this.comptes.chercher(c.beneficiaireId);
    if (!beneficiaire) return;
    const debut = `MonDo : un membre déclare vous avoir payé ${fcfa(c.montant)} (tour ${c.tour}).`;
    const texte =
      palierHeures === 24
        ? `${debut} Vérifiez votre compte Mobile Money puis confirmez la réception dans l'application.`
        : `${debut} Second rappel : confirmez la réception, ou signalez que vous n'avez rien reçu.`;
    // La clé suit la déclaration : une nouvelle déclaration après un refus relance de nouveau.
    await this.sms.mettreEnFile(
      `relance_confirmation:${c.id}:${c.declareeLe ?? ""}:${palierHeures}`,
      beneficiaire.numero,
      texte,
      beneficiaire.id,
    );
    this.sms.declencher();
  }

  /**
   * Tours et cotisations du cycle, créés d'un coup quand le cercle est complet : chaque membre doit le
   * montant du règlement à chaque bénéficiaire sauf lui-même. Rejouable : un cercle déjà planifié est ignoré.
   */
  async planifierTours(c: CercleComplet): Promise<void> {
    const tours = calendrierDesTours(c);
    await this.base.transaction(async (tx) => {
      const [deja] = await tx.requete("SELECT 1 FROM cotisations.tours WHERE cercle_id = $1 LIMIT 1", [c.cercleId]);
      if (deja) return;
      for (const t of tours) {
        await tx.requete(
          "INSERT INTO cotisations.tours (cercle_id, numero, beneficiaire_id, date_limite) VALUES ($1, $2, $3, $4)",
          [c.cercleId, t.numero, t.beneficiaireId, t.dateLimite],
        );
        const finGrace = new Date(Date.parse(t.dateLimite) + c.delaiGraceJours * JOUR_MS).toISOString();
        for (const payeurId of c.ordre.filter((m) => m !== t.beneficiaireId)) {
          await tx.requete(
            `INSERT INTO cotisations.cotisations
               (id, cercle_id, payeur_id, beneficiaire_id, montant, tour, date_limite, fin_grace, statut, penalite)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'due', $9)`,
            [
              randomUUID(),
              c.cercleId,
              payeurId,
              t.beneficiaireId,
              c.montant,
              t.numero,
              t.dateLimite,
              finGrace,
              c.penaliteRetard ?? 0,
            ],
          );
        }
      }
      // Frais du modèle A : le bénéficiaire d'un tour du début doit sa part à MonDo et une remise à chaque
      // membre d'une place de fin. Exigibles le jour de sa cagnotte, à régler avant le tour suivant.
      for (const f of c.frais ?? []) {
        const tour = tours[f.tour - 1];
        const suivant = tours[f.tour];
        if (!tour || !suivant) continue;
        const creances: [string | null, NatureSomme, number][] = [
          [null, "frais_mondo", f.partMonDo],
          ...f.remises.map((r): [string, NatureSomme, number] => [r.creancierId, "remise", r.montant]),
        ];
        for (const [creancierId, nature, montant] of creances) {
          if (montant <= 0) continue;
          await tx.requete(
            `INSERT INTO cotisations.sommes_dues
               (id, cercle_id, nature, debiteur_id, creancier_id, montant, tour, exigible_le, date_limite, statut)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'due')`,
            [
              randomUUID(),
              c.cercleId,
              nature,
              tour.beneficiaireId,
              creancierId,
              montant,
              tour.numero,
              tour.dateLimite,
              suivant.dateLimite,
            ],
          );
        }
      }
    });
  }

  async declarerPaiement(id: string, referenceTransaction: string, parMembreId: string): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.payeurId) throw new ForbiddenException("Seul le payeur déclare son paiement");
    // Pendant un litige ouvert, la déclaration est gelée : l'administrateur tranche sur la pièce d'origine.
    const [l] = await this.base.requete<LigneCotisation>(
      `UPDATE cotisations.cotisations SET reference_transaction = $2, statut = 'declaree', declaree_le = now()
       WHERE id = $1 AND statut IN ('due', 'declaree') AND NOT en_litige RETURNING *`,
      [id, referenceTransaction],
    );
    if (!l) {
      throw new BadRequestException(
        c.statut === "confirmee"
          ? "Cotisation déjà confirmée"
          : c.statut === "annulee"
            ? "Cotisation annulée après le départ d'un membre"
            : "Litige en cours : la déclaration est gelée jusqu'à la décision de l'administrateur",
      );
    }
    return versCotisation(l);
  }

  /** Litige ouvert sur cette cotisation : le payeur ne peut plus changer sa déclaration jusqu'à la décision. */
  async geler(id: string): Promise<void> {
    await this.base.requete("UPDATE cotisations.cotisations SET en_litige = true WHERE id = $1", [id]);
  }

  async confirmer(id: string, parMembreId: string, maintenant: Date = new Date()): Promise<Cotisation> {
    const c = await this.trouver(id);
    if (parMembreId !== c.beneficiaireId) throw new ForbiddenException("Seul le bénéficiaire peut confirmer");
    // Mise à jour conditionnelle : deux confirmations simultanées ne comptent qu'une fois.
    const [l] = await this.base.requete<LigneCotisation>(
      "UPDATE cotisations.cotisations SET statut = 'confirmee', en_litige = false WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à confirmer");
    const confirmee = versCotisation(l);
    await this.publierConfirmation(confirmee, maintenant <= new Date(confirmee.dateLimite));
    return confirmee;
  }

  /**
   * Décision d'un litige : paiement validé par l'administrateur. À temps si le paiement avait été déclaré
   * avant la date limite : le payeur ne paie pas le retard de confirmation du bénéficiaire.
   */
  async validerApresLitige(id: string): Promise<Cotisation> {
    const [l] = await this.base.requete<LigneCotisation>(
      "UPDATE cotisations.cotisations SET statut = 'confirmee', en_litige = false WHERE id = $1 AND statut = 'declaree' RETURNING *",
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à valider");
    const validee = versCotisation(l);
    await this.publierConfirmation(validee, Date.parse(validee.declareeLe!) <= Date.parse(validee.dateLimite));
    return validee;
  }

  /** Décision d'un litige : paiement refusé, la cotisation redevient due (défaut si la grâce est passée). */
  async remettreDueApresLitige(id: string): Promise<Cotisation> {
    const [l] = await this.base.requete<LigneCotisation>(
      `UPDATE cotisations.cotisations SET statut = 'due', reference_transaction = NULL, declaree_le = NULL,
         en_litige = false
       WHERE id = $1 AND statut = 'declaree' RETURNING *`,
      [id],
    );
    if (!l) throw new BadRequestException("Aucun paiement déclaré à refuser");
    return versCotisation(l);
  }

  /**
   * Départ d'un membre en cours de cycle (décision 05, règle détaillée). Tout ou rien, dans une transaction :
   * refusé s'il a déjà reçu quelque chose de sa cagnotte ou s'il n'est pas à jour ; sinon son tour et ses
   * cotisations futures sont annulés, et chaque bénéficiaire déjà servi lui doit le remboursement de ce qu'il a
   * versé. Frais du modèle A : les sommes non réglées qui le concernent sont annulées, une remise qu'il a déjà
   * reçue est à rembourser. Une seule fois par membre et par cercle.
   */
  async enregistrerDepart(
    cercleId: string,
    membreId: string,
    maintenant: Date,
    limiteRemboursement: Date,
  ): Promise<{ remboursements: number; dejaEnregistre?: true }> {
    return this.base.transaction(async (tx) => {
      // La ligne de départ sert de verrou : une seconde demande simultanée s'arrête ici.
      const pris = await tx.requete(
        `INSERT INTO cotisations.departs (cercle_id, membre_id, parti_le) VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING RETURNING membre_id`,
        [cercleId, membreId, maintenant.toISOString()],
      );
      // Déjà enregistré ici : l'appelant termine alors ce qui restait à faire chez lui (reprise après une panne).
      if (pris.length === 0) return { remboursements: 0, dejaEnregistre: true as const };
      const lignes = await tx.requete<LigneCotisation>(
        `SELECT * FROM cotisations.cotisations
         WHERE cercle_id = $1 AND tour > 0 AND (payeur_id = $2 OR beneficiaire_id = $2) FOR UPDATE`,
        [cercleId, membreId],
      );
      const siennes = lignes.map(versCotisation);
      if (siennes.some((c) => c.beneficiaireId === membreId && c.statut !== "due")) {
        throw new BadRequestException(
          "Départ impossible : vous avez commencé à recevoir votre cagnotte, arrêter maintenant serait un défaut",
        );
      }
      const aPayer = siennes.filter((c) => c.payeurId === membreId);
      const sommes = await tx.requete<{
        id: string;
        nature: string;
        debiteur_id: string;
        creancier_id: string | null;
        montant: string | number;
        statut: string;
      }>(
        `SELECT id, nature, debiteur_id, creancier_id, montant, statut FROM cotisations.sommes_dues
         WHERE cercle_id = $1 AND (debiteur_id = $2 OR creancier_id = $2) FOR UPDATE`,
        [cercleId, membreId],
      );
      const pasAJour =
        aPayer.some((c) => c.statut === "declaree" || c.enLitige) ||
        aPayer.some((c) => c.statut === "due" && Date.parse(c.dateLimite) <= maintenant.getTime()) ||
        sommes.some((s) => s.statut === "declaree");
      if (pasAJour) {
        throw new BadRequestException(
          "Départ impossible pour le moment : une cotisation échue, un paiement en attente de confirmation ou un litige est en cours",
        );
      }
      await tx.requete(
        `UPDATE cotisations.cotisations SET statut = 'annulee'
         WHERE cercle_id = $1 AND tour > 0 AND statut = 'due' AND (payeur_id = $2 OR beneficiaire_id = $2)`,
        [cercleId, membreId],
      );
      await tx.requete(
        `UPDATE cotisations.sommes_dues SET statut = 'annulee'
         WHERE cercle_id = $1 AND statut = 'due' AND (debiteur_id = $2 OR creancier_id = $2)`,
        [cercleId, membreId],
      );
      // Remboursements : ce qu'il a versé aux bénéficiaires déjà servis, et les remises qu'il a déjà reçues.
      const aRembourser: [debiteur: string, creancier: string, montant: number, tour: number, origine: string][] = [
        ...aPayer
          .filter((c) => c.statut === "confirmee")
          .map((c): [string, string, number, number, string] => [c.beneficiaireId, membreId, c.montant, c.tour, c.id]),
        ...sommes
          .filter((s) => s.statut === "confirmee" && s.nature === "remise" && s.creancier_id === membreId)
          .map((s): [string, string, number, number, string] => [membreId, s.debiteur_id, Number(s.montant), 0, s.id]),
      ];
      for (const [debiteur, creancier, montant, tour, origine] of aRembourser) {
        await tx.requete(
          `INSERT INTO cotisations.sommes_dues
             (id, cercle_id, nature, debiteur_id, creancier_id, montant, tour, exigible_le, date_limite, origine_id, statut)
           VALUES ($1, $2, 'remboursement_depart', $3, $4, $5, $6, $7, $8, $9, 'due')`,
          [
            randomUUID(),
            cercleId,
            debiteur,
            creancier,
            montant,
            tour,
            maintenant.toISOString(),
            limiteRemboursement.toISOString(),
            origine,
          ],
        );
      }
      return { remboursements: aRembourser.length };
    });
  }

  /**
   * Échange de places : les tours des deux membres sont permutés, avec leurs cotisations et les frais du
   * modèle A, qui suivent la place et non la personne. Refusé si l'un des deux tours a commencé (date limite
   * passée, paiement déclaré ou confirmé) ou si une somme de frais les concernant est déjà déclarée ou réglée.
   * Tout ou rien, dans une transaction. `simuler` : contrôle seulement, rien n'est écrit.
   */
  async echangerTours(cercleId: string, a: string, b: string, maintenant: Date, simuler = false): Promise<void> {
    await this.base.transaction(async (tx) => {
      const tours = await tx.requete<{ numero: number; beneficiaire_id: string; date_limite: Date | string }>(
        "SELECT numero, beneficiaire_id, date_limite FROM cotisations.tours WHERE cercle_id = $1 AND beneficiaire_id = ANY($2::uuid[]) FOR UPDATE",
        [cercleId, [a, b]],
      );
      const tourDe = (id: string) => tours.find((t) => t.beneficiaire_id === id);
      const [tourA, tourB] = [tourDe(a), tourDe(b)];
      if (!tourA || !tourB)
        throw new BadRequestException("Échange impossible : tour introuvable pour l'un des deux membres");
      const numeros = [tourA.numero, tourB.numero];
      const commences = await tx.requete(
        `SELECT 1 FROM cotisations.cotisations
         WHERE cercle_id = $1 AND tour = ANY($2::int[]) AND (statut <> 'due' OR en_litige OR penalite_due_le IS NOT NULL)
         LIMIT 1`,
        [cercleId, numeros],
      );
      const fraisEngages = await tx.requete(
        `SELECT 1 FROM cotisations.sommes_dues
         WHERE cercle_id = $1 AND nature IN ('frais_mondo', 'remise') AND statut IN ('declaree', 'confirmee')
           AND (debiteur_id = ANY($2::uuid[]) OR creancier_id = ANY($2::uuid[])) LIMIT 1`,
        [cercleId, [a, b]],
      );
      if (
        [tourA, tourB].some((t) => new Date(t.date_limite).getTime() <= maintenant.getTime()) ||
        commences.length > 0 ||
        fraisEngages.length > 0
      ) {
        throw new BadRequestException(
          "Échange impossible : l'un des deux tours a commencé, ou des frais liés à ces places sont déjà réglés",
        );
      }
      if (simuler) return;
      for (const [tour, ancien, nouveau] of [
        [tourA.numero, a, b],
        [tourB.numero, b, a],
      ] as const) {
        await tx.requete("UPDATE cotisations.tours SET beneficiaire_id = $3 WHERE cercle_id = $1 AND numero = $2", [
          cercleId,
          tour,
          nouveau,
        ]);
        await tx.requete("UPDATE cotisations.cotisations SET beneficiaire_id = $3 WHERE cercle_id = $1 AND tour = $2", [
          cercleId,
          tour,
          nouveau,
        ]);
        // Le nouveau bénéficiaire ne se paie pas lui-même : sa ligne de payeur revient à l'ancien bénéficiaire.
        await tx.requete(
          "UPDATE cotisations.cotisations SET payeur_id = $4 WHERE cercle_id = $1 AND tour = $2 AND payeur_id = $3",
          [cercleId, tour, nouveau, ancien],
        );
      }
      // Frais et remises non réglés : les deux membres échangent leurs rôles (qui doit, à qui).
      await tx.requete(
        `UPDATE cotisations.sommes_dues SET
           debiteur_id = CASE debiteur_id WHEN $2::uuid THEN $3::uuid WHEN $3::uuid THEN $2::uuid ELSE debiteur_id END,
           creancier_id = CASE creancier_id WHEN $2::uuid THEN $3::uuid WHEN $3::uuid THEN $2::uuid ELSE creancier_id END
         WHERE cercle_id = $1 AND nature IN ('frais_mondo', 'remise') AND statut = 'due'
           AND (debiteur_id IN ($2, $3) OR creancier_id IN ($2, $3))`,
        [cercleId, a, b],
      );
    });
  }

  /**
   * Démonstration seulement, refusée en production : les dates du cercle reculent, ce qui revient à faire
   * avancer le temps pour lui. Tours, cotisations ouvertes et sommes dues non réglées bougent ensemble.
   */
  async reculerDatesPourDemonstration(cercleId: string, dureeMs: number): Promise<void> {
    if (process.env.NODE_ENV === "production") throw new ForbiddenException("Interdit en production");
    const intervalle = "($2 * interval '1 millisecond')";
    await this.base.transaction(async (tx) => {
      await tx.requete(`UPDATE cotisations.tours SET date_limite = date_limite - ${intervalle} WHERE cercle_id = $1`, [
        cercleId,
        dureeMs,
      ]);
      await tx.requete(
        `UPDATE cotisations.cotisations
         SET date_limite = date_limite - ${intervalle}, fin_grace = fin_grace - ${intervalle},
             declaree_le = declaree_le - ${intervalle}
         WHERE cercle_id = $1 AND tour > 0`,
        [cercleId, dureeMs],
      );
      await tx.requete(
        `UPDATE cotisations.sommes_dues
         SET exigible_le = exigible_le - ${intervalle}, date_limite = date_limite - ${intervalle}
         WHERE cercle_id = $1 AND statut IN ('due', 'declaree')`,
        [cercleId, dureeMs],
      );
    });
  }

  /**
   * Qui a payé, qui n'a pas payé (US17) : l'état de chaque tour pour tout le cercle, réservé à ceux qui y
   * paient ou y reçoivent. Ni référence de transaction, ni date de déclaration : seulement le statut.
   */
  async etatDuCercle(cercleId: string, demandeurId: string, maintenant: Date = new Date()) {
    if (!/^[0-9a-f-]{36}$/i.test(cercleId)) throw new ForbiddenException("Réservé aux membres d'un cercle en cours");
    const lignes = (
      await this.base.requete<LigneCotisation>(
        "SELECT * FROM cotisations.cotisations WHERE cercle_id = $1 AND tour > 0 ORDER BY tour, payeur_id",
        [cercleId],
      )
    ).map(versCotisation);
    if (!lignes.some((c) => c.payeurId === demandeurId || c.beneficiaireId === demandeurId)) {
      throw new ForbiddenException("Réservé aux membres d'un cercle en cours");
    }
    const tours = await this.base.requete<{ numero: number; beneficiaire_id: string; date_limite: Date | string }>(
      "SELECT numero, beneficiaire_id, date_limite FROM cotisations.tours WHERE cercle_id = $1 ORDER BY numero",
      [cercleId],
    );
    return {
      cercleId,
      tours: tours.map((t) => ({
        numero: t.numero,
        beneficiaireId: t.beneficiaire_id,
        dateLimite: new Date(t.date_limite).toISOString(),
        paiements: lignes
          .filter((c) => c.tour === t.numero)
          .map((c) => ({
            payeurId: c.payeurId,
            montant: c.montant,
            statut: c.statut,
            enRetard: c.statut === "due" && Date.parse(c.dateLimite) < maintenant.getTime(),
            enLitige: c.enLitige,
            penaliteDue: c.penaliteDue,
          })),
      })),
    };
  }

  async consulter(id: string): Promise<Cotisation> {
    return this.trouver(id);
  }

  private async publierConfirmation(c: Cotisation, aTemps: boolean): Promise<void> {
    // Chaque confirmation est inscrite au registre (cahier des charges, M4) : une empreinte, sans la référence.
    await this.registre.enregistrer(
      canonique({
        objet: "cotisation_confirmee",
        cercleId: c.cercleId,
        cotisationId: c.id,
        tour: c.tour,
        payeurId: c.payeurId,
        beneficiaireId: c.beneficiaireId,
        montant: c.montant,
        aTemps,
      }),
    );
    return this.evenements.publier({
      type: "cotisation_confirmee",
      cercleId: c.cercleId,
      membreId: c.payeurId,
      cotisationId: c.id,
      aTemps,
    });
  }

  /** Cotisations ni payées ni déclarées, pour l'examen des échéances. */
  async listerDues(): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE statut = 'due' ORDER BY date_limite, id",
    );
    return lignes.map(versCotisation);
  }

  /**
   * Pour chaque cercle et chaque payeur : fin du cycle (fin de grâce la plus tardive du cercle) et
   * « tout confirmé » (le bénéficiaire a confirmé toutes ses cotisations). Pour le planificateur.
   */
  async bilansDeCycle(): Promise<BilanDeCycle[]> {
    const lignes = await this.base.requete<{
      cercle_id: string;
      payeur_id: string;
      tout_confirme: boolean;
      fin_cycle: Date | string;
    }>(
      `SELECT c.cercle_id, c.payeur_id, bool_and(c.statut IN ('confirmee', 'annulee')) AS tout_confirme,
              max(max(c.fin_grace)) OVER (PARTITION BY c.cercle_id) AS fin_cycle
       FROM cotisations.cotisations c
       WHERE c.tour > 0 AND NOT EXISTS (
         SELECT 1 FROM cotisations.departs d WHERE d.cercle_id = c.cercle_id AND d.membre_id = c.payeur_id)
       GROUP BY c.cercle_id, c.payeur_id ORDER BY c.cercle_id, c.payeur_id`,
    );
    return lignes.map((l) => ({
      cercleId: l.cercle_id,
      membreId: l.payeur_id,
      toutConfirme: l.tout_confirme,
      finCycle: new Date(l.fin_cycle).toISOString(),
    }));
  }

  /** Paiements déclarés mais pas encore confirmés, pour l'ouverture automatique des litiges. */
  async listerDeclarees(): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE statut = 'declaree' AND tour > 0 ORDER BY date_limite, id",
    );
    return lignes.map(versCotisation);
  }

  /** Ce que le membre doit et ce qu'on lui doit dans un cercle, par tour. Rien sur les autres membres. */
  async listerDuMembre(cercleId: string, membreId: string): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      `SELECT * FROM cotisations.cotisations WHERE cercle_id = $1 AND (payeur_id = $2 OR beneficiaire_id = $2)
       ORDER BY tour, date_limite, id`,
      [cercleId, membreId],
    );
    return lignes.map(versCotisation);
  }

  /** Relevé d'un payeur dans un cercle, du plus ancien au plus récent. */
  async listerPour(cercleId: string, payeurId: string): Promise<Cotisation[]> {
    const lignes = await this.base.requete<LigneCotisation>(
      "SELECT * FROM cotisations.cotisations WHERE cercle_id = $1 AND payeur_id = $2 ORDER BY date_limite, id",
      [cercleId, payeurId],
    );
    return lignes.map(versCotisation);
  }

  private async trouver(id: string): Promise<Cotisation> {
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw new NotFoundException("Cotisation introuvable");
    const [l] = await this.base.requete<LigneCotisation>("SELECT * FROM cotisations.cotisations WHERE id = $1", [id]);
    if (!l) throw new NotFoundException("Cotisation introuvable");
    return versCotisation(l);
  }
}
