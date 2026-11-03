import { Global, Module } from "@nestjs/common";
import { CONNECTEUR_REGISTRE, ConnecteurRegistreSimule, RegistreService } from "./registre.service.js";

@Global()
@Module({
  providers: [RegistreService, { provide: CONNECTEUR_REGISTRE, useClass: ConnecteurRegistreSimule }],
  exports: [RegistreService],
})
export class RegistreModule {}
