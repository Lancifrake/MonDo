/** Écrit une racine sur la chaîne. Simulé au prototype, ou contrat RegistreMonDo (connecteur-evm.ts). */
export interface ConnecteurRegistre {
  inscrireRacine(racine: string): Promise<{ referenceInscription: string }>;
  /** Relit la chaîne : la racine y est-elle inscrite ? Sans cette lecture, la vérification reste en base. */
  estInscrite?(racine: string): Promise<boolean>;
}
