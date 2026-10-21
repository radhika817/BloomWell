# Developer Workflow & Git Hooks 🌸

This document describes local developer workflow, pre-commit secret scanning, and commit hygiene guidelines for the BloomWell repository.

---

## 1. Pre-Commit Hook Installation

BloomWell includes a pre-commit secret scanner script ([scripts/check-secrets.sh](file:///home/radhika/Desktop/BloomWell/scripts/check-secrets.sh)) that prevents accidentally staging or committing forbidden files (`.env`, `*.jks`, `*.keystore`, `key.properties`, `google-services.json`, service account credentials, build artifacts, database dumps, PDFs) or obvious secret patterns (private keys, AWS keys, variable secret assignments).

To install the pre-commit hook on any developer machine, run this one-line command from the repository root:

```bash
ln -sf ../../scripts/check-secrets.sh .git/hooks/pre-commit && chmod +x scripts/check-secrets.sh .git/hooks/pre-commit
```

Once installed, `.git/hooks/pre-commit` will automatically run before every `git commit`.

---

## 2. Commit & Verification Rules

1. **Commit and push per task:** Commit and push at the end of every completed task (or distinct fix), never mid-task and never with failing checks. One logical change per commit.
2. **Pre-commit checks:**
   - `backend/` -> `pytest`
   - `mobile/` -> `dart format .`, `flutter analyze`, `flutter test`
   - Never commit failing code.
3. **Pre-commit secret review:**
   - Run `git status` and `git diff --stat` before staging/committing.
   - Forbidden: `.env*` (except `.env.example`), `*.jks`, `*.keystore`, `key.properties`, `google-services.json`, `service-account*.json`, `.venv`, `build/`, `.dart_tool/`, `node_modules/`, database dumps (`*.sql`, `*.sqlite`, `*.dump`), and generated PDFs (`*.pdf`).
4. **Commit messages:** Short imperative subject (max 72 chars) with conventional type prefix: `feat(backend): ...`, `fix(mobile): ...`, `docs: ...`, `chore: ...`. No emojis.
5. **Push protocol:** Push with plain `git push`. Never force-push or rewrite history.
