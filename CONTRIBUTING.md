# Contributing to HireHub

Thanks for contributing! This document explains how to prepare changes, run tests locally, and submit a clean pull request so your work can be merged quickly.

## 🧭 Workflow
- Create a **feature branch** from `main` named like `feature/<short-description>` or `fix/<issue-number>-<short-desc>`.
- Keep commits small and focused. Write clear commit messages (imperative mood, short summary, optional body).
- Open a **Pull Request (PR)** targeting `main` with a description of the change and mention any related issue numbers.

## 🔁 Running tests locally
### Backend (Django)
1. Create and activate a virtual environment:
   ```bash
   python -m venv .venv
   .venv\Scripts\activate  # Windows
   pip install -r hirehub_project/requirements.txt
   ```
2. Copy `.env.example` → `.env` and set any required values (e.g., `SECRET_KEY`).
3. Apply migrations and run tests:
   ```bash
   cd hirehub_project
   python manage.py migrate
   python manage.py test
   ```

### Frontend (Flutter)
1. Ensure Flutter SDK is installed and `flutter` is on your PATH.
2. From repo root:
   ```bash
   cd hirehub_ui
   flutter pub get
   flutter test
   ```

## ✅ What to include in a PR
- Tests for any new behavior or bug fix (backend or frontend).
- A short description in the PR body explaining why the change was made and how it was tested.
- If database schema changed, include migrations (use `python manage.py makemigrations`).

## 🔐 Secrets & CI
- Do **not** commit secrets; use `.env` locally and add secrets to GitHub Actions as repository secrets.
- CI reads necessary env vars from GitHub Secrets (see `.github/workflows/ci.yml`). If you need additional secrets for a feature, request them or provide instructions to the maintainer.

## 🧹 Style & linting
- Keep code readable and follow existing patterns in the repo.
- For Python, keep PEP8 formatting. For Flutter, run `flutter analyze` as part of your checks.

## Troubleshooting
- If tests pass locally but fail in CI, check for environment-specific assumptions (e.g., missing secrets, database settings).
- If you accidentally commit secrets, rotate them immediately and ask a maintainer to help scrub the git history.

Thanks again — contributions are welcome! 🎉
