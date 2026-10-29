# Production authentication setup

The app uses Supabase Auth for email/password accounts, signup verification,
password recovery, session persistence, and Google OAuth. It fails closed when
the Supabase configuration is absent; there is no demo login or test OTP.

## 1. Create and configure Supabase

1. Create a Supabase project and copy its Project URL and **Publishable key**.
   Never put the `service_role` key in this app.
2. In **Authentication → Providers → Email**, enable email/password sign-in and
   enable **Confirm email**.
3. In **Authentication → URL Configuration**, add this Redirect URL exactly:
   `com.finsight.finsight://login-callback/`
4. In the **Confirm signup** email template, include `{{ .Token }}` as a
   six-digit verification code. The app verifies that token on its Verification
   screen. You may also keep `{{ .ConfirmationURL }}` for users who prefer a
   link.
5. In **Authentication → Email Templates**, ensure the recovery template keeps
   `{{ .ConfirmationURL }}`. Its redirect target is the Android deep link above.
6. Before production, configure a custom SMTP provider and a verified sending
   domain. The default Supabase email service is not a production mail service.

## 2. Configure Google (only if you want Google sign-in)

1. In Google Cloud Console, create OAuth credentials and add Supabase's callback
   URL: `https://<your-project-ref>.supabase.co/auth/v1/callback`.
2. Copy the Google client ID and client secret into **Authentication → Providers
   → Google** in Supabase.
3. Keep `com.finsight.finsight://login-callback/` in Supabase's Redirect URLs.

## 3. Run the app with credentials

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-publishable-key> `
  --dart-define=AUTH_REDIRECT_URL=com.finsight.finsight://login-callback/
```

Use your CI/CD secret store for these values. Do not commit a real key to the
repository. A Supabase publishable/anon key is designed to be present in a
mobile app; database Row Level Security (RLS) must protect every user table.

## 4. Mandatory production checks

- Add RLS policies to every finance/profile table before connecting app data.
- Set Supabase Auth rate limits. Add a client CAPTCHA token integration before
  enabling Supabase CAPTCHA enforcement; enabling it without that integration
  intentionally blocks authentication requests.
- Test signup, expired/wrong OTP, resend throttling, login, Google callback,
  recovery-link callback, sign-out, session expiry, and app-lock recovery on a
  physical Android device.
- Create a release signing key and replace the debug signing configuration
  before publishing the APK/AAB.
