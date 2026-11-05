import { Global, Module } from "@nestjs/common";
import { CONNECTEUR_SMS, ConnecteurSmsSimule } from "./connecteur-sms.js";
import { FileSms } from "./file-sms.js";

@Global()
@Module({
  providers: [{ provide: CONNECTEUR_SMS, useClass: ConnecteurSmsSimule }, FileSms],
  exports: [CONNECTEUR_SMS, FileSms],
})
export class SmsModule {}
