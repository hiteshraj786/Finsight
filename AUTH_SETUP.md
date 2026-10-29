# FinSight authentication setup

This document lists every step used to set up authentication in FinSight, in the
order they are done. The app uses Supabase Auth for:

- email + password sign up with a 6-digit email verification code
- login with session persistence
- password recovery by email link
- Google sign-in

Emails are sent through Resend (custom SMTP). The app fails closed: if the Supabase
configuration is missing it shows "Authentication is not configured for this build"
and never falls back to a demo login.

---

## 1. Create the Supabase project

1. Go to supabase.com, sign in, and create an organization (if you do not have one).
2. Click **New project**, choose a name (for example `finsight`), set a database
   password (store it in a password manager), pick a region, and create it.
3. Wait until the project finishes provisioning.
4. Copy the **Project URL**: open **Project Settings → Data API** (or click the
   **Connect** button at the top). It looks like `https://<project-ref>.supabase.co`.
5. Copy the **Publishable key**: open **Project Settings → API Keys**.
6. Never put the `service_role` / secret key in the Flutter app, in `env.json`, in Git,
   in screenshots or in chat. Only the Project URL and the Publishable key go in the app.

## 2. Enable email + password sign up

1. Open **Authentication → Sign In / Providers → Email**.
2. Turn **Enable Email provider** on.
3. Turn **Confirm email** on. New users must verify their email before they can use
   the app.
4. Click **Save**.

## 3. Add the redirect URL

1. Open **Authentication → URL Configuration**.
2. Under **Redirect URLs** click **Add URL** and add exactly:

```
com.finsight.finsight://login-callback/
```

3. Click **Save**. This URL brings the user back into the app after Google sign-in
   and after tapping a password-recovery link.

## 4. Configure Resend (custom SMTP)

Supabase's built-in email service only delivers to members of your Supabase
organization and has a very low hourly limit, so a custom SMTP provider is used.

1. Create an account at resend.com.
2. Open **API Keys → Create API Key**, give it a name (for example `supabase-smtp`),
   and copy the key. It is shown only once. Store it in a password manager.
3. In Supabase open **Authentication → Emails → SMTP Settings** and turn on
   **Enable custom SMTP**.
4. Fill in the fields:

| Field | Value |
|---|---|
| Sender email | `onboarding@resend.dev` |
| Sender name | `FinSight` |
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | your Resend API key |

5. Click **Save**. All Supabase Auth emails (signup code, password recovery) now go
   through Resend.

Notes:
- `onboarding@resend.dev` is Resend's test sender. It delivers only to the email
  address of the Resend account owner. Other recipients need a domain verified in Resend.
- Never commit the Resend API key to the repository or paste it in chat.

## 5. Set up the email templates

Open **Authentication → Emails → Templates**. Editing templates needs custom SMTP
(section 4) to be on.

### Confirm sign up (the 6-digit code)

The app's Verification screen verifies the code the user types, so the email must
contain `{{ .Token }}`:

```html
<h2>Confirm your FinSight account</h2>
<p>Your verification code is:</p>
<h1>{{ .Token }}</h1>
<p>If you did not sign up, you can ignore this email.</p>
```

You may also keep `{{ .ConfirmationURL }}` in the same template for users who prefer
a link. Click **Save**.

### Reset password

Open the recovery template and make sure it keeps `{{ .ConfirmationURL }}`:

```html
<h2>Reset your FinSight password</h2>
<p><a href="{{ .ConfirmationURL }}">Reset password</a></p>
```

Its redirect goes to the Android deep link from section 3. Click **Save**.

## 6. Configure Google sign-in

1. Open console.cloud.google.com and create or select a project.
2. Open **APIs & Services → OAuth consent screen**. Choose **External**, set the app
   name (`FinSight`) and your support email, and save. While the app is in
   **Testing**, only Google accounts added under **Test users** can sign in.
3. Open **APIs & Services → Credentials → Create credentials → OAuth client ID**.
4. Application type: **Web application**.
5. Under **Authorized redirect URIs** add:

```
https://<project-ref>.supabase.co/auth/v1/callback
```

6. Click **Create** and copy the **Client ID** and **Client secret**.
7. In Supabase open **Authentication → Sign In / Providers → Google**, turn it on,
   paste the Client ID and Client secret, and click **Save**.
8. Check that `com.finsight.finsight://login-callback/` is still listed under
   **Authentication → URL Configuration → Redirect URLs** (section 3).

Never commit the Google client secret to the repository.

## 7. Android deep link

The app must be able to receive `com.finsight.finsight://login-callback/`.
Open `android/app/src/main/AndroidManifest.xml` and check that the main `<activity>`
contains:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.finsight.finsight" android:host="login-callback" />
</intent-filter>
```

Without it, the browser opens for Google sign-in or a recovery link but the app never
reopens. Rebuild the app after changing the manifest.

## 8. Run the app with the configuration

Create `env.json` in the project root (the same folder as `pubspec.yaml`):

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "<publishable-key>",
  "AUTH_REDIRECT_URL": "com.finsight.finsight://login-callback/"
}
```

Run:

```powershell
flutter run --dart-define-from-file=env.json
```

Rules:
- The variable names must match exactly: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
  `AUTH_REDIRECT_URL`.
- The values are fixed into the app at build time. After changing `env.json`, stop the
  app and run it again. Hot reload and hot restart do not pick up new values.
- Do not commit `env.json`; add it to `.gitignore`. A Supabase publishable key is
  designed to be inside a mobile app, but keep it out of Git anyway.
- If the configuration is missing the app shows "Authentication is not configured for
  this build".

## 9. How it works in the app

1. **Sign up:** the user enters name, email and password. Supabase sends the 6-digit
   code through Resend.
2. **Verification screen:** the user types the code. The app verifies it with Supabase
   and the user is signed in.
3. **Login:** email + password. The session is stored on the device, so the user stays
   signed in after the app is closed and reopened.
4. **Google sign-in:** the user signs in with Google, Supabase handles the callback, and
   the deep link returns the user to the app.
5. **Password recovery:** the user requests a reset, taps the link in the email, and the
   deep link opens the app.

## 10. Production checks

- RLS policies exist on every table that holds user data.
- Set Supabase Auth rate limits. Add a CAPTCHA token to the client before enabling
  Supabase CAPTCHA enforcement; enabling it without that integration blocks all
  authentication requests.
- Test on a physical Android device: sign up, wrong and expired code, resend
  throttling, login, Google callback, recovery-link callback, sign-out, session expiry.
- Use a release signing key instead of the debug signing configuration before
  publishing the APK/AAB.
