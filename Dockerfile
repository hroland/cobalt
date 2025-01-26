FROM node:23-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Use ARG to pass the RAILWAY_SERVICE_ID environment variable
ARG RAILWAY_SERVICE_ID
ENV RAILWAY_SERVICE_ID=$RAILWAY_SERVICE_ID

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

# Use the RAILWAY_SERVICE_ID in the cache mount ID
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app
COPY --from=build --chown=node:node /app/.git /app/.git

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
