# Running FinSight

How to get FinSight running on a Windows PC, step by step.

> **All `flutter` commands run inside the `app/` folder.** The Flutter project
> lives in `Finsight/app/`; the repo root only holds `app/`, `backend/`,
> `docs/` and `tools/`.

**Quick version** (once everything is installed):

```powershell
cd "D:\User\Sourish\Desktop\Sourish\College\Sec sem 5\Finsight\app"
flutter pub get
flutter run --dart-define-from-file=env.json
```

The steps below explain each part.

---

## 1. What you need

| Tool | Version | Why |
|---|---|---|
| Flutter SDK | **3.38 or newer** (Dart 3.10+) | `pubspec.yaml` requires `sdk: ^3.10.4` |
| Android SDK | API 34+ with platform-tools | Builds the Android app. Already installed at `%LOCALAPPDATA%\Android\Sdk` |
| JDK | 17 | Gradle 8.14 / Android Gradle Plugin (AGP) 8.11 build with Java 17 |
| Git | any | Getting the code |
| An Android phone **(recommended)** or emulator | Android 6.0+ | SMS import needs real SMS. Emulators have none |
| VS Code + **Flutter** extension | latest | Optional, but `.vscode/launch.json` is already set up |

> FinSight is **Android only**. SMS reading doesn't work on iOS, and the repo
> has no `ios/`, `web/` or `windows/` folders. `flutter run -d chrome` or
> `-d windows` will not work.

---

## 2. Install Flutter (fix for "flutter is not recognized")

This error means Windows can't find the `flutter` command. On this PC, the
PATH points to `C:\Users\souri\OneDrive\Desktop\Sourish\Flutter\flutter\bin`,
but **that folder no longer exists**, so the SDK has to be installed again.

1. Download the latest **stable** Flutter SDK for Windows (zip) from
   <https://docs.flutter.dev/get-started/install/windows/mobile>.
2. Extract it to a short path **outside OneDrive**, for example
   `C:\src\flutter`. OneDrive can move files to the cloud and leave
   placeholders behind, which is probably what broke the old install. Avoid
   paths with spaces too.
3. Fix your PATH:
   - Press Start, type **"environment variables"**, and open *Edit the
     environment variables for your account*.
   - Under **User variables**, select **Path** → **Edit**.
   - **Delete** the old entry
     `C:\Users\souri\OneDrive\Desktop\Sourish\Flutter\flutter\bin`.
   - **Add** `C:\src\flutter\bin`, then click OK on every window.
4. **Close every terminal and VS Code**, then reopen them. Terminals only read
   PATH when they start.
5. Check it worked:

   ```powershell
   flutter --version
   flutter doctor
   ```

