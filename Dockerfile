FROM node:20-alpine AS builder

# Install pnpm
RUN npm install -g pnpm@9.0.0

WORKDIR /app

# Copy package files for the monorepo
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Copy shared configs and packages that might be needed
COPY packages/ ./packages/
COPY apps/fastify-api/package.json ./apps/fastify-api/

# Install dependencies
RUN pnpm install

# Copy application source
COPY apps/fastify-api/ ./apps/fastify-api/

# Build application
RUN pnpm --filter fastify-api build

FROM node:20-alpine AS runner

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@9.0.0

# Copy package files for production
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=builder /app/apps/fastify-api/package.json ./apps/fastify-api/

# Install production dependencies only
RUN pnpm --filter fastify-api install --prod

# Copy built application from builder stage
COPY --from=builder /app/apps/fastify-api/dist ./apps/fastify-api/dist

# Set non-root user
USER node

# Set environment variables
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NODE_ENV=production

WORKDIR /app/apps/fastify-api

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "dist/index.js"] 