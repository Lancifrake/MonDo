import { Logger } from "@nestjs/common";

export const CONNECTEUR_SMS = Symbol("CONNECTEUR_SMS");

/** Envoi de SMS. Simulé au prototype ; un fournisseur réel (non choisi, décision 03) viendra derrière cette interface. */
export interface ConnecteurSms {
  envoyer(numero: string, texte: string): Promise<void>;
}

/** Garde les messages en mémoire et les écrit dans le journal du serveur, pour le développement et les tests. */
export class ConnecteurSmsSimule implements ConnecteurSms {
  readonly messages: { numero: string; texte: string }[] = [];
  private readonly journal = new Logger("SMS simulé");

  constructor() {
    if (process.env.NODE_ENV === "production") {
      throw new Error("SMS simulé interdit en production : brancher un vrai fournisseur");
    }
  }

  async envoyer(numero: string, texte: string): Promise<void> {
    this.messages.push({ numero, texte });
    this.journal.log(`${numero} : ${texte}`);
  }
}
