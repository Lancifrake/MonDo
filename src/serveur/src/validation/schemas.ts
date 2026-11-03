import { z } from "zod";

export const schemaClePublique = z.strictObject({
  kty: z.literal("EC"),
  crv: z.literal("P-256"),
  x: z.string().min(1),
  y: z.string().min(1),
  ext: z.boolean().optional(),
  key_ops: z.array(z.string()).optional(),
});

export const schemaInscription = z.strictObject({
  numero: z.string().regex(/^\+?\d{8,15}$/, "Numéro de téléphone invalide"),
  nom: z.string().trim().min(1).max(100),
  clePublique: schemaClePublique,
  preuve: z.string().min(1),
});

export const schemaReglement = z.strictObject({
  montant: z.number().int().positive().max(100_000_000),
  frequence: z.enum(["hebdomadaire", "mensuelle"]),
  nombreMembres: z.number().int().min(3).max(50),
  penaliteRetard: z.number().int().min(0),
  delaiGraceJours: z.number().int().min(0).max(30),
  ouvert: z.boolean(),
});

export const schemaCreationCercle = z.strictObject({ reglement: schemaReglement, signature: z.string().min(1) });
export const schemaAdhesion = z.strictObject({ signature: z.string().min(1) });

export const schemaCreationCotisation = z.strictObject({
  cercleId: z.string().min(1),
  beneficiaireId: z.string().min(1),
  montant: z.number().int().positive(),
  dateLimite: z.iso.datetime(),
});

export const schemaPaiement = z.strictObject({ referenceTransaction: z.string().trim().min(1).max(64) });
