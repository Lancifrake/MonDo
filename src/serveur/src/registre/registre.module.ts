import { Global, Logger, Module } from "@nestjs/common";
import { connecteurEvmDepuisEnvironnement } from "./connecteur-evm.js";
import {
  CONNECTEUR_REGISTRE,
  ConnecteurRegistreSimule,
  RegistreService,
  type ConnecteurRegistre,
} from "./registre.service.js";

function choisirConnecteur(): ConnecteurRegistre {
  const reel = connecteurEvmDepuisEnvironnement();
  if (reel) return reel;
  if (process.env.NODE_ENV === "production") {
    throw new Error(
      "Registre simulé interdit en production : définir MONDO_REGISTRE_RPC_URL, MONDO_REGISTRE_CONTRAT, MONDO_REGISTRE_CLE",
    );
  }
  new Logger("Registre").warn("Registre simulé : aucune racine n'est inscrite sur une vraie chaîne");
  return new ConnecteurRegistreSimule();
}

@Global()
@Module({
  providers: [RegistreService, { provide: CONNECTEUR_REGISTRE, useFactory: choisirConnecteur }],
  exports: [RegistreService],
})
export class RegistreModule {}
