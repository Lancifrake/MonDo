import { Inject, Injectable, Logger, type OnModuleDestroy } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../base/base-de-donnees.js";
import { CONNECTEUR_SMS, type ConnecteurSms } from "./connecteur-sms.js";

/** Au-delà, le message est abandonné et journalisé (numéro invalide, passerelle durablement en panne). */
export const TENTATIVES_MAX = 5;

/** Un envoi réservé depuis plus longtemps appartient à un serveur arrêté en route : il est repris. */
const RESERVATION_PERIMEE = "5 minutes";

/**
 * File d'envoi des SMS (décision 02, règle 4). Mettre en file n'envoie rien : le message est écrit en base,
 * puis part au prochain `vider()`, déclenché tout de suite par l'appelant et rejoué par le planificateur.
 * La clé rend la mise en file rejouable : un événement traité deux fois ne donne qu'un SMS. Chaque message
 * est réservé avant l'envoi, donc deux serveurs ne l'envoient pas deux fois.
 * Le code de connexion (OTP) ne passe pas par ici : le membre l'attend et doit savoir s'il est parti.
 */
@Injectable()
export class FileSms implements OnModuleDestroy {
  private readonly journal = new Logger("File SMS");
  private enCours: Promise<void> | undefined;

  constructor(
    @Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees,
    @Inject(CONNECTEUR_SMS) private readonly passerelle: ConnecteurSms,
  ) {}

  /**
   * `membreId` : le destinataire est un membre ; le message est aussi gardé dans sa boîte de notifications
   * (cahier des charges, M5). Sans lui (contact de confiance, invité sans compte), SMS seulement.
   */
  async mettreEnFile(cle: string, numero: string, texte: string, membreId?: string): Promise<void> {
    await this.base.requete(
      `INSERT INTO sms.envois (id, cle, numero, texte, statut) VALUES ($1, $2, $3, $4, 'a_envoyer')
       ON CONFLICT (cle) DO NOTHING`,
      [randomUUID(), cle, numero, texte],
    );
    if (membreId) {
      await this.base.requete(
        `INSERT INTO sms.notifications (id, cle, membre_id, texte) VALUES ($1, $2, $3, $4) ON CONFLICT (cle) DO NOTHING`,
        [randomUUID(), cle, membreId, texte],
      );
    }
  }

  /** Envoie en arrière-plan, sans faire attendre l'appelant ; un échec reste en file pour le passage suivant. */
  declencher(): void {
    this.vider().catch((e: unknown) => this.journal.error(`Envoi interrompu : ${String(e)}`));
  }

  /** Tente une fois chaque message en attente. Un seul vidage à la fois par serveur. */
  vider(): Promise<void> {
    if (this.enCours) return this.enCours;
    this.enCours = (async () => {
      const tentes: string[] = [];
      try {
        for (let id = await this.envoyerUn(tentes); id; id = await this.envoyerUn(tentes)) tentes.push(id);
      } finally {
        this.enCours = undefined;
      }
    })();
    return this.enCours;
  }

  onModuleDestroy(): Promise<void> {
    return this.enCours ?? Promise.resolve();
  }

  /** Réserve le plus ancien message à faire (pas encore tenté dans ce vidage), l'envoie, rend son id. */
  private async envoyerUn(dejaTentes: string[]): Promise<string | undefined> {
    const aFaire = `(statut = 'a_envoyer' OR (statut = 'en_cours' AND reserve_le < now() - interval '${RESERVATION_PERIMEE}'))`;
    const [m] = await this.base.requete<{ id: string; numero: string; texte: string; tentatives: number }>(
      `UPDATE sms.envois SET statut = 'en_cours', reserve_le = now(), tentatives = tentatives + 1
       WHERE id = (SELECT id FROM sms.envois WHERE ${aFaire} AND NOT (id = ANY($1::uuid[]))
                   ORDER BY cree_le, id LIMIT 1 FOR UPDATE SKIP LOCKED)
         AND ${aFaire}
       RETURNING id, numero, texte, tentatives`,
      [dejaTentes],
    );
    if (!m) return undefined;
    try {
      await this.passerelle.envoyer(m.numero, m.texte);
      await this.base.requete("UPDATE sms.envois SET statut = 'envoye', envoye_le = now() WHERE id = $1", [m.id]);
    } catch (e) {
      const abandon = m.tentatives >= TENTATIVES_MAX;
      await this.base.requete("UPDATE sms.envois SET statut = $2, derniere_erreur = $3 WHERE id = $1", [
        m.id,
        abandon ? "echec" : "a_envoyer",
        e instanceof Error ? e.message : String(e),
      ]);
      if (abandon) this.journal.error(`SMS abandonné après ${m.tentatives} tentatives`);
    }
    return m.id;
  }
}
