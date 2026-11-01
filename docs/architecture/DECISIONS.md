# FinSight — Decision Log

This log records the architecture and product decisions in the code. Each
entry says what was decided, why, and what follows from it. Where the code
moved away from the original plan
([finsight-design-doc.txt](../planning/finsight-design-doc.txt),
[finsight_implementation_plan.md](../planning/finsight_implementation_plan.md)),
the entry says so.

> D-01 to D-12, the "current state" table and the risk register describe the
> `main` branch as reviewed on **2026-10-30**. D-13 onwards were added on
> **2026-11-01** with the restructure, and some earlier gaps are now closed
> (SMS ingestion, saving accounts, local Drift storage).

Status key: **Accepted** = in the code now · **Superseded** = tried and
reversed · **Pending** = planned but not built.

---

## Current state at a glance

| Area | Planned (design doc) | Built so far |
|---|---|---|
| Framework | Flutter, Android-first | Flutter, Android-first ✅ |
| Auth | Not in the plan (fully local app) | Supabase Auth: email + OTP, Google OAuth, password reset ✅ |
| App lock | — | Local 6-digit PIN with lockout ✅ |
| Storage | On-device Drift/SQLite | Supabase Postgres with RLS (read-only from the app) ⚠️ |
| State management | Riverpod | Static service classes + `setState` ⚠️ |
| SMS ingestion | another_telephony + transaction_sms_parser | Not started ❌ |
| Accounts | Multi-account management | UI only; nothing is saved ❌ |
| Home dashboard | Summary, recent transactions | Reads from Supabase; empty unless rows are inserted on the server ⚠️ |
| Insights, budgets, Splitwise | Phases 2–3 | Not started ❌ |
| Tests | Parser, dedupe, DAO tests | One widget smoke test ⚠️ |

In short, the onboarding, authentication and security shell is done. The core
finance feature (capturing transactions) has not been built yet.

---

## D-01 · Flutter, Android-first

**Status:** Accepted

- **Decision:** Build in Flutter with package id `com.finsight.finsight` and
  target Android first.
- **Why:** The core feature, reading bank SMS, only works on Android. iOS does
  not let apps read the SMS inbox. Flutter keeps the UI and logic shareable if
  iOS is added later with a different way to bring in transactions.
- **Consequence:** Only `android/` exists. No iOS or web folders are set up.

## D-02 · Supabase as the backend (a change from the "no backend" plan)

**Status:** Accepted — **changes the original plan**

- **Decision:** Use Supabase for authentication and Postgres for finance data
  (`profiles`, `finance_accounts`, `finance_transactions`) instead of an
  on-device Drift database.
- **Why (inferred from the code):** It gives user accounts, email
  verification, password recovery and Google sign-in without running our own
  server, and the data is available on any device.
- **Consequences:**
  - The design doc's main privacy promise, "SMS content never leaves the
    phone", no longer holds by default. Parsed transactions would be stored in
    the cloud. The SMS phase needs a clear rule here: either upload only
    parsed fields (amount, merchant, masked account), never the raw SMS text,
    or keep a local store and sync only summaries.
  - The app needs a network connection to show any data. The planned
    "offline-first" requirement is not met.
  - The migrations live in `supabase/migrations/` and must be applied in order.

## D-03 · Fail-closed authentication, no demo login

**Status:** Accepted

- **Decision:** If `SUPABASE_URL` or `SUPABASE_PUBLISHABLE_KEY` is missing,
  every auth call returns "Authentication is not configured for this build".
  There is no local or demo login.
- **Why:** In a finance app, a failed auth request must never become a
  signed-in session.
- **How:** Configuration is passed at build time through
  `--dart-define-from-file=env.json` (`String.fromEnvironment`). `env.json`
  is ignored by Git, and `env.example.json` is the template. Only the
  publishable key ships in the app. The `service_role` key never does.

## D-04 · Email + password sign-up verified with a 6-digit code

**Status:** Accepted

- **Decision:** Sign-up sends a 6-digit OTP (`{{ .Token }}` in the email
  template). The user types it in the app (`verifyOTP`, type `signup`) instead
  of tapping a magic link.
- **Why:** Typing a code works inside the app and does not depend on the
  device opening a link correctly.
- **Details:** The resend timer is 5 minutes (`AppConstants.otpResendDuration`).
  Login also signs the user out again if `emailConfirmedAt` is null.

## D-05 · Resend as the custom SMTP provider

**Status:** Accepted (development setup)

