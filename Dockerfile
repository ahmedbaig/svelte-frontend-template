FROM node:26-alpine AS build
ARG APP=example
ARG PUBLIC_API_BASE=""
ENV CI=1 \
    PUBLIC_API_BASE=${PUBLIC_API_BASE}
WORKDIR /repo
RUN npm install -g pnpm@12.21.0
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY apps/shell/package.json apps/shell/
COPY apps/example/package.json apps/example/
COPY packages/sdk/package.json packages/sdk/
COPY packages/ui/package.json packages/ui/
COPY packages/mock/package.json packages/mock/
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm --filter "@dashboard/${APP}" build \
 && mkdir -p /out \
 && cp -R "apps/${APP}/dist/app/." /out/ \
 && if [ -d "apps/${APP}/dist/module" ]; then cp -R "apps/${APP}/dist/module" /out/module; fi

FROM nginxinc/nginx-unprivileged:1.31-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build --chown=101:101 /out /usr/share/nginx/html
USER 101
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]
