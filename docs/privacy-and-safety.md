# BloomWell Privacy and Safety Guidelines

BloomWell is built for women students with privacy, clinical safety, and data dignity at its core. This document establishes non-negotiable architectural guardrails, verification protocols, and content safety policies.

---

## 1. Data Privacy & Zero-Logging Guardrails

### 1.1 Strict Redaction in Logs
- **Sensitive Fields:** Journal entries, symptom descriptions, cycle dates, mood scores, auth tokens, reporter notes, and search queries (`q`) must **never** be logged in plain text or structured log attributes.
- **Redaction Engine:** `app.core.logging.RedactingFormatter` scrubs recognized payload keys and pattern-matches email addresses and auth tokens, replacing them with `[REDACTED]`.
- **Validation Errors:** FastAPIs validation exception handlers automatically strip user input from error payloads to prevent echoing sensitive text on schema mismatches.

### 1.2 Anonymity in Community Resource Reports
- **Reporter De-identification:** Community reports (`resource_reports`) protect the student reporter. The admin endpoints (`GET /v1/admin/resource-reports`, `PATCH /v1/admin/resource-reports/{id}`) strictly omit `reporter_id` and do not return user details.
- **Account Deletion Safeguard:** If a student deletes their account, their reports are preserved for campus safety with `reporter_id` set to `NULL` (`ON DELETE SET NULL`), completely severing any link to the user while keeping the facility status accurate.

### 1.3 Owner-Scoped Architecture
- Private student endpoints require explicit `user_id` filtering in repository layers. The caller never supplies an owner ID via query or path params.
- Cross-account access attempts return `404 Not Found` (never `403 Forbidden`) to avoid leaking the existence of other users' records.

---

## 2. HelpHub: Resource Verification & Safety Protocol

### 2.1 The "Never Invent" Rule
- Developers, agents, and contributors must **never** invent, hallucinate, or recall from memory real-world helplines, addresses, operating hours, or URLs.
- In test environments, resources must clearly carry `(Demo)` in their name, use `example.org` URLs, and set `is_demo: true`.
- In production, unverified or demo entries are strictly forbidden unless explicit environment overrides (`ALLOW_DEMO_RESOURCES=true`) are activated.

### 2.2 How to Verify a Resource (Admin Checklist)
Before publishing or re-verifying any campus or community resource, administrators must complete this checklist:
1. **Official Source Documentation:** Ensure there is an active, authoritative official website or public institutional directory (`source_url`) documenting the service.
2. **Contact Validation:** Confirm phone numbers and email addresses match institutional directories.
3. **Hours & Access:** Verify whether operating hours are explicitly stated. For emergency 24x7 resources, confirm round-the-clock availability via official guidelines.
4. **Product Accessibility:** For period-product dispensers, specify exact item types (`pads`, `cups`), payment requirements (`cost: "free"` or `"paid"`), and physical access instructions.
5. **Execution:** Use `POST /v1/admin/resources/{id}/verify` with the verified `source_url`. The system records `last_verified_at` as the current date and stamps `verified_by` with the admin's email.

### 2.3 Six-Month (180-Day) Re-verification Protocol
- Stale Information Risk: Emergency resources and dispenser locations change frequently. Resources not re-verified within `RESOURCE_STALE_DAYS` (default: 180 days) are flagged as stale.
- **Stale Audit Workflow:** Admins query `GET /v1/admin/resources?stale=true` to retrieve records due for audit.
- **Marking Outdated:** If a campus resource is reported non-operational or cannot be validated, admins flag it using `POST /v1/admin/resources/{id}/mark-outdated`. Outdated resources are excluded from default student search results.

---

## 3. Educational Content & Clinical Integrity

### 3.1 Non-Diagnostic & Educational Stance
- BloomWell does not provide medical diagnoses, clinical treatment plans, or pharmaceutical advice.
- Educational materials are informational guides to help students understand their bodies and prepare for consultations with qualified healthcare workers.

### 3.2 Prohibited Vocabulary Guardrail
To prevent algorithmic or authorial drift into diagnostic or medical claims, all educational content is strictly screened against the following prohibited terms:
- `diagnose` / `diagnosis`
- `cure`
- `treat` / `treatment` (prescriptive treatment)
- `ovulation`
- `fertile` / `fertility`
- `pregnancy` / `pregnant`
- `abnormal`
- `irregular`
- `dosage` / `dose`

