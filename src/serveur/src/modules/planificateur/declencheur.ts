import { Inject, Injectable, Logger, type OnModuleDestroy } from "@nestjs/common";
import { CerclesService } from "../cercles/cercles.service.js";
import { IdentiteService } from "../comptes/identite.service.js";
import { RecuperationService } from "../comptes/recuperation.service.js";
import { RegistreService } from "../../registre/registre.service.js";
import { FileSms } from "../../sms/file-sms.js";
import { PlanificateurService } from "./planificateur.service.js";

const MINUTE_MS = 60 * 1000;

/**
 * Intervalle entre deux passages, en millisecondes. Une heure par défaut : un défaut est constaté au plus
 * une heure après la fin de grâce. Les tâches sont rejouables, donc passer souvent ne double rien.
 * `MONDO_PLANIFICATEUR_MINUTES=0` désactive le planificateur (par exemple sur une seconde instance).
 */
export function intervallePlanificateur(env: NodeJS.ProcessEnv): number | undefined {
  const brut = env.MONDO_PLANIFICATEUR_MINUTES;
  if (brut === undefined || brut === "") return 60 * MINUTE_MS;
  if (!/^\d+$/.test(brut)) {
    throw new Error(`MONDO_PLANIFICATEUR_MINUTES doit être un nombre entier de minutes, reçu « ${brut} »`);
  }
  const minutes = Number(brut);
  return minutes === 0 ? undefined : minutes * MINUTE_MS;
}

/**
 * À chaque passage : `examinerEcheances`, puis la file des SMS, puis le registre, puis la conservation des pièces (lots en échec réinscrits, puis
 * le lot en cours fermé et sa racine inscrite sur la chaîne). Au démarrage (rattrapage après un arrêt) puis à
 * intervalle régulier. Jamais deux passages en même temps. Chaque étape est indépendante : une étape qui échoue
 * est journalisée, les suivantes ont lieu quand même, et elle est reprise au passage suivant.
 * Démarré par `main.ts` seulement : les tests pilotent le planificateur à la main, avec leur propre date.
 */
@Injectable()
export class DeclencheurPlanificateur implements OnModuleDestroy {
  private readonly journal = new Logger("Planificateur");
  private minuterie: ReturnType<typeof setInterval> | undefined;
  private enCours: Promise<void> | undefined;

  constructor(
    @Inject(PlanificateurService) private readonly planificateur: PlanificateurService,
    @Inject(FileSms) private readonly sms: Pick<FileSms, "vider">,
    @Inject(RegistreService) private readonly registre: Pick<RegistreService, "reprendreInscriptions" | "fermerLot">,
    @Inject(IdentiteService) private readonly identite: Pick<IdentiteService, "purger">,
    @Inject(CerclesService) private readonly cercles: Pick<CerclesService, "aUnCercleEnCours">,
    @Inject(RecuperationService) private readonly recuperation: Pick<RecuperationService, "finaliser">,
  ) {}

  demarrer(intervalleMs: number): void {
    if (this.minuterie) return;
    this.minuterie = setInterval(() => void this.passage(), intervalleMs);
    void this.passage();
  }

  async arreter(): Promise<void> {
    clearInterval(this.minuterie);
    this.minuterie = undefined;
    await this.enCours;
  }

  /** Avant la fermeture de la base (BaseModule la ferme à l'arrêt de l'application, après ceci). */
  onModuleDestroy(): Promise<void> {
    return this.arreter();
  }

  private passage(): Promise<void> {
    if (this.enCours) return this.enCours;
    this.enCours = (async () => {
      try {
        await this.etape("Échéances", async () => {
          const { traitees, echecs } = await this.planificateur.examinerEcheances();
          if (traitees > 0) this.journal.log(`${traitees} tâche(s) traitée(s)`);
          if (echecs > 0) this.journal.warn(`${echecs} tâche(s) en échec, rejouées au prochain passage`);
        });
        // Récupérations de compte dont le délai est passé sans opposition.
        await this.etape("Récupérations", async () => {
          const closes = await this.recuperation.finaliser();
          if (closes > 0) this.journal.log(`${closes} récupération(s) de compte close(s)`);
        });
        // SMS restés en file (passerelle en panne au moment de l'envoi) : nouvelle tentative.
        await this.etape("SMS", () => this.sms.vider());
        await this.etape("Registre", async () => {
          const reprises = await this.registre.reprendreInscriptions();
          if (reprises > 0) this.journal.log(`${reprises} lot(s) en attente inscrit(s) sur la chaîne`);
          const lot = await this.registre.fermerLot();
          if (lot)
            this.journal.log(`Lot de ${lot.empreintes.length} empreinte(s) inscrit : ${lot.referenceInscription}`);
        });
        // Pièces d'identité : suppressions à reprendre, cartes arrivées au bout de leur durée de conservation.
        await this.etape("Conservation", async () => {
          const supprimees = await this.identite.purger(new Date(), (id) => this.cercles.aUnCercleEnCours(id));
          if (supprimees > 0) this.journal.log(`${supprimees} image(s) d'identité supprimée(s)`);
        });
      } finally {
        this.enCours = undefined;
      }
    })();
    return this.enCours;
  }

  private async etape(nom: string, faire: () => Promise<unknown>): Promise<void> {
    try {
      await faire();
    } catch (e) {
      this.journal.error(
        `${nom} : passage interrompu, repris au prochain passage (${e instanceof Error ? e.message : String(e)})`,
      );
    }
  }
}
