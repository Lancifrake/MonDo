import { Global, Module } from "@nestjs/common";
import { CONNECTEUR_SMS, ConnecteurSmsSimule } from "./connecteur-sms.js";
import { FileSms } from "./file-sms.js";
import { NotificationsController, NotificationsService } from "./notifications.js";

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [{ provide: CONNECTEUR_SMS, useClass: ConnecteurSmsSimule }, FileSms, NotificationsService],
  exports: [CONNECTEUR_SMS, FileSms, NotificationsService],
})
export class SmsModule {}
