# BloomWell Agent Rules

These rules govern all AI coding agents working on the BloomWell repository. They are strict, persistent guidelines that must be respected across all tasks and workflows.

---

## Source of Truth & Communication
1. **Documentation Authority:** `README.md` and `docs/architecture.md` are the source of truth for scope, schema, API, security rules, and roadmap. If you think something should change, ask first and wait.
2. **Step-by-Step Execution & Concise Plans:** Work in small steps: propose a plan, wait for approval, then implement. Keep plans short: a one-paragraph approach and the numbered commit list, not a long design essay. Do not reread files you already have in context.
3. **Large Task Splitting:** If a task is large, tell me up front and propose splitting it into parts I can send as separate messages.
4. **No Destructive Commands:** Do not run destructive commands (deleting files, git reset, dropping databases) without asking first.
5. **No Long Foreground Commands without Timeout:** Do not run long commands in the foreground without a timeout. If a command takes longer than 3 minutes, stop it, tell me, and suggest an alternative.
6. **No Auto-Starting Servers or E2E Services:** Do not start Docker, uvicorn, Chrome, or flutter run for end-to-end checks. The user will run those manually. List the exact manual steps for the user to run instead. Only start them if explicitly asked.

## Data Privacy & Security Guardrails
7. **Zero-Logging of Sensitive Data:** Never log or print journal text, symptom notes, cycle dates, mood scores, or tokens.
8. **Owner-Scoped Repositories:** Every private-data repository method must take an explicit `user_id` and filter by it. The client never supplies the owner ID.
9. **Architectural Isolation / Import Boundaries:** `ModerationService` and `CommunityService` must never import private-data repositories.
10. **Environment-Only Secrets:** Secrets only from environment variables; never commit `.env`.
11. **No Sensitive On-Disk Caching on Mobile:** No localStorage-like or on-disk caching of sensitive data in the mobile app in v1. All sensitive records remain in-memory only.
11b. **Schema-Introspection Safety Net:** Any database table with a foreign key to `users.id` or a `user_id` column must be explicitly handled by `deletion_registry` in `app/services/deletion_service.py` and covered by `export_registry` in `app/services/export_service.py` (or listed in `EXPORT_EXCLUDED` with written architectural justification). The introspection test enforces this automatically.

## Clinical Disclaimer, Ethics & Integrity
12. **No Fabricated Health Data:** Never claim data is saved, and never fabricate health data, dates, stats, or user info in UI, tests, or seed data. Use clearly fictional demo data only.
13. **Non-Diagnostic & Educational Tone:** Cycle estimates and planner suggestions are suggestions, never medical claims. No diagnosis, fertility, or pregnancy language anywhere.

## Code Quality, Dependencies & Localization
14. **Strict Localization:** No hard-coded UI strings in Flutter; use localization files (English first, Hindi and Marathi later).
15. **Resolved Dependencies Only:** Never invent package versions. Use `flutter pub add` and `pip install` so versions resolve, and justify any new dependency before adding it.
16. **Isolation Testing:** Every feature that touches private data needs a two-account isolation test.

## Git, Commits & Verification Workflow
17. **10+ Commits per Stage & Commit Plan:** Every stage (each prompt I give you) must end up as at least 10 separate commits. Before writing any code, include a numbered commit plan (at least 10 entries, each with a one-line message) in the plan you show me, and wait for my approval.
18. **Granular Logical Units:** Each commit is one small logical unit: for example a migration, a model, a repository, one group of endpoints, a UI component, a screen, a set of tests, a docs update. Code and its tests go in the same commit. Docs updates for a feature go in their own commit.
19. **Targeted Per-Commit Checks & Full End-of-Stage Verification:** Per-commit checks are targeted: run only the tests/checks for the files you just changed (backend: pytest on the specific test files or with `-k`; mobile: `dart format` on changed files, `flutter analyze` on changed files or the changed feature folder, and `flutter test` on the specific test files). Run the FULL suites (pytest, flutter analyze, flutter test) only before the last commit of a stage, and report the results. Never commit failing checks, never commit half-finished code that breaks the build.
20. **No Padding Commits:** Never create padding commits: no empty commits, no whitespace-only or comment-only changes made just to increase the count, no splitting one line of change across several commits. If a stage cannot honestly be split into 10 meaningful commits, tell me before starting and propose the natural number with a short reason.
21. **Pre-Commit Secrets & Explicit Staging:** Before each commit run git status and git diff --stat, review them, and stage files by explicit path. Never commit anything on the forbidden list (.env and .env.* except .env.example, *.jks, *.keystore, key.properties, google-services.json, service accounts, .venv, build/, .dart_tool/, database dumps, anything containing a password, token or API key). If something forbidden appears, stop, fix .gitignore, and tell me.
22. **Standard Commit Messages:** Commit messages: type prefix plus a short imperative subject, max 72 characters, e.g. "feat(backend): add cycle_logs model and migration", "test(backend): add two-account isolation tests for cycles", "docs: document cycle endpoints". No emojis.
23. **Safe Push Protocol:** Push after every commit with a plain `git push`. Never force-push, never rewrite history, never reset --hard, never delete branches. If a push fails, stop and report the exact error. Never ask me to paste tokens into chat.
24. **Post-Stage Reporting:** At the end of each stage, report the list of commits (hash and message) and the final check results.
