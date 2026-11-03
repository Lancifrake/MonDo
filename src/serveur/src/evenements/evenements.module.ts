import { Global, Module } from "@nestjs/common";
import { EvenementsInternes } from "./evenements-internes.js";

@Global()
@Module({ providers: [EvenementsInternes], exports: [EvenementsInternes] })
export class EvenementsModule {}