6. Fix anything `flutter doctor` flags. The usual ones:

   ```powershell
   flutter doctor --android-licenses     # type y to accept each licence
   ```

   - **"cmdline-tools component is missing"**: install Android Studio, or in
     Android Studio open *SDK Manager → SDK Tools*, tick **Android SDK
     Command-line Tools**, and apply.
   - **Java version errors** (for example "JVM creation failed"): the build
     needs JDK 17 or newer, and Java 8 will not work. Install one (Android
     Studio includes one), then run
     `flutter config --jdk-dir "C:\Program Files\Java\jdk-24"` (use your
     JDK's folder).
   - **"Android sdkmanager did not install NDK 28.2.13676358"**: install
     the NDK with the new Android CLI. The package name uses `/`, not `;`:

     ```powershell
     $env:JAVA_HOME = "C:\Program Files\Java\jdk-24"
     & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\android.exe" sdk install ndk/28.2.13676358
     ```

> Quick fix for one terminal only, if Flutter is already somewhere else:
> `$env:Path += ";C:\src\flutter\bin"`. It stops working when you close the
> terminal.

---

## 3. Get the code

```powershell
git clone https://github.com/hiteshraj786/Finsight.git
cd Finsight
git fetch origin
git switch feature/profile-navigation-localization
```

If you already have the repo, go into the `Finsight` folder and run
`git switch feature/profile-navigation-localization`, then `git pull`.

Then go into the Flutter project and install the packages:

```powershell
cd app
flutter pub get
```

The Drift database code (`app/lib/data/local/app_database.g.dart`) is already
committed. You only need to regenerate it if you change
`app/lib/data/local/app_database.dart` (run from `app/`):

```powershell
dart run build_runner build
```

---

## 4. Create `env.json` (required)

The app reads its Supabase settings at build time. **If they are missing, the
app opens but every login fails** with "Authentication is not configured for
this build". This is deliberate: the app never falls back to a fake login.

1. Copy the template:

   ```powershell
   cd app
   Copy-Item env.example.json env.json
   ```

2. Fill in the real values. Get them from the person who owns the Supabase
   project, or from your own project (*Project Settings → API Keys / Data
   API*):

   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "<publishable key>",
     "AUTH_REDIRECT_URL": "com.finsight.finsight://login-callback/"
   }
   ```

- `env.json` is ignored by Git. **Never commit it.**
- Only use the **publishable** key. Never put the `service_role` / secret key
  in the app.

---

## 5. Backend setup (only if you use your own Supabase project)

Skip this if your team already has a Supabase project set up. To use a new
one, follow [AUTH_SETUP.md](AUTH_SETUP.md) for the email provider, redirect
URL, Resend SMTP, email templates and Google sign-in. Then apply the
migrations **in order**:

| # | File | What it does |
|---|---|---|
| 1 | `backend/supabase/migrations/20261026_001_finance_foundation.sql` | `profiles`, `finance_accounts`, `finance_transactions`, triggers, read policies |
| 2 | `backend/supabase/migrations/20261029_002_remove_bank_connect.sql` | Removes the old Account Aggregator tables |
| 3 | `backend/supabase/migrations/20261030_003_profile_account_settings.sql` | Profile preference columns, plus insert/update/delete policies so the app can save accounts and transactions |

Apply them either way:

- **Supabase CLI:** from the `backend/` folder, run
  `supabase link --project-ref <ref>` and then `supabase db push`
- **Dashboard:** open *SQL Editor*, then paste and run each file in order.

> If migration 3 is missing, the Profile screens and **Add Account** fail,
> because the app isn't allowed to write those rows.

---

## 6. Connect a device

**Physical phone (recommended, and needed for SMS import):**

1. On the phone, open *Settings → About phone* and tap **Build number** 7
   times to turn on Developer options.
2. In *Settings → Developer options*, turn on **USB debugging**.
3. Connect the phone by USB and accept the "Allow USB debugging?" prompt.
4. Check that it's detected:

   ```powershell
   flutter devices
   ```

**Emulator:** create one in Android Studio (*Device Manager*), or list the
existing ones:

```powershell
flutter emulators
flutter emulators --launch <emulator_id>
```

To test SMS import on an emulator, send a fake bank SMS from the emulator's
*Extended controls (⋯) → Phone → SMS message*. For example:
`Rs.500.00 debited from A/c XX1234 on 30-10-26 to SWIGGY. Ref 123456789`.

---

## 7. Run the app

**Terminal:**

```powershell
flutter run --dart-define-from-file=env.json
```

If more than one device is connected, add `-d <device-id>` (the ID comes from
`flutter devices`).

While it runs, press **`r`** for a hot reload, **`R`** for a hot restart, and
**`q`** to quit.

**VS Code:** open the `Finsight` folder, pick the device in the bottom-right
corner, and press **F5**. The **FinSight** launch configuration in
`.vscode/launch.json` already passes `--dart-define-from-file=env.json`.

---

## 8. What to expect on first run

1. Splash → Onboarding → **Sign Up** with a real email address you can open.
   - While the project uses Resend's test sender (`onboarding@resend.dev`),
     **emails only go to the Resend account owner's address**. Use that
     address, or ask the backend owner to add a verified domain.
2. Enter the 6-digit code from the email → Setup Account → **set a 6-digit
   PIN** → Add Account → Home.
3. The app asks for permissions:
   - **SMS** (`READ_SMS`, `RECEIVE_SMS`) for importing bank SMS. Grant it
     once from *Activity → Scan SMS*. After that, importing is automatic:
     new bank SMS appear with a confirmation popup while the app is open,
     and anything received while the app was closed or in the background is
     imported when you return to it. Transactions are stored **on the
     phone** in a Drift/SQLite database (`finsight_sms`).
   - **Biometric** (optional) to unlock with a fingerprint instead of the
     PIN, from *Profile → Security*.
4. On later launches you unlock with the PIN (or fingerprint) and don't need
   to log in again.

---

## 9. Other useful commands

| Task | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Run tests | `flutter test` |
| Debug APK to share | `flutter build apk --debug --dart-define-from-file=env.json` → `build\app\outputs\flutter-apk\app-debug.apk` |
| Release APK | `flutter build apk --release --dart-define-from-file=env.json` (still signed with the debug key, so not ready for the Play Store) |
| Clean build | `flutter clean`, then `flutter pub get` |
| After switching branches | `flutter pub get` (and `flutter clean` if the build behaves strangely) |

---

## 10. Troubleshooting

| Problem | Fix |
|---|---|
| `flutter : The term 'flutter' is not recognized` | Flutter isn't installed or isn't on PATH. See section 2, and reopen the terminal afterwards |
| `The current Dart SDK version is X … requires ^3.10.4` | Flutter is too old. Run `flutter upgrade` |
| "Authentication is not configured for this build" | `env.json` is missing or empty, or you ran without `--dart-define-from-file=env.json` |
| Sign-up code email never arrives | Resend test sender limit (section 8), or SMTP isn't set up (AUTH_SETUP.md section 4). Check the spam folder too |
| Google sign-in returns to the browser or does nothing | The redirect URL `com.finsight.finsight://login-callback/` isn't in Supabase *URL Configuration*, or your Google account isn't a test user on the OAuth consent screen |
| Add Account or Profile save fails / "permission denied" | Migration 3 hasn't been applied (section 5) |
| SMS import finds nothing | Emulator with no SMS, or the permission was denied. Allow it in *App info → Permissions → SMS* |
| Gradle build fails with a Java error | Use JDK 17 (`flutter config --jdk-dir ...`), then `flutter clean` |
| `No connected devices` | Turn on USB debugging, accept the prompt on the phone, and try another cable or port |
| Build is slow the first time | Normal. Gradle downloads about 1 GB the first time |
