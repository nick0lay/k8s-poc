# Kubernetes POC Project

This project is a proof-of-concept (POC) for deploying a TypeScript Fastify service on AWS EKS. It uses CDKTF for infrastructure definition and is organized as a Turborepo monorepo.

## Project Structure

- **apps/fastify-api**: The Fastify application with a basic health check endpoint
- **packages/shared**: Shared code and utilities used across applications
- **infrastructure**: CDKTF code for defining AWS infrastructure

## Getting Started

### Prerequisites

- Node.js 18+
- PNPM
- Docker (for containerization)
- AWS CLI (for deployment)

### Development

1. Install dependencies:
   ```
   pnpm install
   ```

2. Start the development server:
   ```
   pnpm run dev
   ```

3. Build the project:
   ```
   pnpm run build
   ```

## Implementation Plan

This project follows a phased implementation approach as outlined in the `plan.md` file at the root of the repository.

## License

MIT
