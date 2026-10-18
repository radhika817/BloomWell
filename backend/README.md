# BloomWell Backend 🌸

The FastAPI backend foundation for BloomWell: a privacy-first menstrual wellness, self-care, and peer-support platform for women students.

---

## Architecture Overview

Built following `docs/architecture.md` (Sections 5, 6, 7, 12, 14, 17):
- **Framework:** FastAPI with asynchronous ASGI handling and Starlette middleware.
- **ORM & Database:** SQLAlchemy 2.x declarative models and Alembic migrations.
- **Database Engine:** PostgreSQL via `psycopg` (with SQLite support for rapid in-memory isolated tests).
- **Configuration:** `pydantic-settings` reading environment variables exclusively from `.env`.
- **Security & Privacy:**
  - Zero-logging of sensitive fields (`password`, `token`, `journal`, `body`, `notes`, `email`, `authorization`).
  - Strict redaction filter on all log messages.
  - In-memory per-process rate limiting.
  - Production startup guard rejecting placeholder `APP_SECRET_KEY` values.
  - Standardized JSON error response format (`code`, `message`, `details`, `request_id`).
  - Correlation ID middleware (`X-Request-ID`).
  - Strict CORS origin filtering.

---

## Directory Structure

```text
backend/
├── app/
│   ├── api/
│   │   ├── health.py            # GET /health database connectivity probe
│   │   └── v1/
│   │       └── router.py        # /v1 prefix router mount
│   ├── core/
│   │   ├── config.py            # Pydantic Settings with production validation
│   │   ├── logging.py           # Structured JSON logger and redaction filter
│   │   └── security.py          # In-memory rate limiter dependency
│   ├── db/
│   │   ├── base.py              # DeclarativeBase, GUID type, TimestampMixin
│   │   └── session.py           # SQLAlchemy engine & session dependency
│   ├── models/
│   │   ├── user.py              # User model (UUID pk, email, password_hash, role)
│   │   ├── preference.py        # UserPreference model (timezone, language, consent timestamps)
│   │   └── token.py             # RefreshToken family model (token_hash, rotation tracking)
│   ├── schemas/
│   │   ├── error.py             # Standardized problem-details error schema
│   │   └── health.py            # Health check response schema
│   ├── services/                # Business logic services (boundary isolated)
│   ├── repositories/            # Owner-scoped data repositories
│   └── main.py                  # Application factory, middleware & error handlers
├── migrations/
│   ├── versions/
│   │   └── 0001_initial_tables.py # Initial migration (users, user_preferences, refresh_tokens)
│   ├── env.py                   # Alembic environment runner
│   └── script.py.mako           # Migration template
├── tests/
│   ├── conftest.py              # Test database engine and TestClient fixtures
│   ├── test_config.py           # Production secret validation and CORS tests
│   ├── test_errors.py           # Consistent error shape and request-ID tests
│   ├── test_health.py           # /health endpoint checks
│   ├── test_logging.py          # Proves journal text & tokens never appear in logs
│   └── test_rate_limiter.py     # In-memory rate limiter tests
├── Dockerfile                   # Python container image definition
├── alembic.ini                  # Alembic CLI configuration
├── requirements.txt             # Pinned resolved dependency specifications
└── README.md                    # This developer documentation
```

---

## Getting Started

Follow these exact steps to run the backend locally:

### 1. Copy Environment Configuration
```bash
cp .env.example .env
```
*(Verify and edit `.env` if custom credentials or local ports are desired).*

### 2. Start PostgreSQL with Docker Compose
```bash
docker compose up -d db
```
The PostgreSQL database service binds to `127.0.0.1:5432` and performs automatic healthchecks.
*(Note: If you recently added your user to the `docker` group with `sudo usermod -aG docker $USER`, run `newgrp docker` or log out/in for permissions to take effect).*

### 3. Create and Activate Virtual Environment
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
```

### 4. Install Dependencies
```bash
pip install -r requirements.txt
```

### 5. Run Database Migrations
```bash
alembic upgrade head
```

### 6. Start Development Server
```bash
uvicorn app.main:app --reload
```
The API is available at `http://localhost:8000`. OpenAPI documentation is available at `http://localhost:8000/docs`.

### 7. Run Automated Tests
```bash
pytest
```

---

## Endpoints

| Method | Path | Description | Access |
|---|---|---|---|
| `GET` | `/health` | Service & DB connectivity check | Public |
| `GET` | `/v1/info` | V1 API information baseline | Public |

---

## Rate Limiting Architecture Note

The included `rate_limit` dependency (`app.core.security.InMemoryRateLimiter`) operates **in-memory and per-process**. 

When scaling horizontally across multiple processes (e.g. multiple Uvicorn workers or container instances behind an AWS Application Load Balancer), this must be backed by a centralized store (such as Redis) to synchronize rate limits across workers.
