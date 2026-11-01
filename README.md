# FinSight

Android personal-finance app built with Flutter. It reads bank SMS to record
transactions automatically, sorts them into categories (built-in or your own),
and tracks your bank accounts and wallets. Supabase handles sign-in and
account data. SMS transactions are stored on the phone.

## Repository layout

```
Finsight/
├── app/                      Flutter app (run all flutter commands from here)
│   ├── lib/
│   │   ├── main.dart         Startup: loads config, theme, categories
│   │   ├── app/              App widget and route table
│   │   ├── core/             Constants, theme, shared widgets, utils
│   │   ├── data/             Local database, models, repositories, catalogs
│   │   │   ├── local/        Drift (SQLite) database + generated code
│   │   │   ├── models/       Plain data classes
│   │   │   ├── repositories/ Reads/writes for transactions and categories
│   │   │   └── catalogs/     Indian banks, predefined categories, keyword rules
│   │   ├── services/         Business logic, no UI
│   │   │   ├── auth/         Supabase auth, PIN, biometrics
│   │   │   ├── backend/      Supabase data (accounts, profile)
│   │   │   ├── categories/   Category registry used by the UI
│   │   │   ├── preferences/  Currency and language
│   │   │   └── sms/          SMS reading, parsing, background sync
│   │   └── features/         Screens, one folder per feature
│   ├── assets/images/        Onboarding art and bank logos
│   ├── android/              Android project
│   ├── test/                 Unit and widget tests
│   ├── pubspec.yaml
│   └── env.example.json      Template for env.json (Supabase keys)
├── backend/
│   └── supabase/migrations/  Database schema, applied in filename order
├── docs/
│   ├── setup/                RUN.md (how to run), AUTH_SETUP.md (Supabase setup)
│   ├── architecture/         DECISIONS.md, FLOW.md
│   ├── planning/             Design doc and implementation plan
│   └── design/               Screen designs
└── tools/                    Helper scripts
```

## Quick start

```powershell
cd app
Copy-Item env.example.json env.json   # then fill in your Supabase URL and key
flutter pub get
flutter run --dart-define-from-file=env.json
```

Full instructions, including Android setup and troubleshooting, are in
[docs/setup/RUN.md](docs/setup/RUN.md). Backend setup is in
[docs/setup/AUTH_SETUP.md](docs/setup/AUTH_SETUP.md).

## Tests

```powershell
cd app
flutter analyze
flutter test
```

## Bank logos

The logos in `app/assets/images/banks/` are renderings of each bank's logo
from its English Wikipedia article. They are trademarks of their respective
owners and are used only to identify the bank. Banks without a bundled logo
show a coloured monogram instead.
