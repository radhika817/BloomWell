# BloomWell --- System Design

> Companion to the project README. Suggested location: `docs/architecture.md`.\
> Scope: v1 (6-week MVP) plus the path to a campus pilot.

## Contents

1.  [Goals, constraints, and assumptions](#1-goals-constraints-and-assumptions)
2.  [Capacity estimate](#2-capacity-estimate)
3.  [High-level architecture](#3-high-level-architecture)
4.  [Mobile app design](#4-mobile-app-design)
5.  [Backend design](#5-backend-design)
6.  [Data design](#6-data-design)
7.  [Authentication and authorization](#7-authentication-and-authorization)
8.  [Core algorithms](#8-core-algorithms)
9.  [AI gateway](#9-ai-gateway)
10. [Safety layer and community moderation](#10-safety-layer-and-community-moderation)
11. [Key flows](#11-key-flows)
12. [Security and threat model](#12-security-and-threat-model)
13. [Deployment architecture](#13-deployment-architecture)
14. [Reliability and observability](#14-reliability-and-observability)
15. [Scaling path](#15-scaling-path)
16. [Design decisions and trade-offs](#16-design-decisions-and-trade-offs)
17. [Schema additions to the README](#17-schema-additions-to-the-readme)
18. [Risks and open questions](#18-risks-and-open-questions)

------------------------------------------------------------------------

## 1. Goals, constraints, and assumptions

### Design goals (in priority order)

1.  **Protect sensitive data.** Cycle, symptom, mood, and journal records
    must be isolated per user, minimally exposed, and deletable.
2.  **Be demonstrable.** Privacy claims should be provable by tests and
    visible in a three-minute demo.
3.  **Stay simple.** A small team has six weeks; avoid infrastructure that
    does not pay for itself.
4.  **Degrade gracefully.** The app stays useful when AI, network, or
    optional features are unavailable.
5.  **Be explainable.** Insights and planner suggestions use transparent
    rules, not opaque models.

### Constraints

-   Team size is small; timeline is 6 weeks for MVP.
-   Stack is fixed: Flutter, FastAPI, PostgreSQL, AWS, LLM API via
    backend.
-   Not a medical device: no diagnosis, fertility prediction, or clinical
    claims.
-   Students may share phones and have limited connectivity.

### Non-functional requirements

| Area | Target (pilot) |
|---|---|
| Availability | 99% monthly for the API (planned maintenance excluded) |
| Latency | p95 under 300 ms for CRUD; p95 under 10 s for AI calls (hard timeout) |
| Durability | Daily automated backups; point-in-time recovery if using managed DB |
| Recovery | RPO of 24 h or better; RTO of 4 h |
| Security | HTTPS only; no cross-account data access; no sensitive text in logs |
| Privacy | Export and deletion available in-app; documented retention |
| Accessibility | Screen-reader labels, scalable text, sufficient contrast |
| Localization | No hard-coded UI strings; English first, Hindi and Marathi next |

### Assumptions

-   Hackathon load is below 50 concurrent users; a campus pilot is about
    5,000 registered students.
-   Most users use Android; iOS is supported by Flutter but tested less.
-   Content (activities, education, resources) is curated by the team,
    not user-generated.

## 2. Capacity estimate

Back-of-envelope numbers for a campus pilot, to show that a single small
deployment is sufficient.

| Quantity | Assumption | Result |
|---|---|---|
| Registered users | 5,000 | --- |
| Daily active users | 30% | about 1,500 |
| Requests per DAU per day | about 20 | about 30,000 per day |
| Average request rate | 30,000 / 86,400 | about 0.35 requests/s |
| Peak request rate | 10x average (exam weeks, evenings) | about 4--5 requests/s |
| Check-ins | 1 per DAU per day, about 200 bytes | about 0.3 MB per day |
| Journal text | 0.3 entries per DAU per day, about 2 KB | about 1 MB per day |
| Storage per user per year | check-ins + journal + cycles + logs | under 1 MB |
| Total after 1 year | 5,000 users | well under 5 GB |
| AI calls | 5% of DAU per day | about 75 per day |

**Conclusion:** one small application instance and one small PostgreSQL
instance handle the pilot with large headroom. The real bottlenecks are
the AI provider (latency, rate limits, cost) and moderation workload, not
compute or storage.

## 3. High-level architecture

``` mermaid
flowchart TB
    subgraph Device["Student device"]
        APP["Flutter app"]
        LOCK["Discreet Mode: app lock, privacy screen"]
        SAFE["On-device safety phrase check"]
        NOTIF["Local notifications"]
    end

    subgraph Edge["Edge"]
        TLS["HTTPS termination and rate limiting"]
    end

    subgraph Backend["FastAPI modular monolith"]
        API["API layer: routers, validation"]
        AUTH["Auth and RBAC"]
        SVC["Domain services"]
        AIGW["AI gateway"]
        PDF["PDF generator"]
    end

    subgraph Data["Data tier"]
        PG[("PostgreSQL")]
    end

    subgraph External["External"]
        LLM["LLM provider"]
    end

    APP --> LOCK
    APP --> SAFE
    APP --> NOTIF
    APP -->|HTTPS JSON| TLS
    TLS --> API
    API --> AUTH
    API --> SVC
    SVC --> AIGW
    SVC --> PDF
    SVC --> PG
    AUTH --> PG
    AIGW -->|consent-controlled| LLM
```

### Architectural style

A **modular monolith**: one deployable FastAPI service with strict
internal module boundaries. This gives simple deployment, transactional
consistency (important for deletion and export), and an easy path to
extract modules later if needed. Microservices and Kubernetes are
explicitly out of scope for v1.

## 4. Mobile app design

### Layering (per feature)

``` text
features/<name>/
  presentation/   widgets, screens, localized strings
  application/    Riverpod notifiers and controllers
  domain/         entities, use-case logic, validation
  data/           repositories, DTOs, Dio calls
```

Cross-cutting code lives in `core/`: API client, auth/session, routing,
theme, localization, and the privacy lock.

### Key mobile decisions

| Topic | Design |
|---|---|
| Navigation | GoRouter with redirect guards: unauthenticated, locked, and consent-missing states route to the right screen |
| API client | Single Dio instance with interceptors for auth header, language header, request ID, and error mapping to typed failures |
| Token handling | Access token in memory only; refresh token in platform secure storage; one in-flight refresh at a time (single-flight lock) to avoid refresh races |
| Local data | No on-disk cache of sensitive records in v1; in-memory state only. This avoids unencrypted copies of cycle or journal data on the device |
| App lock | PIN and/or biometrics via device APIs; lock after a short background timeout; privacy overlay in the app switcher; screenshot blocking on sensitive screens where supported |
| Reminders | Scheduled as **local notifications** with neutral text. No push server and no device token stored on the backend, so reminder timing and cycle estimates stay on the device |
| Safety phrase check | Runs locally on journal and check-in notes before save; shows a support card; the text never leaves the device because of this check |
| Offline behavior | v1 is online-first. Writes use a client-generated UUID (`client_id`) so retries are idempotent. A small retry queue for check-ins is a P2 improvement |
| Localization | ARB files for `en`, `hi`, `mr`; planner and insight text come from reason codes mapped to localized templates |
| Error handling | Every screen has loading, empty, error, and retry states; AI screens always have a non-AI fallback |

## 5. Backend design

### Module map

``` mermaid
flowchart LR
    subgraph API["api (routers)"]
        R1["auth"]
        R2["checkins and journal"]
        R3["cycles and symptoms"]
        R4["planner and insights"]
        R5["resources and education"]
        R6["ai"]
        R7["community"]
        R8["moderation and admin"]
        R9["privacy and summary"]
    end

    subgraph SVC["services"]
        S1["IdentityService"]
        S2["WellnessService"]
        S3["CycleService"]
        S4["PlannerService"]
        S5["ContentService"]
        S6["AIService"]
        S7["CommunityService"]
        S8["ModerationService"]
        S9["PrivacyService"]
    end

    subgraph REPO["repositories"]
        P1["Private repos: owner-scoped"]
        P2["Content repos: published data"]
        P3["Community repos"]
    end

    R1 --> S1
    R2 --> S2
    R3 --> S3
    R4 --> S4
    R5 --> S5
    R6 --> S6
    R7 --> S7
    R8 --> S8
    R9 --> S9
    S1 --> P1
    S2 --> P1
    S3 --> P1
    S4 --> P1
    S4 --> P2
    S5 --> P2
    S6 --> P1
    S6 --> P2
    S7 --> P3
    S8 --> P3
    S9 --> P1
    S9 --> P3
```

### Module rules (enforced in code review and lint)

-   **ModerationService and CommunityService must not import private
    repositories.** An import-boundary check (for example with
    `import-linter`) fails CI if they do. This makes "moderators cannot
    see private data" a structural property, not just a policy.
-   Every private repository method requires an explicit `user_id`
    argument. There is no "get by id" without an owner filter.
-   Routers contain no business logic; services contain no HTTP concerns.
-   Services return domain objects; Pydantic schemas live at the API
    boundary.
-   Settings and secrets come from environment/secret manager through one
    config module.

### API conventions

| Concern | Convention |
|---|---|
| Versioning | `/v1/...` prefix |
| Pagination | Cursor-based (`limit`, `cursor`) for histories and community feeds |
| Errors | Consistent JSON: `code`, `message`, `details`, `request_id` (problem-details style) |
| Idempotency | `client_id` on create endpoints for check-ins, journal entries, and symptom logs |
| Validation | Pydantic schemas with ranges (for example scores 1--5) and length limits |
| Time | Timestamps in UTC; user-facing dates use the stored `timezone` and a `local_date` column |
| Rate limits | Per-IP and per-user limits on auth, AI, PDF, and community writes |

## 6. Data design

### Data classification

| Class | Examples | Handling |
|---|---|---|
| **Highly sensitive** | Journal text, symptom notes, cycle dates, symptom logs, mood/stress/energy scores | Owner-only access, never logged, excluded from analytics, deleted on request, not sent to AI without consent |
| **Sensitive** | Email, preferences/consents, academic events, planner items | Owner-only access, minimal logging |
| **Community** | Posts, comments, reports | Visible per group rules; moderator-accessible when reported |
| **Public/curated** | Activities, education content, resource listings | Readable by all authenticated users |

### Storage design

-   **PostgreSQL** is the single system of record. The relational model
    fits ownership, foreign keys, and transactional deletion.
-   UUID primary keys; `created_at`/`updated_at` on all mutable tables.
-   Indexes (from README): `user_id`, `created_at`, `period_start`,
    `group_id`, `plan_date`, moderation `status`. Add a composite
    `(user_id, local_date)` on check-ins and `(user_id, period_start)` on
    cycle logs.
-   Cascade rules: private tables use `ON DELETE CASCADE` from `users`;
    community content is anonymized on account deletion (see below).
-   Dates vs timestamps: period dates and `event_date` are `DATE` values
    in the user's local calendar; event times are UTC timestamps.
-   Curated content tables carry a `language` column so activities and
    education can be served per language with an English fallback.

### Encryption

| Layer | Approach |
|---|---|
| In transit | TLS for mobile to API; TLS for API to database and LLM |
| At rest (baseline) | Encrypted database storage and encrypted backups |
| At rest (stretch) | Application-level encryption of `journal_entries.body` and `symptom_logs.notes` with a key from a secret manager. This protects against database dumps and backup leaks, but the server can still decrypt, so it is **not** end-to-end encryption and must not be described as such |
| End-to-end (future) | Client-held keys; requires a recovery story and disables server-side features on that data |

### Deletion and retention

``` text
DELETE /me  (re-authentication required)
  1. Revoke all refresh tokens.
  2. In one transaction:
     - delete private rows (check-ins, journal, cycles, symptoms,
       academic events, planner, routines, activity logs, preferences,
       AI interaction metadata, memberships, blocks);
     - blank and mark community posts/comments as removed; null the author;
     - delete the user row.
  3. Remove any pending export files.
  4. Backups age out under the documented retention window
     (for example 7--14 days); state this window in the Privacy Center.
```

### Export

`GET /me/export` returns a JSON bundle of the user's own records. For
small data this runs synchronously; if exports grow, use
`data_export_jobs` with a short-lived signed download that expires and is
deleted after use.

## 7. Authentication and authorization

### Authentication

| Item | Design |
|---|---|
| Passwords | Argon2id (or bcrypt with a strong cost factor); never stored in plaintext; breached/weak password checks at registration |
| Access token | Short-lived signed JWT (15 min) containing user ID and role only |
| Refresh token | Random opaque value stored **hashed** in `refresh_tokens`; rotated on every use; reuse of an old token revokes the whole token family |
| Logout | Revokes the current token family |
| Sensitive actions | Account deletion, export, and doctor-summary generation require recent re-authentication (password or biometric-gated confirm plus short-lived step-up token) |
| Brute force | Per-account and per-IP throttling with generic error messages |
| Account recovery | Email reset link with short expiry; no security questions |

### Authorization (three layers)

1.  **Role check:** FastAPI dependencies such as `require_role("moderator")`
    guard routes. Roles come from the database, not only from the token,
    for privileged actions.
2.  **Ownership scoping:** repositories always filter by the
    authenticated `user_id`. The client never supplies the owner ID.
3.  **Database safety net (stretch):** PostgreSQL Row-Level Security on
    private tables, with `app.current_user_id` set per transaction. A
    bug in application code then still cannot return another user's rows.
    This is also a strong live-demo point.

### Role matrix

| Capability | Student | Moderator | Resource admin |
|---|---|---|---|
| Own mood, journal, cycle, planner data | Yes | Own only | Own only |
| Read others' private data | No | **No** | **No** |
| View reported posts/comments | Group member | Yes | No |
| Hide/remove content, warn/suspend | No | Yes | No |
| Create/update resource listings | No | No | Yes |
| Read resource-outdated reports | No | No | Yes |
| Export/delete own data | Yes | Yes | Yes |

A person can hold a student account and a staff role; staff actions must
never grant access to private records of any user, including their own
through staff routes.

## 8. Core algorithms

All algorithms are deterministic, documented, and unit-tested so they can
be explained to users and judges.

### 8.1 Cycle estimate

**Inputs:** recorded `period_start` dates (incomplete records allowed).

1.  Compute cycle lengths as the day difference between consecutive
    recorded starts.
2.  Drop gaps above 90 days from the calculation (treated as likely
    missed logs, not as a judgment about the user).
3.  Require at least **3 usable cycle lengths**; otherwise show no
    estimate and an explanation ("log a few more cycles to see an
    estimate").
4.  Use the **median of the last up to 6 lengths** as the typical length.
5.  Build a range around the next start: typical length plus or minus the
    larger of 2 days or the median absolute deviation.
6.  If the spread of lengths exceeds a configured threshold, show:
    "Your logged cycles vary too much for a useful estimate."
7.  Present the result as a **date range**, styled differently from
    recorded dates, with the standard uncertainty note.

No ovulation, fertility window, pregnancy, or abnormality labels. The
method is described in `docs/privacy-and-safety.md`.

### 8.2 Personal observations (insights)

-   Weekly summary: average and range of each score for the week versus
    the user's previous four weeks, shown only with enough entries (for
    example at least 4 of 7 days).
-   Exam context: compare average stress/energy in the 7 days before an
    entered event against the user's overall average, only when at least
    two events or enough check-ins exist.
-   Output is text built from templates and reason codes, for example
    `STRESS_HIGHER_NEAR_EVENT`, always phrased as an observation, never as
    a cause.

### 8.3 Study planner

``` mermaid
flowchart TD
    A["Request plan for week"] --> B{"Enough energy history? 14 or more check-ins in 28 days"}
    B -- "No" --> C["Default plan: normal load plus exam-aware spacing"]
    B -- "Yes" --> D["Compute weekday energy baseline"]
    D --> E{"Cycle consent given?"}
    E -- "No" --> G["Classify days: light, normal, focus"]
    E -- "Yes" --> F["Add recorded-period-day adjustment if 3 or more cycles show a clear difference"]
    F --> G
    C --> H["Apply exam rules"]
    G --> H
    H --> I["Guarantee at least one non-light day in any 3-day stretch before an exam"]
    I --> J["Attach a study-break activity from the curated library"]
    J --> K["Return items with reason codes"]
```

**Details**

-   **Inputs:** last 28 days of energy (and optionally sleep) check-ins;
    academic events in the next 14 days; optionally recorded period days
    if `planner_cycle_consent_at` is set.
-   **Weekday baseline:** average energy per weekday with a minimum of 2
    samples; compare each weekday to the user's mean.
    -   Below mean by more than about 0.5 standard deviations → `light`.
    -   Above by more than about 0.5 → `focus`.
    -   Otherwise → `normal`.
-   **Cycle adjustment (consent only):** if, across at least 3 recorded
    cycles, average energy on days 1--4 after a recorded period start
    differs clearly from other days, mark days that fall inside a
    **currently recorded** period as leaning `light`. v1 does not adjust
    for *predicted* days; adding that would need a clearly labeled
    "possible" tag and is a P2 item.
-   **Exam rules:** days within 7 days before an event are never all
    `light`; the highest-energy day is upgraded to `normal` at minimum;
    a normal/focus option is always available.
-   **Breaks:** each day gets a short activity (study-break category)
    chosen by rotation and favorites.
-   **Output:** `study_plan_items` with `suggested_load`,
    `reason_codes`, and optional `activity_id`. Reason codes map to
    localized sentences such as "You often log more energy on Tuesdays."
-   **No AI involvement.** The planner runs entirely in the backend with
    no external calls, which makes it testable, private, and fast.
-   **Consent revocation** removes cycle inputs from the next generated
    plan immediately.

### 8.4 Recommendation fallback (no AI)

When AI is off or fails, recommend activities by rules: matching
`category` and `duration` to the selected need ("I need a quick break"),
excluding recently completed items, boosting favorites and
high-helpfulness items. This is the same candidate generator the AI path
uses (see section 9).

## 9. AI gateway

Single backend module through which all AI calls pass.

### Pipeline

``` mermaid
sequenceDiagram
    autonumber
    participant App as Flutter app
    participant API as FastAPI
    participant DB as PostgreSQL
    participant GW as AI gateway
    participant LLM as LLM provider

    App->>API: POST /ai/journal-reflection (entry_id, language)
    API->>DB: Verify entry belongs to user
    API->>DB: Check journal_ai_consent_at is set
    alt No consent
        API-->>App: 403 consent_required
    else Consent present
        API->>GW: Entry text (minimal) and language
        GW->>GW: Length cap, strip emails and phone numbers
        GW->>LLM: Prompt with fixed safety rules
        LLM-->>GW: Structured JSON reflection
        GW->>GW: Validate schema, block diagnosis phrases, check for crisis terms
        alt Output unsafe or invalid or timeout
            GW-->>API: Fallback reflection prompts
        else Output valid
            GW-->>API: Reflection labeled AI-generated
        end
        API->>DB: Store metadata only (type, status, latency)
        API-->>App: Reflection and label
    end
```

### Design rules

| Concern | Design |
|---|---|
| Consent | Separate flags: `ai_recommendations_enabled` and `journal_ai_consent_at`; checked server-side on every call |
| Data minimization | Send only the selected entry text (journal) or activity preferences and candidate list (recommendations); never email, name, cycle data, or other entries |
| Recommendations | **Retrieve-then-rank:** backend selects candidate activities from the curated library; the model returns activity IDs and short reasons as JSON; IDs are validated against the candidate list, so the model cannot invent activities |
| Prompting | System prompt forbids diagnosis, treatment advice, and fertility/pregnancy statements; requires supportive, non-directive tone; fixed JSON output schema |
| Output validation | JSON schema check; phrase blocklist for diagnostic language; if distress terms appear, replace with the fixed reviewed support message |
| Failure handling | Timeout (about 10 s), one retry for transient errors, circuit breaker (open for about 2 minutes after repeated failures), fallback to rule-based results |
| Cost and abuse | Per-user daily call limit, max input length, request logging of counts only |
| Logging | Metadata only: interaction type, status, latency, token counts. No prompts, no journal text, no raw responses by default |
| Labeling | Every AI-generated item carries an "AI-generated" label and a link to the AI processing explanation |
| Provider | `AI_PROVIDER` abstraction so the provider can be swapped or disabled with an environment setting |

## 10. Safety layer and community moderation

### Safety layer

| Surface | Mechanism | Data handling |
|---|---|---|
| Journal and check-in notes | On-device phrase check before save; support card offered | Text never sent because of the check; nothing logged |
| Community posts | Backend phrase check on submit; matching posts are **held** for review and the author sees a supportive message with verified resources | Moderator sees the post only; `safety_events` records a count, never the text |
| AI output | Gateway check (section 9); unsafe output replaced with a fixed message | Metadata only |

Support content comes from verified HelpHub entries; never hard-code
unverified numbers. The phrase list and wording are reviewed and stored
in `docs/privacy-and-safety.md`. The Privacy Center states the layer's
limits: it can miss things and does not contact anyone.

### Post lifecycle

``` mermaid
stateDiagram-v2
    [*] --> Published: submit, no flags
    [*] --> Held: submit, safety or spam flag
    Held --> Published: moderator approves
    Held --> Removed: moderator removes
    Published --> Hidden: reported and hidden pending review
    Hidden --> Published: report dismissed
    Hidden --> Removed: report upheld
    Published --> Removed: author deletes or moderator removes
```

### Community query rules (enforced server-side)

-   Feed queries exclude authors who have blocked the viewer **and**
    authors the viewer has blocked.
-   Membership is checked on every group read and write.
-   Only `Published` content is visible to other users.
-   Display names are pseudonymous; email and account ID are never
    returned in community payloads.
-   Rate limits: posts and comments per hour per user; reports per day.

### Moderation workflow

1.  Report creates a `content_reports` queue item with a snapshot
    reference to the target.
2.  Moderator view returns only the reported content, group, reason, and
    timestamps.
3.  Actions: dismiss, warn, hide, remove, suspend.
4.  Every action writes a `moderation_actions` row (moderator ID, target,
    action, time).
5.  Reporter and author receive status updates where appropriate.

## 11. Key flows

### 11.1 Check-in

1.  App generates `client_id` and `local_date`, runs the on-device safety
    check on the optional note.
2.  `POST /v1/checkins` with scores, tags, note, and `client_id`.
3.  Backend validates ranges, scopes to the authenticated user, and
    inserts (idempotent on `client_id`).
4.  Response includes the saved record; app requests weekly insight and
    shows an observation if enough data exists.

### 11.2 Study plan generation

1.  `POST /v1/study-plans/generate` for the target week.
2.  PlannerService loads the user's check-ins, events, and (if consented)
    recorded cycle days, all owner-scoped.
3.  Algorithm (section 8.3) produces items and reason codes.
4.  Items are stored with status `suggested`; the app renders them with
    localized explanations.
5.  User accepts, edits, or skips each item via
    `PATCH /v1/study-plans/items/{id}`.

### 11.3 Doctor-visit summary

1.  User picks a date range and categories; app requires recent
    re-authentication.
2.  `POST /v1/me/doctor-summary` runs owner-scoped queries for only the
    chosen categories.
3.  PDF is rendered in memory (or a temp file) using a font that supports
    the chosen language (embed a Devanagari-capable font for Hindi and
    Marathi).
4.  PDF streams to the requesting client; temp files are deleted
    immediately; nothing is stored.
5.  Content: recorded dates and symptoms for the range, optional labeled
    estimate, "questions to ask" section, and the standard disclaimer.

### 11.4 Reporting and moderation

See the post lifecycle in section 10. The key property: the moderator
endpoints touch only community and report tables.

### 11.5 Resource freshness

1.  Admin creates or updates a listing with `source_url`,
    `verification_status`, and `last_verified_at`.
2.  Listings older than a threshold (for example 6 months) display a
    "may be outdated" label in the app and appear in an admin review list.
3.  Student reports ("dispenser empty", "number incorrect") create
    `resource_reports`; admin resolves and updates the verification date.

## 12. Security and threat model

| Threat | Example | Mitigation |
|---|---|---|
| Broken access control | User A reads User B's journal via ID guessing | Owner-scoped repositories; UUIDs; automated two-account tests; optional RLS |
| Privilege misuse | Moderator browses private records | Import-boundary rule; no moderator route touches private tables; tests that call every moderator route and assert no private data in responses |
| Token theft | Stolen refresh token | Rotation and reuse detection; secure storage; short access-token life; logout and deletion revoke families |
| Credential attacks | Password stuffing | Rate limiting, lockout/backoff, strong hashing, generic errors |
| Injection | SQL injection through search | ORM with parameterized queries; input validation |
| Sensitive data in logs | Journal text appears in error trace | Central log redaction filter; never log request bodies on private routes; tests that scan logs for fixture text |
| Provider data exposure | Journal sent to LLM without consent | Consent check inside the gateway; separate consents; minimization; accurate disclosure; provider terms reviewed before enabling |
| Prompt injection via journal | Entry text tries to override rules | Fixed system prompt; schema-validated output; retrieved-candidate-only recommendations; no tools or data access for the model |
| Abuse of community | Harassment, spam, unsafe medical claims | Reporting, holds, rate limits, moderator actions, guidelines |
| Device sharing | Roommate opens the app | App lock, neutral notifications, privacy overlay, quick-hide |
| Backup leak | Database snapshot exposed | Encrypted backups, least-privilege access, optional field-level encryption |
| Supply chain | Malicious dependency | Pinned versions, dependency scanning in CI, minimal dependencies |
| Misconfiguration | Public database | Private subnet, security groups allowing only the app, secrets in a manager, HTTPS enforced |

**Secrets:** never in the repository or client build; stored in a secret
manager or protected environment configuration; separate values per
environment. Pre-commit secret scanning hook is installed with:
`ln -sf ../../scripts/check-secrets.sh .git/hooks/pre-commit && chmod +x scripts/check-secrets.sh .git/hooks/pre-commit`

## 13. Deployment architecture

``` mermaid
flowchart TB
    subgraph Internet
        U["Students' phones"]
        GH["GitHub Actions"]
    end

    subgraph AWS["AWS account"]
        DNS["DNS"]
        subgraph Public["Public subnet"]
            PROXY["Reverse proxy or load balancer with TLS"]
            EC2["EC2: Docker host running FastAPI container"]
        end
        subgraph Private["Private subnet"]
            RDS[("PostgreSQL: managed instance")]
        end
        SM["Secrets manager or parameter store"]
        CW["Logs and metrics"]
        ECR["Container registry"]
        BK["Encrypted backups"]
    end

    LLM["LLM provider"]

    U --> DNS --> PROXY --> EC2
    EC2 --> RDS
    EC2 --> SM
    EC2 --> CW
    EC2 -->|outbound HTTPS only| LLM
    RDS --> BK
    GH -->|build, test, push| ECR
    GH -->|deploy| EC2
    ECR --> EC2
```

### Environments

| Environment | Purpose | Notes |
|---|---|---|
| Local | Development | Docker Compose with PostgreSQL; `AI_PROVIDER=disabled` by default |
| Staging (optional) | Pre-demo verification | Small instance; synthetic data only |
| Production/demo | Hackathon and pilot | HTTPS, managed backups, real secrets |

### Hosting choices

-   **Application:** one small EC2 instance running the Docker image
    (several uvicorn workers behind the proxy). A second instance behind
    a load balancer is optional later.
-   **Database:** a managed PostgreSQL instance in a private subnet is
    recommended because it provides automated backups and point-in-time
    recovery. **Budget alternative:** PostgreSQL in a container on the
    same host with scheduled encrypted dumps to object storage; this is
    cheaper but adds operational risk, so test restores before relying on
    it.
-   **Network:** database accepts connections only from the application
    security group; the application accepts only HTTPS from the internet.
-   **Migrations:** run as an explicit release step (`alembic upgrade
    head`) before starting the new container; migrations must be
    backward-compatible for one release to allow rollback.

### CI/CD pipeline

1.  Pull request: lint, unit tests, API tests (including the two-account
    isolation suite), import-boundary check, dependency scan.
2.  Merge to main: build image, run tests again, push to the registry.
3.  Deploy: pull the image on EC2, run migrations, start the new
    container, check `/health`, keep the previous image for rollback.
4.  Mobile: build Android release candidate artifacts from tagged
    commits.

## 14. Reliability and observability

### Health and failure handling

| Failure | Behavior |
|---|---|
| LLM down or slow | Circuit breaker opens; rule-based fallback; app labels results as "suggested from our library" |
| Database unavailable | `/health` fails; proxy returns a friendly error; mobile shows retry state; no data loss for already-committed writes |
| Network loss on device | Reads show last in-memory state or an offline notice; writes fail with retry; idempotent `client_id` prevents duplicates |
| Bad deploy | Roll back to the previous image; migrations designed to be backward-compatible |
| Content outdated | Verification labels and admin review list (section 11.5) |
| Moderation backlog | Queue age metric and alert; held posts remain hidden until reviewed |

### Observability

-   **Logs:** structured JSON with request ID, route, status, and
    latency. A redaction filter removes sensitive fields; private-route
    bodies are never logged.
-   **Metrics:** request rate, error rate, p50/p95 latency per route,
    login failures, AI success/fallback/timeout rates, PDF generation
    time, moderation queue length and oldest item age.
-   **Alerts (minimum):** error rate above threshold, p95 latency above
    threshold, health check failing, database storage nearing limit,
    moderation queue older than a set age, AI failure rate spike.
-   **Product analytics:** event counts only (for example "check-in
    completed"), no health values, no text, and no user-identifying data
    in third-party tools.

### Backup and recovery

-   Automated daily backups plus point-in-time recovery if available.
-   Documented and **tested** restore procedure; run a restore drill
    before the demo.
-   Backup retention window documented in the Privacy Center.

## 15. Scaling path

The pilot needs no scaling work. This table records what to do **when**
specific signals appear.

| Signal | Action |
|---|---|
| CPU or latency rises on the app instance | Increase instance size, then add a second instance behind a load balancer (the API is stateless) |
| Database CPU or connections high | Add connection pooling; tune indexes; scale the instance up |
| Read-heavy insight queries slow | Add a read replica for insights and content; cache curated content |
| AI latency or cost grows | Queue AI requests, tighten daily limits, cache non-personal results such as activity explanations |
| PDF or export jobs spike | Move to a background worker with a job table |
| Community grows | Add moderation tooling, automated spam checks, and stricter rate limits before adding features |
| Multiple campuses | Add `tenant_id` or campus scoping for resources and groups; keep private data tenant-isolated |
| Need for end-to-end encryption | Move to client-held keys with an explicit recovery design; accept loss of server-side processing on that data |

## 16. Design decisions and trade-offs

| Decision | Chosen | Alternatives | Reason and trade-off |
|---|---|---|---|
| Architecture style | Modular monolith | Microservices | Fits team size and timeline; simple transactions for deletion/export. Trade-off: shared deploy unit, mitigated by module boundaries |
| API style | REST + OpenAPI | GraphQL | Simple, well-supported by FastAPI and Dio; automatic docs help demos |
| Database | PostgreSQL | NoSQL | Strong relations and constraints; good fit for per-user ownership and reports |
| Auth tokens | Short JWT + rotating opaque refresh | Long-lived JWT; server sessions | Limits theft impact and supports revocation; slightly more code |
| Reminders | Local notifications | Push notifications | No device tokens or reminder data on the server; trade-off: no cross-device reminders |
| Study planner | Deterministic rules with reason codes | LLM-generated plans | Explainable, private, testable, no provider dependency; trade-off: less flexible phrasing |
| Recommendations | Retrieve-then-rank with LLM | Free-form LLM generation | Prevents invented activities; keeps content curated |
| Safety check on journal | On-device phrases | Server-side or LLM classifier | Text never leaves the device; trade-off: simpler and less accurate, so it is framed as a gentle prompt |
| PDF generation | Server-side, not stored | Client-side generation | Consistent rendering and fonts across devices; trade-off: data transits the server (already holds it), so delete temp files immediately |
| Journal encryption | At-rest field encryption as stretch | End-to-end now | E2EE needs key recovery design and breaks server features; at-rest encryption is achievable and honest if described accurately |
| Local caching | No sensitive on-disk cache in v1 | Local database cache | Avoids unencrypted health data on shared phones; trade-off: weaker offline support |
| Moderator isolation | Code boundary + tests (+ optional RLS) | Policy only | Makes the privacy promise verifiable |
| Languages | `intl` + reason codes | Server-translated strings | Offline-friendly localized text; keeps API responses language-neutral |

## 17. Schema additions to the README

The README schema should be extended with:

| Change | Purpose |
|---|---|
| `refresh_tokens` (`id`, `user_id`, `token_hash`, `family_id`, `expires_at`, `revoked_at`, `replaced_by`) | Rotation, reuse detection, revocation |
| `moderation_actions` (`id`, `moderator_id`, `target_type`, `target_id`, `action`, `reason`, `created_at`) | Audit trail for moderation |
| `mood_checkins.local_date` and `client_id` (unique per `user_id`) | Correct day grouping across time zones; idempotent creates |
| `symptom_logs.client_id`, `journal_entries.client_id` | Idempotent creates |
| `study_plan_items.reason_codes` (text array) | Localized, explainable suggestions |
| `community_posts.status` values: `published`, `held`, `hidden`, `removed` | Matches the post lifecycle |
| `community_posts.author_id` nullable | Anonymize on account deletion |
| `resources.last_verified_at` index and `resource_reports` table | Freshness workflow |
| `user_preferences.planner_cycle_consent_at`, `language`, `discreet_notifications` | Already in the updated README; listed here for completeness |
| Optional RLS policies on private tables | Database-level isolation |

## 18. Risks and open questions

| Risk or question | Why it matters | Suggested handling |
|---|---|---|
| Content quality and review | Menstrual-health and wellness content must be accurate | Name a reviewer, track sources and review dates in `content-review-log.md`, publish only reviewed items |
| Safety phrase list quality | Too sparse misses distress; too broad annoys users | Keep it small and reviewed; frame as optional support; test with non-sensitive scenarios |
| Moderation capacity | Community adds ongoing human work | Launch with a small number of pre-seeded groups; slow-mode and rate limits; cut community depth first if time is short |
| AI provider data terms | Claims in the Privacy Center must be accurate | Review terms before enabling; keep `AI_PROVIDER=disabled` as a safe default |
| Regulatory and legal | Health-adjacent data, student data, and local privacy law | Obtain advice before any real-user pilot; keep v1 on synthetic data |
| Planner usefulness | Little history exists at first | Default plan path; show how many check-ins are needed for personalized suggestions |
| Shared-device edge cases | App lock does not protect a device unlocked by someone else | Quick-hide, auto-lock, clear explanations in onboarding |
| Open question: hosting database | Managed instance costs more than self-hosting | Decide based on budget; whichever is chosen, run a restore drill |
| Open question: campus partnership | Verified resources and access points need real contacts | Identify a campus counselor or welfare office early to validate listings |
| Open question: account model | Email-only vs campus SSO | Email-only for v1 to avoid sharing identity with the college; revisit with a privacy review |