- **Decision:** Send Supabase Auth email through Resend (`smtp.resend.com:465`).
- **Why:** Supabase's built-in mailer only delivers to members of the
  organisation and has a very low hourly limit.
- **Limitation:** The sender `onboarding@resend.dev` only delivers to the
  Resend account owner. Real users need a domain verified in Resend before
  launch.

## D-06 · Google sign-in via Supabase OAuth and a deep link

**Status:** Accepted

- **Decision:** Google sign-in goes through `signInWithOAuth` in the browser
  and returns to the app on `com.finsight.finsight://login-callback/`. Password
  recovery uses the same redirect.
- **The problem it solves:** When Android brings the app back from the
  browser, the splash screen could run before the session was saved, briefly
  showing onboarding or sign-up.
- **The fix:** Before opening the browser, the app saves an
  `auth_google_oauth_pending` flag in SharedPreferences. On launch, the splash
  screen waits for the session with **no automatic timeout**. After 10 seconds
  it shows a "Having trouble? Return to sign in" button so the user can leave.
- **Trade-off:** We chose to wait (with a manual way out) over a timeout that
  could cause a visible flicker.

## D-07 · No account enumeration, safe error messages

**Status:** Accepted

- Login always says "Invalid email or password". Password reset always says
  "If that email has an account…".
- `_safeAuthMessage` maps Supabase errors to a few generic messages (rate
  limit, weak password, anything else) so server details are never shown.

## D-08 · Local 6-digit PIN as an app lock (not a login)

**Status:** Accepted

- **Decision:** After Supabase sign-in, the user sets a 6-digit PIN. On later
  launches with a saved session, they unlock with the PIN instead of the
  password.
- **Storage:** A salted SHA-256 hash with a 32-byte random salt, kept in
  `flutter_secure_storage` (Android Keystore). The PIN itself is never stored.
- **Brute-force limit:** 5 wrong attempts lock the PIN for 5 minutes. The
  attempt count and lock time are kept in SharedPreferences.
- **Fails closed:** If secure storage throws, `hasPin()` returns false. The
  user is sent to PIN setup, never into the app.
- **Known weaknesses (see the risk register):** the PIN is per device, not per
  user. The lockout counter is in normal, non-secure storage. A single SHA-256
  is fast to brute-force if the hash is ever extracted. A slow key-derivation
  function (KDF) or a Keystore-bound key would be stronger.

## D-09 · Route guarding with `AuthGuard` and a global auth listener

**Status:** Accepted

- **Decision:** Every screen that needs a signed-in user (setup account, setup
  PIN, unlock PIN, add account, home) is wrapped in `AuthGuard`. If there is
  no session, it sends the user to onboarding.
- `main.dart` listens to `onAuthStateChange`:
  - `passwordRecovery` → Reset Password
  - `signedIn` → Unlock PIN if a PIN exists, otherwise Setup Account.
    `_routedSessionToken` stops the same session from being routed twice.
  - `signedOut` → clears that token
- **Trade-off:** Navigation uses plain named routes with `onGenerateRoute` (no
  go_router). It is simple, but some screens (Login, Verification, Sign-up
  Success) also navigate themselves, so two places can try to navigate at
  once (see R-03).

## D-10 · Feature-first folder structure, no state-management library yet

**Status:** Accepted (a simpler version of the plan)

- `lib/core/` holds constants, services, theme and widgets.
  `lib/features/<feature>/screens` holds the screens.
- The services are static classes (`AuthService`, `PinService`,
  `FinanceDataService`). Screens use `StatefulWidget` + `setState` and
  `FutureBuilder`.
- **Why:** There is very little shared state while the app is mostly
  authentication. Riverpod from the plan has not been added.
- **Revisit when:** transactions, categories and SMS events need to be shared
  across screens. Add Riverpod (or similar) then, not after.

## D-11 · Finance data model with row-level security

**Status:** Accepted

- `profiles` is filled automatically by the `handle_new_user` trigger from
  `raw_user_meta_data.full_name`.
- `finance_accounts` has account types `savings | current | credit_card |
  loan | wallet | other`, defaults to INR, and is unique on
  (user, provider, masked number, type).
- `finance_transactions` has amount > 0, direction `debit | credit`, source
  `sms | manual`, and a `dedupe_hash` unique per account. This builds the
  design doc's duplicate detection into the database.
- RLS is on for all three tables. **Only SELECT policies exist** (plus UPDATE
  on profiles). The app cannot insert accounts or transactions. This
  read-only access is on purpose (`FinanceDataService`), but it means the
  write path is still undecided (see P-02).
