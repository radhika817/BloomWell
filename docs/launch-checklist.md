# BloomWell Production Launch Checklist

Before opening BloomWell to any pilot students or users, review and check off every item on this list.

---

## 1. Content & Feature Flags

- [ ] **Demo Resources Flag Disabled:** `ALLOW_DEMO_RESOURCES=false` in `.env.production`.
- [ ] **Draft Educational Content Flag Disabled:** `ALLOW_DRAFT_CONTENT=false` in `.env.production`.
- [ ] **Real Campus & Community Resources Verified:** All resource listings in the database have valid `source_url`, `verification_status="verified"`, and active contact details.
- [ ] **Reviewers Named in Review Log:** Every published educational resource and helpline is recorded in `docs/content-review-log.md` with reviewer identity and review date.
- [ ] **No Medical Diagnosis or Prescription Language:** Content verified non-diagnostic, strictly supportive and educational.

---

## 2. API & Network Security

- [ ] **API Documentation Disabled:** Verify `ENABLE_DOCS=false` in `.env.production`. Confirm that `GET /docs`, `GET /redoc`, and `GET /openapi.json` return `404 Not Found`.
- [ ] **Valid HTTPS / TLS:** Verify Caddy serves a valid TLS certificate with A+ rating on SSL Labs.
- [ ] **HTTP to HTTPS Redirect:** Confirm requesting `http://api.yourdomain.com` redirects with 308/301 to `https://`.
- [ ] **Security Headers Present:** Inspect response headers on any endpoint:
  - `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: no-referrer`
  - `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`
- [ ] **CORS Origins Restricted:** `CORS_ORIGINS` does not contain `*`. Configured explicitly to trusted mobile/web domains.
- [ ] **Client IP Forwarding:** Trusted proxy headers configured in `TRUSTED_PROXY_IPS` so the in-memory rate limiter tracks real client IPs rather than proxy IPs.

---

## 3. Data Integrity & Backups

- [ ] **Managed PostgreSQL in Private Subnet:** Database has no public IP address and accepts inbound traffic only from the application security group.
- [ ] **Automated Backup Active:** AWS RDS automated backups enabled (minimum 14-day retention).
- [ ] **Local Dumps Automated with Rotation:** `scripts/backup.sh` scheduled via cron, setting file permissions to `0600` and pruning dumps older than `BACKUP_RETENTION_DAYS`.
- [ ] **Restore Drill Conducted:** Executed a successful restore into a test database using `scripts/restore.sh` prior to launch.
- [ ] **Off-Site Backup Sync:** Dumps replicated to an encrypted, access-restricted AWS S3 bucket.

---

## 4. Git & Secrets Audit

- [ ] **No Secrets in Git History:** Run the following command locally and confirm zero matches:
  ```bash
  git log -p | grep -E "(BEGIN (RSA|OPENSSH) PRIVATE KEY|password\s*=|secret_key\s*=|ghp_[A-Za-z0-9]{36})" || true
  ```
- [ ] **Pre-Commit Hook Active:** Run `./scripts/check-secrets.sh` to confirm secret scanning succeeds.
- [ ] **No `.env` or Credentials in Docker Image:** Inspect built image layers:
  ```bash
  docker history bloomwell-api:latest | grep -E "(\.env|secret|password)" || true
  ```
- [ ] **Repository Variables & Secrets:**
  - `API_BASE_URL` repository variable configured with `https://...` (not plain HTTP).
  - Keystore passwords and signing keys stored exclusively in GitHub Secrets or encrypted local vault.

---

## 5. Secret Rotation & Incident Procedures

### What to Do If a Secret Leaks
1. **Database Password Leaked:**
   - Immediately change master/application password in AWS RDS.
   - Update `DATABASE_URL` in `.env.production`.
   - Run `docker compose -f docker-compose.prod.yml restart api`.
2. **`APP_SECRET_KEY` Leaked:**
   - Generate a new 32+ byte secret: `openssl rand -hex 32`.
   - Update `APP_SECRET_KEY` in `.env.production`.
   - Restart the API container.
   - *Consequence:* All existing access tokens are immediately invalidated; users must re-authenticate.
3. **Backup Passphrase Leaked:**
   - Generate a new passphrase and update the cron script.
   - Re-encrypt existing archives with the new passphrase.
4. **Audit Logs:**
   - Check the `account_events` table for any unauthorized `export_requested`, `password_changed`, or administrative role changes.

---

## 6. Honest Technical Limitations & Roadmap Notes

Keep these operational facts clear when reporting platform readiness:
1. **Per-Process Rate Limiter:**
   - BloomWell's built-in sliding-window rate limiter is in-memory and per-process.
   - Running multiple uvicorn workers or multiple containers multiplies effective rate limits. For multi-node scaling, back the limiter with Redis.
2. **Stateless Access Token Revocation:**
   - When a user changes passwords or calls "revoke all sessions", refresh token families are revoked immediately in the database.
   - Issued JWT access tokens remain cryptographically valid until their 15-minute expiration window closes.
3. **Regulatory & Privacy Guardrails:**
   - No real student or patient health records may be gathered or stored prior to obtaining formal university legal counsel and privacy compliance approval (FERPA, HIPAA, DPDP).
   - Use fictional, synthetic data for all hackathon demonstrations and developer verification.
