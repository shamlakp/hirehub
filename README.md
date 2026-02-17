# HireHub — Project Setup & Run Guide

This README provides a short, practical guide to get the project running locally (backend and frontend) and how to manage secrets with `.env`.

---

## Structure
- `hirehub_project/` — Django backend (API, database, migrations, tests)
- `hirehub_ui/` — Flutter frontend (mobile/web UI, stores token securely)

---

## Backend (Django) — Quick start ✅
1. Create a virtual environment and install deps:
   ```bash
   python -m venv .venv
   .venv\Scripts\activate   # Windows
   pip install -r hirehub_project/requirements.txt
   ```
2. Configure environment variables:
   - Copy `.env.example` → `.env` in repo root and fill values (SECRET_KEY, EMAIL_HOST_PASSWORD, DATABASE_URL if using DB other than sqlite).
   - **Do NOT commit `.env`**. `.gitignore` excludes it.
3. Apply migrations and run server:
   ```bash
   cd hirehub_project
   python manage.py migrate
   python manage.py runserver
   ```
4. Run tests:
   ```bash
   python manage.py test
   ```

> Notes:
> - In development `EMAIL_BACKEND` can be console or local memory backend; in production use real SMTP credentials stored in env.
> - If you accidentally committed secrets, rotate them immediately and use `git filter-repo` or BFG to scrub history.

---

## Frontend (Flutter) — Quick start ✅
1. Install Flutter and required SDKs: https://flutter.dev/docs/get-started/install
2. From project root:
   ```bash
   cd hirehub_ui
   flutter pub get
   flutter run
   ```
3. Auth tokens are stored using `flutter_secure_storage` (encrypted on-device). API base URL is set in `lib/services/api_service.dart` — update it when testing on a device.

---

## Environment & Secrets Management 🔐
- Use `.env` file locally (template: `.env.example`).
- For CI/CD (GitHub Actions) put secrets in **Repository Settings → Secrets** and reference them in workflows.
- For production, use a secrets manager (AWS Secrets Manager, Azure Key Vault, etc.) for best practice.

---

## Useful Commands
- Git: `git status`, `git diff`, `git log --name-only -n 20` to inspect recent changes.
- Django: `python manage.py makemigrations`, `python manage.py migrate`, `python manage.py createsuperuser`.
- Flutter: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`.

---

If you want, I can add a short `CONTRIBUTING.md` with branches/PR workflow and a GitHub Actions CI workflow that runs Django tests and Flutter tests automatically. Reply `yes` to add CI next. ✅
