import { describe, expect, it } from "vitest";
import { verifierSignature } from "./signature.js";

// Le test joue le rôle du téléphone avec WebCrypto, comme le fera l'application mobile.
async function telephone() {
  const paire = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const clePublique = (await crypto.subtle.exportKey("jwk", paire.publicKey)) as JsonWebKey;
  const signer = async (m: string) =>
    Buffer.from(
      await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, paire.privateKey, new TextEncoder().encode(m)),
    ).toString("base64");
  return { clePublique, signer };
}

describe("signature ECDSA P-256", () => {
  it("accepte une signature valide faite par le téléphone", async () => {
    const t = await telephone();
    expect(verifierSignature(t.clePublique, "règlement v1", await t.signer("règlement v1"))).toBe(true);
  });

  it("refuse un message modifié après signature", async () => {
    const t = await telephone();
    expect(verifierSignature(t.clePublique, "règlement v2", await t.signer("règlement v1"))).toBe(false);
  });

  it("refuse la signature d'un autre téléphone", async () => {
    const [a, b] = [await telephone(), await telephone()];
    expect(verifierSignature(a.clePublique, "m", await b.signer("m"))).toBe(false);
  });

  it("refuse une signature illisible sans planter", async () => {
    const t = await telephone();
    expect(verifierSignature(t.clePublique, "m", "pas-une-signature")).toBe(false);
  });
});
