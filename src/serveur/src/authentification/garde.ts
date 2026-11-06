import {
  type CanActivate,
  type ExecutionContext,
  Inject,
  Injectable,
  SetMetadata,
  UnauthorizedException,
  createParamDecorator,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { ComptesService } from "../modules/comptes/comptes.service.js";
import { verifierSignature } from "../signature/signature.js";
import { messageRequete } from "./messages.js";

const CLE_PUBLIC = "mondo:public";
/** Route accessible sans requête signée (seulement l'inscription). */
export const Public = () => SetMetadata(CLE_PUBLIC, true);

/** Une requête signée n'est valable que 5 minutes, et une seule fois. */
export const FENETRE_MS = 5 * 60 * 1000;

interface RequeteHttp {
  method: string;
  originalUrl: string;
  body: unknown;
  headers: Record<string, string | string[] | undefined>;
  membreId?: string;
}

/** Identité du membre, prouvée par la signature de son téléphone : jamais lue dans le corps de la requête. */
export const MembreAuthentifie = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string => ctx.switchToHttp().getRequest<RequeteHttp>().membreId!,
);

@Injectable()
export class GardeAuthentification implements CanActivate {
  constructor(
    @Inject(Reflector) private readonly reflector: Reflector,
    @Inject(ComptesService) private readonly comptes: ComptesService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(CLE_PUBLIC, [ctx.getHandler(), ctx.getClass()])) return true;
    const req = ctx.switchToHttp().getRequest<RequeteHttp>();
    const entete = (nom: string) => {
      const v = req.headers[nom];
      return typeof v === "string" ? v : undefined;
    };
    const membreId = entete("x-mondo-membre");
    const horodatage = entete("x-mondo-horodatage");
    const signature = entete("x-mondo-signature");
    if (!membreId || !horodatage || !signature) throw new UnauthorizedException("Requête non signée");

    const instant = Date.parse(horodatage);
    if (Number.isNaN(instant) || Math.abs(Date.now() - instant) > FENETRE_MS) {
      throw new UnauthorizedException("Horodatage hors délai");
    }
    const compte = await this.comptes.chercher(membreId);
    const message = messageRequete(req.method, req.originalUrl, horodatage, req.body);
    if (!compte || !verifierSignature(compte.clePublique, message, signature)) {
      throw new UnauthorizedException("Signature invalide");
    }
    // Après la vérification : on ne laisse pas un inconnu remplir la table des signatures.
    if (!(await this.comptes.marquerRequeteVue(membreId, message, new Date(instant + FENETRE_MS)))) {
      throw new UnauthorizedException("Requête déjà utilisée");
    }
    req.membreId = membreId;
    return true;
  }
}
