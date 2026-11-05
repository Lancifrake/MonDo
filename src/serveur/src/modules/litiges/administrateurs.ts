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
