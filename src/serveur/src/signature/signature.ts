import { createPublicKey, verify } from "node:crypto";

/**
 * Vérifie une signature ECDSA P-256 / SHA-256 produite par le téléphone.
 * La clé privée ne quitte jamais le téléphone : le serveur ne connaît que la clé publique (JWK).
 * Format de signature : r||s en base64, celui de WebCrypto.
 */
export function verifierSignature(clePubliqueJwk: JsonWebKey, message: string, signatureBase64: string): boolean {
  try {
    const cle = createPublicKey({ key: clePubliqueJwk, format: "jwk" });
    return verify(
      "sha256",
      Buffer.from(message),
      { key: cle, dsaEncoding: "ieee-p1363" },
      Buffer.from(signatureBase64, "base64"),
    );
  } catch {
    return false;
  }
}
