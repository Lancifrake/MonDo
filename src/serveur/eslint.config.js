import tseslint from "typescript-eslint";

export default tseslint.config({ ignores: ["dist/", "coverage/", "node_modules/"] }, ...tseslint.configs.recommended, {
  rules: {
    "no-console": "error",
    eqeqeq: "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/consistent-type-imports": "error",
  },
});
