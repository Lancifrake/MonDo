import { z } from "zod";

export const schemaClePublique = z.strictObject({
  kty: z.literal("EC"),
  crv: z.literal("P-256"),
  x: z.string().min(1),
  y: z.string().min(1),
  ext: z.boolean().optional(),
  key_ops: z.array(z.string()).optional(),
});

const schemaNumero = z.string().regex(/^\+?\d{8,15}$/, "Numéro de téléphone invalide");

export const schemaDemandeOtp = z.strictObject({ numero: schemaNumero });

export const schemaInscription = z.strictObject({
  numero: schemaNumero,
  nom: z.string().trim().min(1).max(100),
  clePublique: schemaClePublique,
  preuve: z.string().min(1),
  codeOtp: z.string().regex(/^\d{6}$/, "Code SMS à 6 chiffres"),
});

export const schemaReglement = z.strictObject({
  montant: z.number().int().positive().max(100_000_000),
  frequence: z.enum(["hebdomadaire", "mensuelle"]),
  nombreMembres: z.number().int().min(3).max(50),
  penaliteRetard: z.number().int().min(0),
  delaiGraceJours: z.number().int().min(0).max(30),
  ouvert: z.boolean(),
  /** Jours avant la date limite où l'assistant peut rappeler. Absent : aucun rappel avant l'échéance. */
  rappelsAvantEcheanceJours: z.array(z.number().int().min(1).max(30)).max(5).optional(),
  /** Date et heure limite des cotisations du premier tour (choix de David, 05/11). */
  datePremierTour: z.iso.datetime(),
});

export const schemaCreationCercle = z.strictObject({ reglement: schemaReglement, signature: z.string().min(1) });
export const schemaAdhesion = z.strictObject({ signature: z.string().min(1) });

export const schemaPaiement = z.strictObject({ referenceTransaction: z.string().trim().min(1).max(64) });

export const schemaOuvertureLitige = z.strictObject({
  cotisationId: z.uuid(),
  motif: z.string().trim().min(1).max(500),
});

export const schemaDecisionLitige = z.strictObject({
  decision: z.enum(["paiement_valide", "paiement_refuse"]),
  motif: z.string().trim().min(1).max(500),
});

export const schemaModeAssistant = z.strictObject({ mode: z.enum(["autonome", "manuel"]) });
