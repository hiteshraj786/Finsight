# FinSight — App Flow

How the app behaves as of **2026-10-30**: the screens and routes, the
authentication flows, how the app decides where to go, and where data
flows. The Mermaid diagrams render on GitHub and in VS Code's Markdown
preview. See [DECISIONS.md](DECISIONS.md) for the reasons behind each choice.

---

## 1. Architecture

```mermaid
flowchart LR
  subgraph Device["Android device (Flutter app)"]
    UI["Screens<br/>lib/features/*"]
    AG["AuthGuard"]
    AS["AuthService"]
    PS["PinService"]
    FDS["FinanceDataService<br/>(read-only)"]
    SS[("flutter_secure_storage<br/>PIN hash + salt")]
    SP[("SharedPreferences<br/>OAuth pending flag,<br/>PIN attempts / lockout")]
  end

  subgraph Supabase
    AUTH["Supabase Auth"]
    DB[("Postgres + RLS<br/>profiles<br/>finance_accounts<br/>finance_transactions")]
  end

  RESEND["Resend SMTP"]
  GOOGLE["Google OAuth"]

  UI --> AG --> AS
  UI --> PS --> SS
  PS --> SP
  AS --> SP
  UI --> FDS --> DB
  AS <--> AUTH
  AUTH --> RESEND -->|"OTP / reset email"| User((User))
  AUTH <--> GOOGLE
  AUTH -->|"trigger handle_new_user"| DB
  GOOGLE -.->|"deep link<br/>com.finsight.finsight://login-callback/"| UI
```

**Startup (`main.dart`):**

1. `AuthService.initialize()` reads the build-time defines `SUPABASE_URL`,
   `SUPABASE_PUBLISHABLE_KEY` and `AUTH_REDIRECT_URL`. If they are missing,
   Supabase is not initialised and every auth call fails closed.
2. `FinSightApp` subscribes to `onAuthStateChange` (the global auth listener
   in section 4).
3. The app opens at `/` (Splash).

---

## 2. Route map

| Route | Screen | Guarded | Arguments |
|---|---|---|---|
| `/` | SplashScreen | – | – |
| `/onboarding` | OnboardingScreen (3 slides) | – | – |
| `/sign-up` | SignUpScreen | – | – |
| `/login` | LoginScreen | – | – |
| `/verification` | VerificationScreen | – | `String email` |
| `/sign-up-success` | SignUpSuccessScreen | – | – |
| `/forgot-password` | ForgotPasswordScreen | – | – |
| `/email-sent` | EmailSentScreen | – | `String email` |
| `/reset-password` | ResetPasswordScreen | – | – |
| `/setup-account` | SetupAccountScreen | ✅ | – |
| `/setup-pin` | SetupPinScreen | ✅ | – |
| `/unlock-pin` | EnterPinScreen | ✅ | – |
| `/add-account` | AddAccountScreen | ✅ | – |
| `/home` | HomeScreen | ✅ | – |
| *unknown route* | SplashScreen | – | – |

A guarded screen shows a spinner first. If `AuthService.isAuthenticated` is
false, it replaces the whole navigation stack with `/onboarding`.

---

## 3. Full screen flow

```mermaid
flowchart TD
  Start([App launch]) --> Splash["/ Splash<br/>min 1.6 s"]

  Splash -->|"OAuth pending?"| WaitG{"Wait for Google<br/>session (no timeout)"}
  WaitG -->|"session arrives"| Decide
  WaitG -->|"user taps 'Return to sign in'<br/>(shown after 10 s)"| Onb
  Splash -->|"no OAuth pending"| Decide{"Signed in?"}

  Decide -->|No| Onb["/onboarding"]
  Decide -->|Yes| HasPin{"PIN set on device?"}
  HasPin -->|Yes| Unlock["/unlock-pin"]
  HasPin -->|No| SetupAcc["/setup-account"]

  Onb -->|Sign Up| SignUp["/sign-up"]
  Onb -->|Login| Login["/login"]
  SignUp <-->|switch| Login

  SignUp -->|"email + password<br/>+ accept terms"| Verify["/verification<br/>6-digit OTP, resend after 5 min"]
  Verify -->|"OTP valid → session"| Success["/sign-up-success<br/>auto 2.5 s"]
  Success --> SetupAcc

  Login -->|"email + password OK"| HasPin
  Login -->|"Forgot password"| Forgot["/forgot-password"]
  Forgot --> Sent["/email-sent"]
  Sent -->|"Back to login"| Login
  Sent -.->|"user taps link in email<br/>→ deep link → passwordRecovery"| Reset["/reset-password"]
  Reset -->|"update password, then sign out"| Login

  SignUp -->|Google| GBrowser["Browser: Google consent"]
  Login -->|Google| GBrowser
  GBrowser -.->|"deep link → signedIn"| HasPin

  SetupAcc -->|"Let's go"| SetupPin["/setup-pin<br/>enter + confirm"]
  SetupPin -->|"PIN saved"| AddAcc["/add-account<br/>(form not saved yet)"]
  AddAcc -->|Continue| Home["/home"]

  Unlock -->|"correct PIN"| Home
  Unlock -->|"5 wrong → 5 min lock"| Unlock
  Unlock -->|"Forgot PIN → Reset & Logout"| Login
```

