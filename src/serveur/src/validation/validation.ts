import { BadRequestException, type PipeTransform } from "@nestjs/common";
import type { ZodType } from "zod";

/** Les types TypeScript disparaissent à l'exécution : chaque corps de requête est validé par un schéma. */
export class ValidationSchema<T> implements PipeTransform<unknown, T> {
  constructor(private readonly schema: ZodType<T>) {}

  transform(valeur: unknown): T {
    const r = this.schema.safeParse(valeur);
    if (!r.success) {
      throw new BadRequestException({
        message: "Entrée invalide",
        details: r.error.issues.map((i) => ({ champ: i.path.join("."), message: i.message })),
      });
    }
    return r.data;
  }
}