### 3.3 Mandatory Doctor Consultation Disclaimer
Every educational article must conclude with clear, neutral guidance encouraging consultation with a qualified doctor, campus clinic, or healthcare professional if personal symptoms cause concern or discomfort.

### 3.4 Content Review & Publishing Protocol
1. **Draft Ingestion:** Initial submissions enter as `review_status: "draft"` with `source_name: "BloomWell team draft"` and `is_published: false`.
2. **Clinical Review:** A verified medical educator or clinician inspects the article for clarity, non-prescriptive language, and cultural safety.
3. **Approval:** The reviewer details are recorded in `docs/content-review-log.md`.
4. **Publishing:** The admin activates the article via `PATCH /v1/admin/education/{id}` setting `review_status: "reviewed"`, `reviewed_at: "<date>"`, and `is_published: true`.

---

## 4. Privacy Center: Export, Deletion, and Session Controls

### 4.1 Step-Up Re-Authentication
- Sensitive account operations (data export and account deletion) require a recent step-up token.
- `POST /v1/me/reauth` verifies the user's password in constant time and returns a signed 5-minute JWT (`scope: "reauth"`).
- The client passes this token via the `X-Reauth-Token` header. Step-up tokens cannot be used as access tokens, and access tokens cannot be used as step-up tokens.
- Attempting to use a step-up token belonging to a different user is rejected with `401 Unauthorized`.

### 4.2 Data Export (`GET /v1/me/export`)
- **What is Exported:** A single JSON document containing all of the caller's own records across every feature: profile (id, display_name, role, created_at; strictly no password hash or tokens), preferences and consent timestamps, mood check-ins (scores, tags, notes), journal entries (full body and titles), academic events, activity completion and favorites, cycle logs (period dates), study plans and daily suggestions/decisions, submitted resource reports, and account events.
- **On-the-Fly Generation:** Exports are streamed on-the-fly directly to the response and are never saved to disk or object storage.
- **Headers:** Returned with `Content-Disposition: attachment; filename="bloomwell-data-export.json"`, `Cache-Control: no-store`, and `Content-Type: application/json`.
- **Audit Logging:** An `export_requested` event is logged to `account_events` without file content, record counts, or IP/device metadata.
- **Safety Limits:** Capped at `EXPORT_MAX_RECORDS` (default: 50,000 records). Requests exceeding this limit return `413 Request Entity Too Large` with guidance. Rate limited to 3 exports per user per day.

### 4.3 Account Deletion (`DELETE /v1/me`)
- **Atomic Deletion:** Requires `X-Reauth-Token` and explicit request body `{"confirm": "DELETE"}`.
- **Single Transaction:** In a single atomic database transaction, all rows owned by the user across `user_preferences`, `refresh_tokens`, `mood_checkins`, `journal_entries`, `academic_events`, `user_activity_logs`, `cycle_logs`, `study_plans`, and `study_plan_items` are explicitly deleted.
- **Anonymous Retention:** `resource_reports` rows survive to keep campus facility status accurate, but the `reporter_id` link is set to `NULL`, severing all connection to the user.
- **Immediate Token Invalidation:** When the `users` row is deleted, the user's old access token fails immediately on all subsequent requests with `401 Unauthorized` because authentication resolves live users from the database.
- **Backup Retention Window:** Database backups age out under the documented `BACKUP_RETENTION_DAYS` window (default: 14 days), after which deleted data is completely purged from all backup media.

### 4.4 Session Control & Security Log
- **Session Revocation (`POST /v1/me/sessions/revoke-all`):** Revokes all active refresh token families.
  - *Honest Session Limit:* The caller's current 15-minute access token remains valid until its natural expiry time (up to 15 minutes), after which refresh is refused and re-authentication is required.
- **Active Session Count (`GET /v1/me/sessions`):** Returns only `{ "active_sessions": <count> }`. Strictly no IP addresses, device user-agents, or geographical locations are stored or returned.
- **Security Audit Log (`GET /v1/me/account-events`):** Cursor-paginated log of the user's account security events (`export_requested`, `password_changed`, `sessions_revoked`, `cycle_data_deleted`, `consent_changed`). Disappears permanently when the account is deleted.
