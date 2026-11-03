import { BadRequestException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { EvenementsInternes } from "../../evenements/evenements-internes.js";

export interface Cotisation {
  id: string;
  cercleId: string;
  payeurId: string;
  beneficiaireId: string;
  montant: number;
  dateLimite: string;
  referenceTransaction?: string;
  statut: "due" | "declaree" | "confirmee";
}

/** Le bénéficiaire confirme la réception : le silence ne vaut jamais confirmation. */
@Injectable()
export class CotisationsService {
  private readonly cotisations = new Map<string, Cotisation>();

  constructor(@Inject(EvenementsInternes) private readonly evenements: EvenementsInternes) {}

  creer(d: Omit<Cotisation, "id" | "statut">): Cotisation {
    const c: Cotisation = { ...d, id: randomUUID(), statut: "due" };
    this.cotisations.set(c.id, c);
    return c;
  }

  declarerPaiement(id: string, referenceTransaction: string): Cotisation {
    const c = this.trouver(id);
    if (!referenceTransaction.trim()) throw new BadRequestException("La référence de la transaction est obligatoire");
    if (c.statut === "confirmee") throw new BadRequestException("Cotisation déjà confirmée");
    c.referenceTransaction = referenceTransaction;
    c.statut = "declaree";
    return c;
  }

  confirmer(id: string, parMembreId: string, maintenant: Date = new Date()): Cotisation {
    const c = this.trouver(id);
    if (parMembreId !== c.beneficiaireId) throw new BadRequestException("Seul le bénéficiaire peut confirmer");
    if (c.statut !== "declaree") throw new BadRequestException("Aucun paiement déclaré à confirmer");
    c.statut = "confirmee";
    this.evenements.publier({
      type: "cotisation_confirmee",
      cercleId: c.cercleId,
      membreId: c.payeurId,
      aTemps: maintenant <= new Date(c.dateLimite),
    });
    return c;
  }

  private trouver(id: string): Cotisation {
    const c = this.cotisations.get(id);
    if (!c) throw new NotFoundException("Cotisation introuvable");
    return c;
  }
}
