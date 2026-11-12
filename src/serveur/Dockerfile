# Image de production du serveur MonDo. À construire depuis la racine du dépôt :
#   docker build -f src/serveur/Dockerfile -t mondo-serveur .
# Le .dockerignore de la racine ne laisse entrer que le serveur et les fichiers du monorepo.

FROM node:22-bookworm-slim AS construction
WORKDIR /depot
RUN corepack enable
# Les manifestes d'abord : la couche des dépendances n'est refaite que s'ils changent.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json ./
COPY src/serveur/package.json src/serveur/
COPY src/contrat/package.json src/contrat/
RUN pnpm install --frozen-lockfile --filter @mondo/serveur
COPY src/serveur src/serveur
RUN pnpm --filter @mondo/serveur build
# Ne garder que les dépendances de production.
RUN rm -rf node_modules src/serveur/node_modules \
 && pnpm install --frozen-lockfile --prod --filter @mondo/serveur

FROM node:22-bookworm-slim
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app
COPY --from=construction /depot/node_modules ./node_modules
COPY --from=construction /depot/src/serveur/node_modules ./src/serveur/node_modules
COPY --from=construction /depot/src/serveur/dist ./src/serveur/dist
COPY --from=construction /depot/src/serveur/package.json ./src/serveur/package.json
# Jamais root : l'utilisateur « node » de l'image officielle (uid 1000), sans droit d'écriture sur le code.
USER node
WORKDIR /app/src/serveur
EXPOSE 3000
# L'hébergeur et Docker savent si le serveur répond et si la base est joignable.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/sante').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
CMD ["node", "--enable-source-maps", "dist/main.js"]
