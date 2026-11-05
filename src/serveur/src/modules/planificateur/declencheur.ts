import { Inject, Injectable, Logger, type OnModuleDestroy } from "@nestjs/common";
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
 * Lance `examinerEcheances` puis vide la file des SMS, au démarrage (rattrapage après un arrêt) puis à intervalle régulier.
 * Jamais deux passages en même temps ; un passage qui échoue est journalisé et le suivant a lieu quand même.
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
        const { traitees, echecs } = await this.planificateur.examinerEcheances();
        if (traitees > 0) this.journal.log(`${traitees} tâche(s) traitée(s)`);
        if (echecs > 0) this.journal.warn(`${echecs} tâche(s) en échec, rejouées au prochain passage`);
        // SMS restés en file (passerelle en panne au moment de l'envoi) : nouvelle tentative.
        await this.sms.vider();
      } catch (e) {
        this.journal.error(`Passage interrompu : ${e instanceof Error ? e.message : String(e)}`);
      } finally {
        this.enCours = undefined;
      }
    })();
    return this.enCours;
  }
}
