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
The API is available at `http://localhost:8000`. OpenAPI documentation is available at `http://localhost:8000/docs` (served when `ENABLE_DOCS=true`; disabled by default in production).

For production deployment instructions, see [docs/deployment.md](../docs/deployment.md) and the [docs/launch-checklist.md](../docs/launch-checklist.md).

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
| `GET` | `/v1/resources` | List verified resources and product points | Public |
| `GET` | `/v1/resources/support` | 24x7 emergency helplines & free counseling | Public |
| `GET` | `/v1/resources/{id}` | Resource details | Public |
| `POST` | `/v1/resources/{id}/report` | Report broken or outdated resource | Student |
| `GET` | `/v1/me/resource-reports` | List caller's submitted reports | Student |
| `GET` | `/v1/education` | List educational articles (with EN fallback) | Public |
| `GET` | `/v1/education/{slug}` | Educational article details | Public |
| `POST` | `/v1/admin/resources` | Create resource | Admin |
| `PATCH` | `/v1/admin/resources/{id}` | Update resource | Admin |
| `DELETE` | `/v1/admin/resources/{id}` | Delete resource | Admin |
| `POST` | `/v1/admin/resources/{id}/verify` | Verify resource with official source | Admin |
| `POST` | `/v1/admin/resources/{id}/mark-outdated`| Flag resource as outdated | Admin |
| `GET` | `/v1/admin/resources?stale=true` | Audit unverified / stale resources | Admin |
| `GET` | `/v1/admin/resource-reports` | List community reports (reporter de-identified) | Admin |
| `PATCH` | `/v1/admin/resource-reports/{id}` | Resolve or dismiss report | Admin |
| `POST` | `/v1/admin/education` | Create educational article | Admin |
| `PATCH` | `/v1/admin/education/{id}` | Update review status and body | Admin |
| `DELETE` | `/v1/admin/education/{id}` | Delete educational article | Admin |

---

## Seed & Administration CLI Scripts

All scripts are executed from the repository root or `backend/` directory using the virtual environment:

### 1. Seed HelpHub Resources
Populates verified demo campus and community resources from `docs/seed/resources.demo.json`:
```bash
python scripts/seed_resources.py
```
Options:
- `--demo`: Seed fictional demo resources (default: reads from `docs/seed/resources.demo.json`).
- `--clear`: Clear existing seeded demo resources before seeding.

### 2. Seed Educational Content
Populates reviewed educational articles covering period basics, comfort, and care:
```bash
python scripts/seed_education.py
```
Options:
- `--clear`: Clear existing educational resources before seeding.

### 3. Assign User Role (Safety Protected)
Grants administrative or moderator roles to verified users without logging sensitive credentials:
```bash
python scripts/set_role.py user@example.edu resource_admin --yes
```
*Note: The `--yes` flag is mandatory to prevent accidental privilege escalation.*

---

## Rate Limiting Architecture Note

The included `rate_limit` dependency (`app.core.security.InMemoryRateLimiter`) operates **in-memory and per-process**. 

When scaling horizontally across multiple processes (e.g. multiple Uvicorn workers or container instances behind an AWS Application Load Balancer), this must be backed by a centralized store (such as Redis) to synchronize rate limits across workers.

---

## Doctor-Visit Summary Manual Testing Guide

Follow these steps to manually test the Doctor-visit Summary PDF generation end-to-end using fictional demo credentials:

### 1. Log In to Obtain an Access Token
```bash
curl -X POST http://localhost:8000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo.student@example.edu",
    "password": "demo-password-123"
  }'
```
Save the returned `access_token`.

### 2. Enable Cycle Tracking Consent
Cycle tracking must be active before generating a summary:
```bash
curl -X PUT http://localhost:8000/v1/me/cycle-tracking \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "cycle_tracking_enabled": true
  }'
```

### 3. Re-Authenticate to Obtain Step-Up Token
Generating sensitive health summaries requires recent re-authentication:
```bash
curl -X POST http://localhost:8000/v1/me/reauth \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "demo-password-123"
  }'
```
Save the returned `reauth_token`.

### 4. Generate Doctor Summary PDF
Request the summary PDF using fictional demo dates and categories:
```bash
curl -X POST http://localhost:8000/v1/me/doctor-summary \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "X-Reauth-Token: <REAUTH_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "from_date": "2026-01-01",
    "to_date": "2026-03-31",
    "include": {
      "periods": true,
      "symptoms": true,
      "symptom_notes": true,
      "estimate": true,
      "questions": true
    },
    "language": "en"
  }' \
  --output bloomwell-summary.pdf
```

### 5. Verify the Generated PDF
Open `bloomwell-summary.pdf` to verify:
- Clean A4 layout with neutral styling.
- Header: "Personal health notes summary", date range, generated timestamp.
- Strict anonymity: No names, emails, or user IDs anywhere in body or metadata.
- Periods section: "Recorded by me in BloomWell" table with start/end dates and cycle lengths.
- Symptoms section: Logged symptoms grouped by type and custom label, with dates and severity.
- Estimate section (if usable history exists): Date range labeled "Estimate. This can be wrong. Not medical advice."
- Questions section: 6 neutral discussion questions for clinician consults.
- Mandatory disclaimer at bottom: "This summary was created by the person from the dates and symptoms they recorded themselves. It is not a medical record, an assessment or a diagnosis."

