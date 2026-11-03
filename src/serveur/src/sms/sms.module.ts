import { Global, Module } from "@nestjs/common";
import { CONNECTEUR_SMS, ConnecteurSmsSimule } from "./connecteur-sms.js";

@Global()
@Module({ providers: [{ provide: CONNECTEUR_SMS, useClass: ConnecteurSmsSimule }], exports: [CONNECTEUR_SMS] })
export class SmsModule {}
