FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

# Copy package.json
COPY package.json ./

# Install production dependencies only
RUN npm install --omit=dev

# Copy built application
COPY --from=builder /app/dist ./dist

# Set non-root user
USER node

# Set environment variables
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "dist/index.js"] 