---

## 4. Global auth listener (`main.dart`)

These auth events run no matter which screen is open:

```mermaid
flowchart LR
  E{{"onAuthStateChange"}} -->|passwordRecovery| R["Clear stack → /reset-password"]
  E -->|signedOut| C["Clear _routedSessionToken"]
  E -->|signedIn| T{"Same access token<br/>already routed?"}
  T -->|Yes| X["Ignore"]
  T -->|No| D["Unfocus, wait 180 ms"] --> P{"PIN set?"}
  P -->|Yes| U["Clear stack → /unlock-pin"]
  P -->|No| S["Clear stack → /setup-account"]
```

> The Login and Verification screens also navigate themselves after a
> successful sign-in, so both they and this listener can push a route.
> See R-03 in DECISIONS.md.

---

## 5. Sequence diagrams

### 5.1 Email sign-up

```mermaid
sequenceDiagram
  actor U as User
  participant App
  participant SA as Supabase Auth
  participant R as Resend
  participant DB as Postgres

  U->>App: name, email, password, accept terms
  App->>SA: signUp(email, password, data.full_name, emailRedirectTo)
  SA->>DB: insert auth.users → trigger handle_new_user → profiles row
  SA->>R: send "Confirm sign up" email with {{ .Token }}
  R-->>U: 6-digit code
  App->>App: open /verification(email)
  U->>App: type code
  App->>SA: verifyOTP(email, token, type=signup)
  SA-->>App: session (signedIn event)
  App->>App: /sign-up-success → /setup-account → /setup-pin → /add-account → /home
```

### 5.2 Email login

```mermaid
sequenceDiagram
  actor U as User
  participant App
  participant SA as Supabase Auth
  U->>App: email + password
  App->>SA: signInWithPassword
  alt invalid credentials or AuthException
    SA-->>App: error
    App-->>U: "Invalid email or password." (always the same message)
  else email not confirmed
    SA-->>App: session, emailConfirmedAt = null
    App->>SA: signOut
    App-->>U: "Please verify your email before logging in."
  else success
    SA-->>App: session (stored on device)
    App->>App: has PIN? → /unlock-pin : /setup-account
  end
```

### 5.3 Google sign-in (cold start after browser return)

```mermaid
sequenceDiagram
  actor U as User
  participant App
  participant Prefs as SharedPreferences
  participant SA as Supabase Auth
  participant G as Google

  U->>App: Continue with Google
  App->>Prefs: set auth_google_oauth_pending = true
  App->>SA: signInWithOAuth(google, redirectTo=app scheme)
  SA->>G: consent screen (browser)
  G-->>SA: auth code
  SA-->>App: deep link com.finsight.finsight://login-callback/
  Note over App: The app may be relaunched → Splash
  App->>Prefs: pending? yes
  App->>App: wait for session (escape button after 10 s)
  SA-->>App: signedIn
  App->>Prefs: remove pending flag
  App->>App: /unlock-pin or /setup-account
```

### 5.4 Password recovery

```mermaid
sequenceDiagram
  actor U as User
  participant App
  participant SA as Supabase Auth
  participant R as Resend
  U->>App: email on /forgot-password
  App->>SA: resetPasswordForEmail(redirectTo=app scheme)
  App-->>U: "If that email has an account, a reset link has been sent." → /email-sent
  SA->>R: recovery email with {{ .ConfirmationURL }}
  U->>SA: taps link
  SA-->>App: deep link → passwordRecovery event
  App->>App: global listener → /reset-password
  U->>App: new password ×2
  App->>SA: updateUser(password)
  App->>SA: signOut
  App->>App: /login
```

### 5.5 PIN setup and unlock

