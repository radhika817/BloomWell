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

## Git, Commits & Verification Workflow
14. **10+ Commits per Stage & Commit Plan:** Every stage (each prompt I give you) must end up as at least 10 separate commits. Before writing any code, include a numbered commit plan (at least 10 entries, each with a one-line message) in the plan you show me, and wait for my approval.
15. **Granular Logical Units:** Each commit is one small logical unit: for example a migration, a model, a repository, one group of endpoints, a UI component, a screen, a set of tests, a docs update. Code and its tests go in the same commit. Docs updates for a feature go in their own commit.
16. **Verification Before Committing:** Every commit must leave the project working: the checks for the folders you changed must pass before the commit (backend: pytest; mobile: dart format ., flutter analyze, flutter test). Never commit failing checks, never commit half-finished code that breaks the build.
17. **No Padding Commits:** Never create padding commits: no empty commits, no whitespace-only or comment-only changes made just to increase the count, no splitting one line of change across several commits. If a stage cannot honestly be split into 10 meaningful commits, tell me before starting and propose the natural number with a short reason.
18. **Pre-Commit Secrets & Explicit Staging:** Before each commit run git status and git diff --stat, review them, and stage files by explicit path. Never commit anything on the forbidden list (.env and .env.* except .env.example, *.jks, *.keystore, key.properties, google-services.json, service accounts, .venv, build/, .dart_tool/, database dumps, anything containing a password, token or API key). If something forbidden appears, stop, fix .gitignore, and tell me.
19. **Standard Commit Messages:** Commit messages: type prefix plus a short imperative subject, max 72 characters, e.g. "feat(backend): add cycle_logs model and migration", "test(backend): add two-account isolation tests for cycles", "docs: document cycle endpoints". No emojis.
20. **Safe Push Protocol:** Push after every commit with a plain `git push`. Never force-push, never rewrite history, never reset --hard, never delete branches. If a push fails, stop and report the exact error. Never ask me to paste tokens into chat.
21. **Post-Stage Reporting:** At the end of each stage, report the list of commits (hash and message) and the final check results.
