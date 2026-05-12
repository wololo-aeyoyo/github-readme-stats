FROM node:22-alpine AS base

# Dependencies stage - installs only production dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN npm ci --omit=dev --ignore-scripts

# Builder stage - prepares application files
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Runner stage - production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/api ./api
COPY --from=builder /app/themes ./themes
COPY --from=builder /app/express.js ./express.js

EXPOSE 3000
CMD ["node", "express.js"]