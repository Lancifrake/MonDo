import { z } from "zod";
import { periodeMinimaleJours } from "../modules/cotisations/calendrier.js";

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

export const schemaContactConfiance = z.strictObject({
  nom: z.string().trim().min(1).max(100),
  numero: schemaNumero,
});
export const schemaAccordContact = z.strictObject({ code: z.string().regex(/^\d{6}$/, "Code à 6 chiffres") });

/** Image en base64 ; la taille et le format réels sont contrôlés par le service, sur les octets décodés. */
const schemaImage = z
  .string()
  .min(1)
  .max(2_900_000)
  .regex(/^[A-Za-z0-9+/]+={0,2}$/, "Image en base64");
export const schemaDepotIdentite = z.strictObject({
  typePiece: z.enum(["cni", "passeport"]),
  /** Consentement explicite : la valeur vraie, rien d'autre. */
  consentement: z.literal(true),
  versionConsentement: z.string().min(1).max(20),
  recto: schemaImage,
  verso: schemaImage,
  selfie: schemaImage,
});
export const schemaDecisionIdentite = z.strictObject({
  decision: z.enum(["validee", "refusee"]),
  motif: z.string().trim().min(1).max(500),
});

export const schemaCodeSecret = z.strictObject({
  code: z.string().regex(/^\d{4,8}$/, "Code secret de 4 à 8 chiffres"),
});
export const schemaDemandeRecuperation = z.strictObject({
  numero: schemaNumero,
  clePublique: schemaClePublique,
  preuve: z.string().min(1).max(200),
  codeOtp: z.string().regex(/^\d{6}$/, "Code SMS à 6 chiffres"),
  codeSecret: z
    .string()
    .regex(/^\d{4,8}$/)
    .optional(),
});
export const schemaPiecesRecuperation = schemaDepotIdentite.extend({
  horodatage: z.iso.datetime(),
  preuve: z.string().min(1).max(200),
});
export const schemaDecisionRecuperation = z.strictObject({
  decision: z.enum(["titulaire_confirme", "recuperation_acceptee"]),
  motif: z.string().trim().min(1).max(500),
});

export const schemaInscription = z.strictObject({
  numero: schemaNumero,
  nom: z.string().trim().min(1).max(100),
  clePublique: schemaClePublique,
  preuve: z.string().min(1),
  codeOtp: z.string().regex(/^\d{6}$/, "Code SMS à 6 chiffres"),
});

export const schemaReglement = z
  .strictObject({
    montant: z.number().int().positive().max(100_000_000),
    /** hebdomadaire, mensuelle (même jour chaque mois) ou jours : tous les `periodeJours` jours, au choix du cercle. */
    frequence: z.enum(["hebdomadaire", "mensuelle", "jours"]),
    periodeJours: z.number().int().min(1).max(60).optional(),
    nombreMembres: z.number().int().min(3).max(50),
    penaliteRetard: z.number().int().min(0),
    delaiGraceJours: z.number().int().min(0).max(30),
    ouvert: z.boolean(),
    /** Jours avant la date limite où l'assistant peut rappeler. Absent : aucun rappel avant l'échéance. */
    rappelsAvantEcheanceJours: z.array(z.number().int().min(1).max(30)).max(5).optional(),
    /** Date et heure limite des cotisations du premier tour (choix de David, 05/11). */
    datePremierTour: z.iso.datetime(),
    /**
     * Cercle privé seulement (choix de David, 11/11) : l'organisateur fixe l'ordre de passage, identifiants des
     * membres du premier au dernier. Chacun signe le règlement en connaissant cet ordre.
     */
    ordreFixe: z.array(z.uuid()).min(3).max(50).optional(),
    /** Score minimum pour rejoindre le cercle, fixé par l'organisateur (cahier des charges, M3). */
    scoreMinimum: z.number().int().min(0).max(100).optional(),
    /** Frais du modèle A en francs, place par place ; l'exactitude est contrôlée par le service. */
    bareme: z
      .array(
        z.strictObject({
          place: z.number().int().min(1).max(16),
          frais: z.number().int().min(0),
          partMonDo: z.number().int().min(0),
          remiseParPlaceDeFin: z.number().int().min(0),
        }),
      )
      .max(16)
      .optional(),
  })
  .superRefine((r, ctx) => {
    if ((r.frequence === "jours") !== (r.periodeJours !== undefined)) {
      ctx.addIssue({
        code: "custom",
        path: ["periodeJours"],
        message: "Nombre de jours obligatoire avec « jours », interdit sinon",
      });
      return;
    }
    if (r.ordreFixe) {
      const probleme = r.ouvert
        ? "L'ordre fixé par l'organisateur est réservé aux cercles privés"
        : r.ordreFixe.length !== r.nombreMembres
          ? "L'ordre fixé doit nommer chaque membre, ni plus ni moins"
          : new Set(r.ordreFixe).size !== r.ordreFixe.length
            ? "Un membre ne figure qu'une fois dans l'ordre fixé"
            : undefined;
      if (probleme) ctx.addIssue({ code: "custom", path: ["ordreFixe"], message: probleme });
    }
    // Sinon le tour suivant commence avant que le défaut du précédent soit constaté.
    if (r.delaiGraceJours >= periodeMinimaleJours(r.frequence, r.periodeJours)) {
      ctx.addIssue({
        code: "custom",
        path: ["delaiGraceJours"],
        message: "Le délai de grâce doit être plus court que la période",
      });
    }
  });

/** Place souhaitée, signée dans l'engagement (1 = premier à recevoir) ; bornée au nombre de membres par le service. */
const schemaPlace = z.number().int().min(1).max(50);
export const schemaCreationCercle = z.strictObject({
  reglement: schemaReglement,
  placeSouhaitee: schemaPlace,
  signature: z.string().min(1),
  /** Cycle suivant d'un cercle terminé, relancé par son organisateur. */
  cerclePrecedentId: z.uuid().optional(),
});
export const schemaAdhesion = z.strictObject({ placeSouhaitee: schemaPlace, signature: z.string().min(1) });

export const schemaPropositionEchange = z.strictObject({
  avecMembreId: z.uuid(),
  signature: z.string().min(1).max(200),
});
export const schemaAcceptationEchange = z.strictObject({ signature: z.string().min(1).max(200) });

export const schemaAvanceDemonstration = z.strictObject({ jours: z.number().int().min(1).max(400) });

export const schemaInvitation = z.strictObject({ numero: schemaNumero });

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