```mermaid
stateDiagram-v2
  [*] --> EnterFirst: /setup-pin
  EnterFirst --> Confirm: 6 digits entered
  Confirm --> EnterFirst: mismatch
  Confirm --> Saved: match → PinService.setPin
  Saved --> [*]: /add-account

  state Unlock {
    [*] --> Typing
    Typing --> Check: 6 digits
    Check --> Home: hash matches → reset attempts
    Check --> Typing: wrong (attempts + 1)
    Check --> Locked: 5th wrong attempt
    Locked --> Typing: after 5 minutes
  }
```

PIN storage: `sha256("<base64url 32-byte salt>:<pin>")`. The hash and salt
are kept in `flutter_secure_storage` (`user_security_pin_hash_v2`,
`user_security_pin_salt_v2`). The attempt count and lock time are kept in
SharedPreferences.

---

## 6. Data flow (Home dashboard)

```mermaid
flowchart LR
  Home["/home initState"] --> L["FinanceDataService.loadDashboard()"]
  L -->|parallel| Q1["profiles.full_name"]
  L -->|parallel| Q2["finance_accounts<br/>is_active = true<br/>order balance_updated_at desc"]
  L -->|parallel| Q3["finance_transactions<br/>order occurred_at desc limit 10"]
  Q1 & Q2 & Q3 -->|"RLS: auth.uid() = owner"| M["FinanceDashboardData"]
  M --> V1["Usable balance = sum of savings + current"]
  M --> V2["Month spend = this month's debits<br/>(from the 10 rows loaded)"]
  M --> V3["Credit-card dues card"]
  M -->|"no accounts"| Empty["'No accounts yet' empty state"]
```

> Month spend only adds up the 10 most recent transactions, so it is too low
> once a month has more than 10.
>
> The app has **no write path** yet. Rows have to be inserted on the server
> (for example in the Supabase dashboard) before Home shows anything except
> the empty state.

---

## 7. Database

```mermaid
erDiagram
  AUTH_USERS ||--|| PROFILES : "trigger handle_new_user"
  AUTH_USERS ||--o{ FINANCE_ACCOUNTS : owns
  AUTH_USERS ||--o{ FINANCE_TRANSACTIONS : owns
  FINANCE_ACCOUNTS ||--o{ FINANCE_TRANSACTIONS : has

  PROFILES {
    uuid id PK
    text full_name
    text phone
  }
  FINANCE_ACCOUNTS {
    uuid id PK
    uuid user_id FK
    text provider_name
    text masked_account_number
    text account_type "savings|current|credit_card|loan|wallet|other"
    char currency "INR"
    numeric latest_balance
    bool is_active
  }
  FINANCE_TRANSACTIONS {
    uuid id PK
    uuid user_id FK
    uuid account_id FK
    text dedupe_hash "unique per account"
    numeric amount ">0"
    text direction "debit|credit"
    text merchant
    text category
    timestamptz occurred_at
    text source "sms|manual"
  }
```

Migrations, applied in this order:

1. `20261026_001_finance_foundation.sql`: tables, indexes, `updated_at`
   triggers, `handle_new_user`, RLS read policies.
2. `20261029_002_remove_bank_connect.sql`: removes the Account
   Aggregator/Setu tables, column and rows (`source = 'aa'`).

---

## 8. Planned flow not yet built (Phase 1 from the design doc)

```mermaid
flowchart LR
  SMS["Incoming bank SMS"] --> L["SMS listener<br/>another_telephony"]
  L --> P["transaction_sms_parser"]
  P -->|"low confidence"| F["Fallback regex templates"]
  P & F --> D{"Duplicate?<br/>dedupe_hash"}
  D -->|yes| X["Discard"]
  D -->|no| Pend["Save as PENDING"]
  Pend --> N["Confirmation popup / notification"]
  N -->|"confirm + category"| OK["CONFIRMED → dashboard"]
  N -->|ignore| IG["IGNORED"]
  OK --> W["WorkManager daily/weekly digest"]
```

What has to be built or decided first (details in DECISIONS.md):

- SMS and notification permissions in `AndroidManifest.xml`. Today the
  manifest only has `INTERNET`.
- A `status` column (pending / confirmed / ignored) on
  `finance_transactions`, or in a local Drift table.
- Write access: either RLS INSERT/UPDATE policies or an RPC (P-02).
- Where the data is stored: local, cloud, or both (P-01).
- Turn Add Account into a real form that saves to `finance_accounts`.
