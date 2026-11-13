import { BadRequestException, ForbiddenException, Inject, Injectable } from "@nestjs/common";
import { generateKeyPairSync, sign, type KeyObject } from "node:crypto";
import { messageInscription } from "../../authentification/messages.js";
import { CONNECTEUR_SMS, type ConnecteurSms, type ConnecteurSmsSimule } from "../../sms/connecteur-sms.js";
import { FileSms } from "../../sms/file-sms.js";
import { CerclesService, messageEngagement, type Cercle } from "../cercles/cercles.service.js";
import { ComptesService } from "../comptes/comptes.service.js";
import { OtpService } from "../comptes/otp.service.js";
import { CotisationsService } from "../cotisations/cotisations.service.js";
import { PlanificateurService } from "../planificateur/planificateur.service.js";

const JOUR_MS = 24 * 60 * 60 * 1000;

interface MembreFictif {
  id: string;
  cle: KeyObject;
  /** Le dernier membre fictif d'un cercle cesse de payer après le premier tour : c'est le défaut de la démonstration. */
  defaillant: boolean;
}

/**
 * Outils de démonstration, refusés en production. Ils servent à montrer un cycle entier en quelques minutes
 * avec un seul téléphone : des membres fictifs complètent le cercle du membre réel et jouent leur rôle, et le
 * temps avance à la demande. Rien n'est truqué dans les règles : les membres fictifs s'inscrivent, signent et
 * paient par les mêmes services que tout le monde, avec leur propre clé. Leurs clés ne vivent qu'en mémoire.
 */
@Injectable()
export class DemonstrationService {
  private readonly fictifs = new Map<string, MembreFictif[]>();
  private suivant = 0;

  constructor(
    @Inject(ComptesService) private readonly comptes: ComptesService,
    @Inject(OtpService) private readonly otp: OtpService,
    @Inject(CerclesService) private readonly cercles: CerclesService,
    @Inject(CotisationsService) private readonly cotisations: CotisationsService,
    @Inject(PlanificateurService) private readonly planificateur: PlanificateurService,
    @Inject(CONNECTEUR_SMS) private readonly sms: ConnecteurSms,
    @Inject(FileSms) private readonly file: FileSms,
  ) {}

  /** Complète le cercle avec des membres fictifs, jusqu'au nombre prévu par le règlement. */
  async remplir(cercleId: string, parMembreId: string): Promise<{ membresFictifs: number }> {
    const cercle = await this.autoriser(cercleId, parMembreId);
    if (cercle.reglement.ordreFixe) {
      throw new BadRequestException("Pas de membres fictifs dans un cercle à ordre fixé : l'ordre nomme ses membres");
    }
    const manquants = cercle.statut === "en_attente" ? cercle.reglement.nombreMembres - cercle.membres.length : 0;
    const liste = this.fictifs.get(cercleId) ?? [];
    this.fictifs.set(cercleId, liste);
    for (let i = 0; i < manquants; i++) {
      const membre = await this.inscrire();
      if (cercle.reglement.ouvert) await this.comptes.passerAuNiveau2(membre.id);
      // Tous demandent la dernière place, toujours permise : l'attribution ordinaire fait le reste.
      const place = cercle.reglement.nombreMembres;
      await this.cercles.rejoindre(cercleId, {
        membreId: membre.id,
        placeSouhaitee: place,
        signature: signer(membre.cle, messageEngagement(cercleId, cercle.empreinteReglement, membre.id, place)),
      });
      liste.push(membre);
    }
    if (manquants > 0) liste.forEach((m, i) => (m.defaillant = i === liste.length - 1));
    return { membresFictifs: manquants };
  }

