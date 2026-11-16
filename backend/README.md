# Simpex Backend Service

Production-grade, industry-standard **Node.js (v24) + TypeScript** backend for **Simpex** (AI-Powered Voice Expense Tracker).

## Architecture Highlights

- **Clean Layered Architecture**: Decoupled HTTP transport (Controllers), business rules (Services), validated DTOs (Zod), and persistence (Mongoose).
- **Financial Precision Invariant**: All monetary values are strictly validated and stored as positive integers in minor units (`paise` for INR, ₹500.00 = `50000`). No floating-point math in financial records.
- **Idempotent Sync Engine**: Multi-operation batch synchronization (`/api/v1/sync/batch`) with client `operationId` deduplication and audit logging.
- **Agentic AI & Tool Pipeline (LangGraph.js)**: Small Language Model (SLM) communicates strictly through validated backend tools. Direct DB queries by the model are forbidden; confirmation is enforced before committing financial records.
- **Strict Multi-Tenancy**: Every database read/write query is explicitly scoped to `req.user.id`. Client-supplied user IDs are rejected.
- **Zero-Vulnerability Security**: Argon2id password hashing, rotating JWT Access + Refresh tokens, Helmet protection, rate limiting, and Pino structured logging with PII/secret redaction.

---

## Getting Started

### Prerequisites

- Node.js `v22+` (v24 recommended)
- MongoDB `v7+` (Local or Docker)
- Ollama (Optional, for local SLM voice intelligence)

### Installation

```bash
cd backend
npm install
```

### Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

### Running Locally

```bash
# Development mode with hot-reloading (tsx)
npm run dev

# Type check
npm run lint

# Run automated test suites (Vitest)
npm test

# Production build
npm run build
npm start
```

### Running via Docker Compose

```bash
docker compose up -d --build
```

---

## API Endpoints Reference

### Diagnostics & Health
- `GET /health/live` — Liveness probe (200 OK)
- `GET /health/ready` — Readiness probe (checks MongoDB connectivity)
- `GET /api/v1` — API metadata and versioning

### Authentication (`/api/v1/auth`)
- `POST /register` — Register user with email, name, password (Argon2id)
- `POST /login` — Authenticate and receive Access + Refresh tokens
- `POST /refresh` — Rotate refresh token and receive new Access token
- `POST /logout` — Invalidate user session
- `GET /me` — Get authenticated profile
- `PATCH /me` — Update user preferences (currency, locale, display name)

### Categories (`/api/v1/categories`)
- `GET /` — Fetch 12 system default categories + user custom categories
- `POST /` — Create custom category
- `PATCH /:id` — Update or archive custom category

### Expenses (`/api/v1/expenses`)
- `POST /` — Create expense (supports `Idempotency-Key` header)
- `GET /` — Paginated querying with date range, category, amount, and search filters
- `GET /:id` — Fetch single transaction
- `PUT /:id` — Update transaction
- `DELETE /:id` — Soft-delete transaction

### Offline Sync Engine (`/api/v1/sync`)
- `POST /batch` — Submit offline transaction queue with idempotency resolution

### Deterministic Analytics (`/api/v1/analytics`)
- `GET /summary` — Today, monthly spend, and month-over-month percentage
- `GET /category-breakdown` — Category-wise spend distribution & percentages

### Agentic Voice Assistant (`/api/v1/assistant`)
- `POST /chat` — Conversational expense extraction, clarification, live corrections, and confirmation
