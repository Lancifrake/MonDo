/** Écrit une racine sur la chaîne. Simulé au prototype, ou contrat RegistreMonDo (connecteur-evm.ts). */
export interface ConnecteurRegistre {
  inscrireRacine(racine: string): Promise<{ referenceInscription: string }>;
}
