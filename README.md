# FinSight

Flutter personal-finance app with Supabase email/password authentication,
email verification, password recovery, Google OAuth, a local six-digit app
lock, and protected application routes.

See [AUTH_SETUP.md](AUTH_SETUP.md) for the required Supabase, Google, Android
callback, and production release setup.

## On-device insight jobs

Spending aggregation, recurring-payment detection, anomaly checks, budgets, and
notifications run only against the local Drift database and locally cached account
balances. Android's scheduler is best effort: aggressive battery managers on Xiaomi,
Oppo, and Vivo devices can delay periodic WorkManager jobs. When timely alerts matter,
allow FinSight to run without battery optimization in that device's battery settings.
Verify periodic jobs and notification permission behavior on a real device before a
release; emulators do not reliably reproduce OEM battery restrictions.
