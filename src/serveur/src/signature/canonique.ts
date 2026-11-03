/** JSON à clés triées : le téléphone et le serveur doivent signer exactement les mêmes octets. */
export function canonique(valeur: unknown): string {
  if (Array.isArray(valeur)) return `[${valeur.map(canonique).join(",")}]`;
  if (valeur && typeof valeur === "object") {
    const o = valeur as Record<string, unknown>;
    return `{${Object.keys(o)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${canonique(o[k])}`)
      .join(",")}}`;
  }
  return JSON.stringify(valeur);
}