- On the dashboard, "Usable balance" counts only savings and current
  accounts. Credit-card balances are shown separately as dues.

## D-12 · Account Aggregator / Setu removed

**Status:** Superseded (reversed by `20261029_002_remove_bank_connect.sql`)

- An earlier version had bank linking through India's Account Aggregator
  (Setu): `finance_consents`, `consent_audit_events`, `consent_id`, and
  source = `aa`.
- **Decision:** Remove it. The migration drops these tables and the column,
  deletes rows with `aa` as the source, and limits `source` to
  `sms | manual`.
- **Why (inferred):** An AA integration needs regulatory onboarding and a
  backend. That is too much for the current scope, and the plan's SMS-first
  approach fits better.
- **Leftover:** The onboarding image `Add new account_Bank.png` and the
  bank-picker UI still exist.

## D-13 · Repository split into `app/`, `backend/`, `docs/`, `tools/`

**Status:** Accepted (2026-11-01)

- **Decision:** The Flutter project moved into `app/`, the Supabase
  migrations into `backend/supabase/`, and all Markdown and design files into
  `docs/`. Inside `app/lib/`, code is layered as `core/` (shared UI basics),
  `data/` (database, models, repositories, catalogs), `services/` (logic with
  no UI) and `features/` (screens). `main.dart` only starts the app. The app
  widget and routes live in `lib/app/`.
- **Why:** The repo root mixed app code, SQL and documents, and the SMS
  feature folder held the app-wide database and parsing services.
- **Consequence:** Run `flutter` commands from `app/`. `env.json` lives in
  `app/`. All moves used `git mv`, so file history is kept.

## D-14 · One shared database connection

**Status:** Accepted (2026-11-01)

- **Decision:** `AppDatabase.instance` is the only connection to the local
  SQLite file. Repositories use it by default.
- **Why:** `loadDashboard()` opened a new connection each time Home loaded and
  never closed it. Several connections to one SQLite file cause lock
  contention and stalls.

## D-15 · Automatic SMS sync in `SmsSyncService`

**Status:** Accepted (2026-11-01)

- **Decision:** Once SMS permission is granted, a service started by the
  main shell (a) listens for incoming SMS while the app is open and (b) on
  every app start or resume imports only the SMS newer than the last check,
  using an inbox query filtered by date. Parsing runs in a background
  isolate (`compute`).
- **Why:** Before this, new SMS were only caught while the SMS review screen
  was open. The resume check also read the whole inbox and parsed it on the
  UI thread, which froze the app on return from other apps. That check never
  ran after a first full import anyway, because the import did not record the
  "last checked" time.
- **Limits:** Nothing runs while the app process is killed. Those SMS are
  imported on the next launch. A true background listener would need
  `listenInBackground: true` with a top-level handler, plus notifications.

## D-16 · Custom categories with keywords

**Status:** Accepted (2026-11-01)

- **Decision:** A `CustomCategories` table (Drift schema v3, migrated from v2)
  stores user categories with an icon and optional keywords. Auto-categorizing
  checks, in order: learned merchant rules → custom-category keywords →
  built-in keywords → Uncategorized. Renames and deletes carry over to
  existing transactions.
- **Why:** The category list was hard-coded, and any other name was shown as
  "Uncategorized".

## D-17 · Bundled Indian bank catalog with logos

**Status:** Accepted (2026-11-01)

- **Decision:** 57 banks and wallets in `data/catalogs/indian_banks.dart`,
  covering public, private, small finance, payments and foreign banks plus
  UPI wallets. 47 have bundled logos (rendered from each bank's Wikipedia
  infobox). The rest show a coloured monogram. One searchable picker is
  used by both Add Account and the account editor. Saved accounts are matched
  back to a bank by name.
- **Why:** The two pickers had separate short lists, and one offered US banks.

## D-18 · Payment popup over other apps, 5 s after the SMS

**Status:** Accepted (2026-11-01)

- **Decision:** When a bank SMS arrives while FinSight is not on screen,
  `onBackgroundSms` (a background isolate started by the telephony plugin's
  `IncomingSmsReceiver`) stores the transaction. Then, 5 seconds after the
  SMS, it shows a small card over the current app using
  `flutter_overlay_window`. The card runs in its own engine (`overlayMain`)
  and reads the transaction id from `app_states`. If FinSight is open, the
  in-app popup shows instead, also after 5 seconds.
- **Why:** You can categorise a payment in GPay/PhonePe without switching
  apps. The delay lets the payment app show its own success screen first.
