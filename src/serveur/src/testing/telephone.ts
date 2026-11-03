/** Joue le rôle du téléphone (WebCrypto) dans les tests : clé privée locale, seule la clé publique sort. */
export async function nouveauTelephone() {
  const paire = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const clePublique = (await crypto.subtle.exportKey("jwk", paire.publicKey)) as JsonWebKey;
  const signer = async (message: string) =>
    Buffer.from(
      await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, paire.privateKey, new TextEncoder().encode(message)),
    ).toString("base64");
  return { clePublique, signer };
}
