import { Global, Module } from "@nestjs/common";
import { STOCKAGE_OBJETS, creerStockage } from "./stockage-objets.js";

@Global()
@Module({
  providers: [{ provide: STOCKAGE_OBJETS, useFactory: () => creerStockage() }],
  exports: [STOCKAGE_OBJETS],
})
export class StockageModule {}
