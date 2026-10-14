# BloomWell Agent Rules

These rules govern all AI coding agents working on the BloomWell repository. They are strict, persistent guidelines that must be respected across all tasks and workflows.

---

## Source of Truth & Communication
1. **Documentation Authority:** `README.md` and `docs/architecture.md` are the source of truth for scope, schema, API, security rules, and roadmap. If you think something should change, ask first and wait.
2. **Step-by-Step Execution:** Work in small steps: propose a plan, wait for approval, then implement.
3. **No Destructive Commands:** Do not run destructive commands (deleting files, git reset, dropping databases) without asking first.

## Data Privacy & Security Guardrails
4. **Zero-Logging of Sensitive Data:** Never log or print journal text, symptom notes, cycle dates, mood scores, or tokens.
5. **Owner-Scoped Repositories:** Every private-data repository method must take an explicit `user_id` and filter by it. The client never supplies the owner ID.
6. **Architectural Isolation / Import Boundaries:** `ModerationService` and `CommunityService` must never import private-data repositories.
7. **Environment-Only Secrets:** Secrets only from environment variables; never commit `.env`.
8. **No Sensitive On-Disk Caching on Mobile:** No localStorage-like or on-disk caching of sensitive data in the mobile app in v1. All sensitive records remain in-memory only.

## Clinical Disclaimer, Ethics & Integrity
9. **No Fabricated Health Data:** Never claim data is saved, and never fabricate health data, dates, stats, or user info in UI, tests, or seed data. Use clearly fictional demo data only.
10. **Non-Diagnostic & Educational Tone:** Cycle estimates and planner suggestions are suggestions, never medical claims. No diagnosis, fertility, or pregnancy language anywhere.

## Code Quality, Dependencies & Localization
11. **Strict Localization:** No hard-coded UI strings in Flutter; use localization files (English first, Hindi and Marathi later).
12. **Resolved Dependencies Only:** Never invent package versions. Use `flutter pub add` and `pip install` so versions resolve, and justify any new dependency before adding it.
13. **Isolation Testing:** Every feature that touches private data needs a two-account isolation test.
