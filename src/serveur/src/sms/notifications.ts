import { Controller, Get, Inject, Injectable, NotFoundException, Param, Post } from "@nestjs/common";
import { MembreAuthentifie } from "../authentification/garde.js";
import { BASE_DE_DONNEES, type BaseDeDonnees } from "../base/base-de-donnees.js";

export interface Notification {
  id: string;
  texte: string;
  creeeLe: string;
  lueLe?: string;
}

/** Boîte de notifications d'un membre : chaque message qui lui a été adressé, lu ou non (cahier des charges, M5). */
@Injectable()
export class NotificationsService {
  constructor(@Inject(BASE_DE_DONNEES) private readonly base: BaseDeDonnees) {}

  async boite(membreId: string): Promise<{ nonLues: number; notifications: Notification[] }> {
    const lignes = await this.base.requete<{
      id: string;
      texte: string;
      creee_le: Date | string;
      lue_le: Date | string | null;
    }>(
      "SELECT id, texte, creee_le, lue_le FROM sms.notifications WHERE membre_id = $1 ORDER BY creee_le DESC, id LIMIT 100",
      [membreId],
    );
    const [{ n }] = (await this.base.requete<{ n: string | number }>(
      "SELECT count(*) AS n FROM sms.notifications WHERE membre_id = $1 AND lue_le IS NULL",
      [membreId],
    )) as [{ n: string | number }];
    return {
      nonLues: Number(n),
      notifications: lignes.map((l) => ({
        id: l.id,
        texte: l.texte,
        creeeLe: new Date(l.creee_le).toISOString(),
        ...(l.lue_le ? { lueLe: new Date(l.lue_le).toISOString() } : {}),
      })),
    };
  }

  /** Une notification du membre ; celle d'un autre est introuvable pour lui. */
  async marquerLue(id: string, membreId: string): Promise<{ id: string }> {
    const lignes = /^[0-9a-f-]{36}$/i.test(id)
      ? await this.base.requete(
          "UPDATE sms.notifications SET lue_le = COALESCE(lue_le, now()) WHERE id = $1 AND membre_id = $2 RETURNING id",
          [id, membreId],
        )
      : [];
    if (lignes.length === 0) throw new NotFoundException("Notification introuvable");
    return { id };
  }

  async toutMarquerLu(membreId: string): Promise<{ marquees: number }> {
    const lignes = await this.base.requete(
      "UPDATE sms.notifications SET lue_le = now() WHERE membre_id = $1 AND lue_le IS NULL RETURNING id",
      [membreId],
    );
    return { marquees: lignes.length };
  }
}

@Controller("notifications")
export class NotificationsController {
  constructor(@Inject(NotificationsService) private readonly notifications: NotificationsService) {}

  @Get()
  boite(@MembreAuthentifie() membreId: string) {
    return this.notifications.boite(membreId);
  }

  @Post("lues")
  toutMarquerLu(@MembreAuthentifie() membreId: string) {
    return this.notifications.toutMarquerLu(membreId);
  }

  @Post(":id/lue")
  marquerLue(@Param("id") id: string, @MembreAuthentifie() membreId: string) {
    return this.notifications.marquerLue(id, membreId);
  }
}
