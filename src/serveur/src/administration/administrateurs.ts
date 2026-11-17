/**
 * Prototype : les administrateurs sont des comptes membres listés dans `MONDO_ADMINISTRATEURS`
 * (identifiants séparés par des virgules), lue à chaque appel. Une vraie administration web viendra plus tard.
 */
export function estAdministrateur(membreId: string, env: NodeJS.ProcessEnv = process.env): boolean {
  return (env.MONDO_ADMINISTRATEURS ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .includes(membreId);
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Les identifiants de la liste, tels qu'on peut les passer à une requête (ceux qui ne sont pas des UUID sont ignorés). */
export function identifiantsAdministrateurs(env: NodeJS.ProcessEnv = process.env): string[] {
  return (env.MONDO_ADMINISTRATEURS ?? "")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter((s) => UUID.test(s));
}
