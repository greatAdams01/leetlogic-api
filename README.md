# Leetlogic Phase One

TypeScript foundation for Leetlogic's Nigeria-first farmer-to-buyer marketplace.

## Prerequisites

- Node.js 22+
- pnpm 11+
- Docker with Compose

## Setup

1. Copy `.env.example` to `.env` and replace all secrets.
   Generate `TOTP_ENCRYPTION_KEY` with `openssl rand -hex 32` (64 hex characters) or
   `openssl rand -base64 32` (a Base64-encoded 32-byte key).
2. Start PostgreSQL and Redis with `docker compose up -d`.
3. Install dependencies with `pnpm install`.
4. Generate the Prisma client with `pnpm db:generate`.
5. Apply migrations with `pnpm db:migrate`.
6. Seed languages, units, permissions and roles with `pnpm db:seed`.
7. Start the API with `pnpm dev`.

API documentation is available at `http://localhost:3000/docs`. Health endpoints are
`/health/live` and `/health/ready`.

## Database viewer

Docker Compose includes Adminer for local database inspection. After running
`docker compose up -d`, open `http://localhost:8080` and use:

- System: `PostgreSQL`
- Server: `postgres`
- Username: `leetlogic`
- Password: `leetlogic`
- Database: `leetlogic`

Adminer is bound to `127.0.0.1`, so it is only available from your computer. It is a development
tool and should not be deployed with the production stack.

In development, `OTP_PROVIDER=console` logs OTP codes rather than sending SMS. Do not use the
console provider in production.