  /**
   * Fait jouer les membres fictifs pour le tour en cours : chacun déclare sa cotisation (sauf le défaillant
   * après le premier tour), et celui qui reçoit confirme tous les paiements déclarés vers lui, y compris celui
   * du membre réel. Si c'est le membre réel qui reçoit, il confirme lui-même sur son téléphone.
   */
  async jouerLaSuite(cercleId: string, parMembreId: string) {
    const cercle = await this.autoriser(cercleId, parMembreId);
    const fictifs = this.fictifs.get(cercleId) ?? [];
    if (cercle.statut !== "complet" || fictifs.length === 0) {
      throw new BadRequestException("Rien à jouer : le cercle doit être complet, avec des membres fictifs");
    }
    const parMembre = await Promise.all(
      [parMembreId, ...fictifs.map((m) => m.id)].map((id) => this.cotisations.listerDuMembre(cercleId, id)),
    );
    const ouvertes = parMembre.flat().filter((c) => c.statut === "due" || c.statut === "declaree");
    if (ouvertes.length === 0) return { tour: 0, paiementsDeclares: 0, confirmations: 0, termine: true };
    const tour = Math.min(...ouvertes.map((c) => c.tour));
    let paiementsDeclares = 0;
    let confirmations = 0;
    for (const m of fictifs) {
      if (m.defaillant && tour > 1) continue;
      for (const c of await this.cotisations.listerDuMembre(cercleId, m.id)) {
        if (c.tour !== tour || c.payeurId !== m.id || c.statut !== "due") continue;
        await this.cotisations.declarerPaiement(c.id, `DEMO-${tour}-${m.id.slice(0, 8)}`, m.id);
        paiementsDeclares++;
      }
    }
    for (const m of fictifs) {
      for (const c of await this.cotisations.listerDuMembre(cercleId, m.id)) {
        if (c.tour !== tour || c.beneficiaireId !== m.id || c.statut !== "declaree") continue;
        await this.cotisations.confirmer(c.id, m.id);
        confirmations++;
      }
    }
    return { tour, paiementsDeclares, confirmations, termine: false };
  }

  /** Avance le temps du cercle de N jours (ses dates reculent d'autant), puis fait passer le planificateur. */
  async avancer(cercleId: string, parMembreId: string, jours: number) {
    await this.autoriser(cercleId, parMembreId);
    await this.cotisations.reculerDatesPourDemonstration(cercleId, jours * JOUR_MS);
    const { traitees, echecs } = await this.planificateur.examinerEcheances();
    await this.file.vider();
    return { jours, tachesTraitees: traitees, echecs };
  }

  private async autoriser(cercleId: string, parMembreId: string): Promise<Cercle> {
    if (process.env.NODE_ENV === "production") {
      throw new ForbiddenException("Outils de démonstration désactivés en production");
    }
    const cercle = await this.cercles.trouver(cercleId);
    if (cercle.organisateurId !== parMembreId) {
      throw new ForbiddenException("Réservé à l'organisateur du cercle de démonstration");
    }
    return cercle;
  }

  /** Inscription ordinaire d'un membre fictif : numéro inventé, code lu dans la passerelle SMS simulée. */
  private async inscrire(): Promise<MembreFictif> {
    const { publicKey, privateKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
    const jwk = publicKey.export({ format: "jwk" });
    const clePublique = { kty: "EC", crv: "P-256", x: jwk.x!, y: jwk.y! } as JsonWebKey;
    const n = ++this.suivant;
    const donnees = {
      numero: `+2376990${String(Date.now() % 10000).padStart(4, "0")}${String(n).padStart(2, "0")}`.slice(0, 16),
      nom: `Membre fictif ${n}`,
      clePublique,
    };
    await this.otp.demander(donnees.numero);
    const messages = (this.sms as ConnecteurSmsSimule).messages ?? [];
    const code = /(\d{6})/.exec([...messages].reverse().find((m) => m.numero === donnees.numero)?.texte ?? "")?.[1];
    if (!code) throw new BadRequestException("Membres fictifs impossibles sans passerelle SMS simulée");
    const compte = await this.comptes.inscrire({
      ...donnees,
      preuve: signer(privateKey, messageInscription(donnees)),
      codeOtp: code,
    });
    return { id: compte.id, cle: privateKey, defaillant: false };
  }
}

/** Même format que le téléphone : ECDSA P-256, SHA-256, r||s en base64. */
const signer = (cle: KeyObject, message: string) =>
  sign("sha256", Buffer.from(message), { key: cle, dsaEncoding: "ieee-p1363" }).toString("base64");
