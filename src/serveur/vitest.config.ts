import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    coverage: {
      provider: "v8",
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.test.ts", "src/main.ts", "src/testing/**"],
      thresholds: { lines: 85, functions: 85, branches: 75, statements: 85 },
    },
  },
});
