import tseslint from "typescript-eslint";

export default tseslint.config({ ignores: ["dist/", "coverage/", "node_modules/"] }, ...tseslint.configs.recommended, {
  rules: {
    "no-console": "error",
    eqeqeq: "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/consistent-type-imports": "error",
    // Retirer un champ par déstructuration ({ objet: _objet, ...reste }) est voulu.
    "@typescript-eslint/no-unused-vars": [
      "error",
      { ignoreRestSiblings: true, varsIgnorePattern: "^_", argsIgnorePattern: "^_" },
    ],
  },
});