- **Needs:** the "Display over other apps" permission (asked once, and
  in *Settings → Payment popups*), plus the SMS receiver in the manifest.
  The receiver was missing before, so live SMS were never delivered.
- **Limits:** Battery savers on some phones (Samsung "sleeping apps",
  Xiaomi) can stop the background handler. Users should set battery to
  Unrestricted. Google Play restricts `SYSTEM_ALERT_WINDOW`, so a Play
  release would need a declared use case or a heads-up notification instead.
- Several connections can now write the local database at once (app,
  background handler, popup), so `busy_timeout` is set and the app re-reads
  its data on resume.

## D-19 · Dark mode for the SMS / Activity screens

**Status:** Accepted (2026-11-01)

- **Decision:** The SMS module's `AppColors` are getters that return a light
  or dark value based on `AppTheme.themeMode`. `AppTheme.current` builds the
  matching `ThemeData`. Screens call `AppColors.rebuildOnThemeChange` so a
  theme switch repaints them.
- **Consequence:** These colours are no longer compile-time constants, so
  widgets using them cannot be `const`.

---

## Pending decisions

| ID | Question | Options | Recommendation |
|---|---|---|---|
| P-01 | Where do parsed SMS transactions live? | (a) Drift on device only (original plan) · (b) Supabase only · (c) Drift on device + sync parsed fields to Supabase | **(c)**: offline-first and private (no raw SMS uploaded), and the dashboard keeps working |
| P-02 | How are accounts and transactions written? | (a) Add INSERT/UPDATE RLS policies scoped to `auth.uid()` · (b) Write through an Edge Function / RPC that validates input | (a) is enough for manual entry. Use (b) if server-side dedupe or validation is needed |
| P-03 | Add Account screen data | It offers US banks (Chase, BoA…) and types `Bank / Wallet / Credit Card / Cash`. The DB allows `savings / current / credit_card / loan / wallet / other` and expects INR | Change the UI to Indian institutions and the DB's type list, and save on Continue |
| P-04 | State management | Riverpod (planned) vs keep `setState` | Add Riverpod before the SMS and transactions work |
| P-05 | SMS packages | another_telephony vs android_sms_reader; vendor transaction_sms_parser | Do the hands-on comparison the design doc asks for |
| P-06 | Production email sender | Verified Resend domain | Required before real users |
| P-07 | Logout | There is no logout button in the app | Add one in a Profile tab |

---

## Risk register (found while reviewing the code)

| ID | Severity | Issue | Where | Suggested fix |
|---|---|---|---|---|
| R-01 | **High** | "Reset & Logout" on the PIN screen clears the PIN but **does not sign out of Supabase**. On the next launch the session is still valid and there is no PIN, so the splash screen goes to Setup Account. Anyone holding the phone can set a new PIN and get in without the password. | [enter_pin_screen.dart](lib/features/auth/screens/enter_pin_screen.dart) | Call `AuthService.signOut()` before going to Login |
| R-02 | Medium | The PIN is stored per device, not per user. If user B signs in on a device where user A set a PIN, B is asked for A's PIN. | [pin_service.dart](lib/core/services/pin_service.dart) | Include the user id in the PIN storage keys, or clear the PIN on sign-out and when the user changes |
| R-03 | Medium | Two navigations can race after sign-in. The global `signedIn` listener in `main.dart` and the screen's own navigation (Login, Verification → Sign-up Success) both push routes. After OTP verification, the listener may skip the Sign-up Success screen. | [main.dart](lib/main.dart), [verification_screen.dart](lib/features/auth/screens/verification_screen.dart) | Let one place own post-auth routing |
| R-04 | Medium | Add Account does nothing: `_onContinue` ignores the form and goes to Home, which then shows "No accounts yet". | [add_account_screen.dart](lib/features/setup/screens/add_account_screen.dart) | See P-02 and P-03 |
| R-05 | Low | The lockout counter is in SharedPreferences. Clearing app data resets it, but that also wipes the PIN, so the impact is limited. | `PinService` | Optionally move it to secure storage |
| R-06 | Low | The Verification screen falls back to `'your email'` as the email address if the route argument is missing. | `VerificationScreen` | Block the screen when the email is missing |
| R-07 | Low | The Home bottom navigation only highlights the tapped tab. The other tabs have no screens. | `HomeScreen` | Build the tabs or hide them |
| R-08 | Low | `convert.ps1` has hard-coded paths from another machine (`C:\Users\hites\...`). | `convert.ps1` | Delete it, or use relative paths |
