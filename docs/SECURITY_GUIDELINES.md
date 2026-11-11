# Security Guidelines (Flutter)

> **For the AI coding agent:** Every rule in this file is **mandatory** for every piece of code you write or change in this project.
> - Before writing code that touches **storage, networking, authentication, crypto, logging, permissions, platform config (AndroidManifest / Info.plist / Gradle), or build/release**, read the matching section and follow its patterns.
> - If a user request conflicts with a **MUST / MUST NOT** rule, do not silently comply. Explain the risk, propose the secure alternative, and wait for confirmation.
> - Never weaken an existing security control (pinning, obfuscation, secure storage, rules, RASP) as a "quick fix" for a bug or build error. Find the root cause instead.
> - Package APIs change between major versions. Before using a package, check the version in `pubspec.yaml` and adapt the snippets below to it.
> - When you finish a task, go through the **Pre-Merge Checklist** (section 15) for the parts of the code you touched.
> - Read **section A (Core Principle)** and **section C (Risk Profile)** first. The risk profile decides which controls this project needs. If `project.md` / `CLAUDE.md` does not state a risk profile, ask the user before adding high-cost controls (certificate pinning, RASP, screen protection).

---

## A. Core Principle: Client-Side vs Server-Side Security

**The mobile app runs on a device the attacker controls.** Anything inside the app can be read, changed, or bypassed. The attacker can:

- Decompile the app and read its code and strings, even with obfuscation.
- Find every API endpoint and call it directly with `curl` or Postman, without the app.
- Extract any key or secret embedded in the app.
- Modify the app (or hook it at runtime with Frida) to skip any client-side check: the paywall, the admin check, the score limit, root detection, certificate pinning.
- Change any value the app sends: price, quantity, score, user ID, role.

Therefore:

| You **cannot** guarantee… | So instead… |
|---|---|
| …that the API address stays hidden | Secure every endpoint as if it were public |
| …that a key embedded in the app stays secret | Keep real secrets on the server; restrict any key that must ship |
| …that obfuscation prevents reverse engineering | Treat obfuscation only as a cost increase for the attacker |
| …that root/jailbreak detection cannot be bypassed | Treat RASP as an extra signal, never as the only protection |
| …that the client sends honest data | **Validate and recompute everything critical on the server** |

> **The goal of security is not to make the app impossible to inspect. The goal is that even when an attacker inspects or modifies the app, they still cannot break the security of the system.**

### Rules that follow from this principle (for the agent)

1. **Every security decision has a server-side source of truth.** A client-side check is allowed only *in addition to* a server-side check, for user experience. It never replaces it.
2. **Never trust values computed on the client** for anything that matters:
   - ❌ The client sends `{ "productId": 5, "price": 10 }`. The server charges 10.
   - ✅ The client sends `{ "productId": 5, "quantity": 1 }`. The server looks up the price in its own database.
   - ❌ The client sends `{ "score": 99999 }` at the end of a game. The server saves it.
   - ✅ The server checks that the score is plausible (time played, max points per second), or computes it from the game events.
   - ❌ The client sends `{ "userId": "abc" }` to read a profile.
   - ✅ The server takes the user ID from the verified auth token, not from the request body.
3. **Never decide permissions on the client.** Hiding the admin button is UX. Rejecting the admin request is security, and it happens on the server or in Firebase rules.
4. **Assume every endpoint will be called directly.** Each endpoint checks authentication, authorization, input validity, and rate limits by itself.
5. **When a client-side control fails, the damage must stay limited.** Ask: "If an attacker removes this check from the app, what happens?" If the answer is "they get someone else's data / free items / admin access", the check is in the wrong place. Move it to the server.

### Where the logic goes in Firebase projects

There is no "own backend" in a Firebase-only app, so:
- **Firestore/Storage Security Rules** are the server-side authorization and validation layer. They must check ownership, field types, allowed fields, and value ranges.
- **Critical operations** (payments, balance changes, points/rewards, role changes, anything involving another user's data, calls to secret-key APIs) go into **Cloud Functions**, never into client code.
- **Firebase App Check** reduces abuse from modified apps and scripts. It is not a replacement for rules.

---

## B. Security Architecture Layers

Security works in layers (defense in depth). Each layer assumes the layers outside it can fail.

| # | Layer | Controls | Where in this file |
|---|---|---|---|
| 1 | **Application layer** | Code obfuscation, root/jailbreak detection, anti-tampering (RASP), screen protection | Sections 8, 10 |
| 2 | **Device security** | `local_auth` (biometrics), `flutter_secure_storage`, secure token handling, logout cleanup | Sections 3, 5.2 |
| 3 | **Communication security** | HTTPS/TLS only, certificate pinning, secure API client, timeouts | Section 4 |
| 4 | **Server security** | Authentication, authorization, rate limiting, input validation, **transaction verification** | Sections A, 5, 6, D |
| 5 | **Data security** | Encryption at rest, secure/encrypted databases, backup rules, access control | Sections 3, 7.1, 12, 5.3 |

> Layers 1–3 make attacks **harder and more expensive**. Layers 4–5 make attacks **fail**. If time is limited, invest in layers 4 and 5 first.

---

## C. Risk Profile: Choosing the Right Controls

Not every project needs every control at the same level. Controls are chosen through **risk analysis**: what data does the app handle, and what happens if it leaks or is manipulated?

### Step 1 – Decide the profile

| Profile | Typical apps | Signals |
|---|---|---|
| **L1 – Basic** | Course projects, demos, offline apps, habit/to-do trackers with local data only, games without a real economy | No real money, no sensitive personal data, no shared user data |
| **L2 – Standard** | Apps with user accounts and a backend, social/community features, marketplaces without in-app payments, apps with location or photos | Personal data, user-to-user data, accounts that can be taken over |
| **L3 – High** | Payments, wallets, crypto, banking, health data, identity documents, enterprise/internal data | Real money, regulated data (KVKK special categories), high fraud value |

Write the chosen profile in `project.md` / `CLAUDE.md`, for example: `Security risk profile: L2 – Standard`.

### Step 2 – Apply controls by profile

✅ = required · ➕ = recommended · ➖ = not needed (optional)

| Control | L1 | L2 | L3 |
|---|---|---|---|
| No hard-coded secrets / backend proxy for secret keys | ✅ | ✅ | ✅ |
| Server-side auth & authorization / strict Firebase rules | ✅* | ✅ | ✅ |
| Input validation (client + server) | ✅ | ✅ | ✅ |
| HTTPS only, cleartext blocked | ✅ | ✅ | ✅ |
| No sensitive data in logs, no `print()` | ✅ | ✅ | ✅ |
| `flutter_secure_storage` for tokens | ✅* | ✅ | ✅ |
| Release obfuscation (`--obfuscate`) + R8 | ➕ | ✅ | ✅ |
| `allowBackup=false` / backup exclusion rules | ➖ | ✅ | ✅ |
| Rate limiting on the backend | ➖ | ✅ | ✅ |
| Transaction verification on the server (section D) | ➖ | ✅ | ✅ |
| Firebase App Check | ➖ | ➕ | ✅ |
| Encrypted local database | ➖ | ➕ | ✅ |
| Biometric unlock (`local_auth`) | ➖ | ➕ | ✅ |
| Certificate pinning (with backup pins + rotation plan) | ➖ | ➕ | ✅ |
| RASP / root-jailbreak / anti-tampering | ➖ | ➕ | ✅ |
| Screenshot & app switcher protection on sensitive screens | ➖ | ➕ | ✅ |
| Auto-logout after background timeout | ➖ | ➕ | ✅ |
| Dynamic testing (MobSF, MITM, Frida) before release | ➖ | ➕ | ✅ |

\* Only if the app has accounts or a backend. A fully offline L1 app has no server layer.

### Step 3 – Reassess when the app changes
Raise the profile when a feature adds payments, health data, identity data, or access to other users' data. When the profile goes up, update `project.md` and apply the missing controls.

> **For the agent:** Do not add L3 controls to an L1 project unprompted. They add complexity and can break the app (for example, expired certificate pins). Never skip controls marked ✅ for the project's profile.

---

## D. Server-Side Requirements (Backend / Cloud Functions)

When the agent writes backend code (ASP.NET Core, Node, Cloud Functions) or Firebase rules, these apply:

### D.1 Authentication
- Verify the token on **every** request (JWT signature, expiry, issuer, audience; or `verifyIdToken` for Firebase).
- Take the user's identity **only from the verified token**, never from the request body or query.

### D.2 Authorization
- Check ownership/role for every resource access: "Does this user own this order?"
- Deny by default. Allow only what is explicitly permitted.
- Roles come from the server (database or custom claims), never from the client.
- Return `404` instead of `403` for resources owned by other users when revealing their existence is a risk (this prevents ID enumeration).

### D.3 Rate limiting & abuse protection
- Rate limit login, register, password reset, OTP, and any expensive or proxied endpoint (per IP **and** per user).
- Lock or slow down accounts after repeated failed logins.
- Limit request body size and pagination size (`limit` ≤ a fixed max).

### D.4 Input validation
- Validate type, length, format, and range of every field on the server, even if the client already validated it.
- Reject unknown fields (allow-list). Do not bind request JSON directly to database models (mass assignment).
- Use parameterized queries / ORM. Never build SQL from strings.

### D.5 Transaction verification (işlem doğrulama)
For any operation with value (money, points, stock, rewards, votes):
- **Recompute on the server:** prices, totals, discounts, and scores come from server data, not from the client.
- **Check state transitions:** for example, an order can only go `pending → paid → shipped`. Reject illegal jumps.
- **Idempotency:** payment and order endpoints accept an `Idempotency-Key` header, so retries do not create duplicate charges.
- **Atomicity:** balance and stock changes use database transactions to prevent race conditions (for example, double spending by sending two requests at the same time).
- **Re-authentication for critical actions:** changing email/password, deleting the account, or large payments require a recent login or biometric step-up, verified by the server.
- **Audit log:** record who did what and when for critical operations (without logging secrets or PII).

### D.6 Errors
- Return generic error messages to clients. Log details on the server only.
- Never return stack traces, SQL errors, or internal paths in API responses.

---

## 0. Non-Negotiable Rules

> These apply to **every** risk profile. Controls that depend on the profile are marked in section C.

### MUST NOT
1. Hard-code secrets (API keys, tokens, passwords, private keys, client secrets) in `.dart`, `.kt`, `.swift`, `.xml`, `.plist`, or `.json` files that ship with the app.
2. Store tokens, passwords, keys, or personal data (PII) in `SharedPreferences`, `NSUserDefaults`, plain files, or unencrypted databases.
3. Use `http://` URLs, or accept invalid or self-signed certificates (`badCertificateCallback = (_, __, ___) => true`).
4. Log tokens, passwords, PII, full request/response bodies, or backend internals in release builds.
5. Use `print()` directly. Always use the project logger (section 9).
6. Use MD5, SHA-1, DES, 3DES, RC4, AES-ECB, hard-coded keys/IVs, or a self-written crypto algorithm.
7. Make authorization decisions only on the client (for example, `if (user.isAdmin) showAdminPanel()` with no server-side check).
8. Leave Firebase rules open (`allow read, write: if true;`), even "temporarily".
9. Ship debug-only features, test endpoints, mock logins, or hidden admin screens in release builds.
10. Request permissions the feature does not need, or request all permissions at startup.
11. Add a dependency without checking that it is maintained, popular, and from a trusted publisher.

### MUST
1. Keep secrets on the backend. The app talks to our own backend, and the backend talks to third-party APIs (backend proxy pattern).
2. Store sensitive data only through `SecureStorageService` (section 3).
3. Use the shared `ApiClient` for all network calls (section 4). Certificate pinning is enabled according to the risk profile (section C).
4. Validate all external input: user input, deep links, push payloads, and API responses.
5. Put every critical check (auth, permissions, prices, scores, balances) on the server (sections A and D).
6. Apply the controls marked ✅ for the project's risk profile (section C).
7. Clear sensitive data on logout and when the session expires.

---

## 1. Project Security Structure

Put security-related code in these locations. Do not scatter it across features.

```
lib/
  core/
    config/
      env.dart                  # compile-time config (no secrets)
    security/
      secure_storage_service.dart
      encryption_service.dart
      rasp_service.dart
      screen_protection.dart
      input_validators.dart
    network/
      api_client.dart           # Dio + pinning + interceptors
      auth_interceptor.dart
      certificate_pins.dart
    logging/
      app_logger.dart
config/
  dev.json                      # gitignored
  prod.json                     # gitignored
  example.json                  # committed, placeholder values only
```

`.gitignore` must contain:

```gitignore
config/*.json
!config/example.json
.env
*.env
*.keystore
*.jks
key.properties
android/app/google-services.json      # if the repo is public
ios/Runner/GoogleService-Info.plist   # if the repo is public
build/symbols/
```

---

## 2. Secrets & Configuration (OWASP M1 – Improper Credential Usage)

### 2.1 What may be in the app

| Type | Allowed in app? | How |
|---|---|---|
| Backend base URL | ✅ | `--dart-define-from-file` |
| Feature flags, environment name | ✅ | `--dart-define-from-file` |
| Firebase config (`google-services.json`) | ✅ (it is a public identifier) | Restrict with App Check + rules |
| Google Maps key | ✅ only if restricted | Restrict by package name + SHA-1 / bundle ID in Google Cloud |
| Third-party secret keys (OpenAI, Stripe secret, SMTP, DB passwords) | ❌ **NEVER** | Backend proxy only |
| Signing keys (`.jks`, `key.properties`) | ❌ | CI secrets only |

> ⚠️ `--dart-define` values are **compiled into the binary** and can be extracted. They keep config out of git, but they **do not protect secrets**. Never put a real secret there.

### 2.2 Compile-time config pattern

`config/example.json`:

```json
{
  "API_BASE_URL": "https://api.example.com",
  "ENV": "dev"
}
```

`lib/core/config/env.dart`:

```dart
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static bool get isProd => env == 'prod';

  static void validate() {
    if (apiBaseUrl.isEmpty || !apiBaseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL is missing or not HTTPS');
    }
  }
}
```

Run and build:

```bash
flutter run --dart-define-from-file=config/dev.json
flutter build apk --release --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols
```

### 2.3 Backend proxy pattern

```
❌ App ──(OpenAI key inside app)──▶ OpenAI
✅ App ──(user's auth token)──▶ Our backend ──(secret key on server)──▶ OpenAI
```

The backend must also enforce **rate limiting** and **per-user quotas** on proxied endpoints.

### 2.4 CI/CD

Signing keys and production config come from **GitHub Actions Secrets**. They are written to files only inside the CI job:

```yaml
- name: Create prod config
  run: echo '${{ secrets.PROD_CONFIG_JSON }}' > config/prod.json
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload.jks
```

---

## 3. Secure Local Storage (OWASP M9 – Insecure Data Storage)

### 3.1 Decision table

| Data | Storage |
|---|---|
| Access / refresh tokens, passwords, API session IDs, encryption keys | `flutter_secure_storage` |
| Sensitive structured data (health, finance, private messages, PII lists) | Encrypted Hive box (key kept in secure storage) |
| Non-sensitive settings (theme, language, onboarding seen) | `SharedPreferences` ✅ |
| Temporary sensitive files | App-private directory; delete after use |

### 3.2 `SecureStorageService`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _kAccessToken, value: access);
    await _storage.write(key: _kRefreshToken, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);

  /// Call on logout, account deletion, and session expiry.
  Future<void> clearAll() => _storage.deleteAll();
}
```

- `*_this_device` accessibility on iOS keeps secrets out of iCloud/iTunes backups.
- On iOS, Keychain items survive app uninstall. On the first launch after install, check a `SharedPreferences` flag and call `clearAll()` if the flag is missing.

### 3.3 Encrypted Hive box

```dart
import 'dart:convert';
import 'package:hive/hive.dart';

Future<Box<T>> openEncryptedBox<T>(String name) async {
  const keyName = 'hive_encryption_key';
  var encoded = await SecureStorageService.instance.read(keyName);
  if (encoded == null) {
    final key = Hive.generateSecureKey(); // 256-bit
    encoded = base64UrlEncode(key);
    await SecureStorageService.instance.write(keyName, encoded);
  }
  return Hive.openBox<T>(
    name,
    encryptionCipher: HiveAesCipher(base64Url.decode(encoded)),
  );
}
```

> A plain `Hive.openBox()` is **not** encrypted. Never use it for sensitive data.

### 3.4 In-memory and cache hygiene

- Do not keep sensitive data in global singletons or static variables longer than needed.
- On logout:

```dart
Future<void> logout() async {
  await apiClient.logoutOnServer();          // invalidate the session server-side
  await SecureStorageService.instance.clearAll();
  await Hive.deleteBoxFromDisk('user_data');
  imageCache.clear();
  imageCache.clearLiveImages();
  // reset state management (Bloc/Riverpod) so user data is not kept in memory
}
```

- When the app goes to the background on sensitive screens, clear sensitive fields such as OTP or card number controllers (see section 10.3).
- Disable autocorrect, suggestions, and copy for sensitive inputs:

```dart
TextField(
  obscureText: true,
  autocorrect: false,
  enableSuggestions: false,
  enableInteractiveSelection: false,
  keyboardType: TextInputType.visiblePassword,
)
```

---

## 4. Network Security (OWASP M5 – Insecure Communication)

### 4.1 Rules
- HTTPS only. `Env.validate()` rejects non-HTTPS base URLs.
- All requests go through `ApiClient`. Never create `Dio()` or call `http.get()` directly in features.
- Certificate pinning: **required for L3**, recommended for L2, not needed for L1 (section C). When it is enabled, always keep a backup pin and a rotation plan.
- Set timeouts on every request.

### 4.2 `ApiClient` with certificate pinning (Dio)

`lib/core/network/certificate_pins.dart`:

```dart
/// SHA-256 fingerprints of the server certificate (DER).
/// Keep at least TWO pins: the current one and the backup/next one.
/// Rotate BEFORE the certificate expires, or the app stops working.
const kAllowedCertSha256 = <String>{
  'aa11bb22...current',
  'cc33dd44...backup',
};
```

`lib/core/network/api_client.dart`:

```dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        )) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (_, __, ___) => false, // never accept invalid certs
      validateCertificate: (cert, host, port) {
        if (!Env.isProd) return true; // pin only in prod (use debug proxy in dev)
        if (cert == null) return false;
        final fingerprint = sha256.convert(cert.der).toString();
        return kAllowedCertSha256.contains(fingerprint);
      },
    );
    dio.interceptors.add(AuthInterceptor(dio));
    if (!Env.isProd) {
      dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
    }
  }

  final Dio dio;
}
```

Get the fingerprint:

```bash
openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null 2>/dev/null \
  | openssl x509 -outform DER | openssl dgst -sha256
```

Alternatives: the `http_certificate_pinning` or `ssl_pinning_plugin` packages. Use only **one** pinning approach across the project.

### 4.3 Android native pinning and cleartext block

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set expiration="2027-12-31">
            <pin digest="SHA-256">BASE64_SPKI_PIN_CURRENT=</pin>
            <pin digest="SHA-256">BASE64_SPKI_PIN_BACKUP=</pin>
        </pin-set>
    </domain-config>
</network-security-config>
```

> Dart's `HttpClient` does not use the Android network stack, so this file **does not pin Dart traffic**. It protects native/WebView traffic and blocks cleartext. Dart traffic is pinned in `ApiClient`.

### 4.4 iOS App Transport Security

`ios/Runner/Info.plist` must **not** contain `NSAllowsArbitraryLoads = true`. If an exception is unavoidable, scope it to a single domain and document the reason.

### 4.5 Auth interceptor (token handling)

```dart
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._dio);
  final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.instance.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final retry = await _dio.fetch(err.requestOptions
          ..headers['Authorization'] = 'Bearer ${await SecureStorageService.instance.accessToken}');
        return handler.resolve(retry);
      }
      await SecureStorageService.instance.clearAll();
      // navigate to login via the router / auth state
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    // Call the refresh endpoint with the refresh token and save the new tokens.
    // Use a separate Dio instance without this interceptor to avoid loops.
    return false;
  }
}
```

---

## 5. Authentication & Authorization (OWASP M3)

### 5.1 Rules
- The **server** decides who can do what. The client only hides UI elements.
- Access tokens are short-lived (≈15 minutes). Refresh tokens are rotated and revocable.
- Logout invalidates the session **on the server** and clears local storage.
- Password rules and brute-force protection (rate limit, lockout) are enforced on the server.
- Never send passwords in query strings. Use the request body over HTTPS.
- Login error messages are generic ("Invalid email or password"). They never reveal whether an email exists.

### 5.2 Biometrics (`local_auth`)

Biometrics only **unlock locally stored credentials**. They do not replace login.

```dart
import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

Future<bool> unlockWithBiometrics() async {
  final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  if (!canCheck) return false;
  try {
    return await _auth.authenticate(
      localizedReason: 'Verify your identity to continue',
      options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
    );
  } catch (_) {
    return false;
  }
}
```

- After a successful biometric check, read the refresh token from secure storage and refresh the session with the server.
- If biometrics fail several times, fall back to full login.
- Android: `MainActivity` must extend `FlutterFragmentActivity`.
- iOS: add `NSFaceIDUsageDescription` to `Info.plist`.

### 5.3 Firebase Security Rules

Firestore, default deny, owner-only access:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }

    match /users/{userId} {
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.keys().hasOnly(['name', 'email', 'createdAt'])
                    && request.resource.data.name is string
                    && request.resource.data.name.size() <= 100;
    }

    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null
                    && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

Storage:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

- Roles (admin, moderator) are stored in **custom claims** set by the backend or Cloud Functions, never in a client-writable document.
- Enable **Firebase App Check** (Play Integrity / App Attest).
- Test rules with the Firebase Emulator before every deploy.

---

## 6. Input & Output Validation (OWASP M4)

### 6.1 Validators (`lib/core/security/input_validators.dart`)

```dart
abstract final class InputValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (value.length > 254 || !_email.hasMatch(value)) return 'Invalid email';
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.length < 8) return 'At least 8 characters';
    if (value.length > 128) return 'Too long';
    return null;
  }

  static String? text(String? v, {int max = 500, bool required = true}) {
    final value = v?.trim() ?? '';
    if (required && value.isEmpty) return 'Required';
    if (value.length > max) return 'Max $max characters';
    return null;
  }
}
```

- Always enforce length limits (`maxLength` on `TextField` plus server-side checks).
- Validation is repeated on the **server**. Client validation is only for user experience.

### 6.2 Deep links / App Links
- Use verified **Android App Links** (`assetlinks.json`) and **iOS Universal Links** instead of custom schemes where possible.
- Parse incoming URIs with an allow-list of paths and parameters:

```dart
bool isAllowedDeepLink(Uri uri) {
  const allowedHosts = {'app.example.com'};
  const allowedPaths = {'/product', '/reset-password'};
  return uri.scheme == 'https' &&
      allowedHosts.contains(uri.host) &&
      allowedPaths.contains(uri.path);
}
```

- Never perform sensitive actions (payment, delete, change email) directly from a deep link without user confirmation and a valid session.

### 6.3 WebView
- Avoid WebView for sensitive flows.
- If you use it: `JavaScriptMode.disabled` unless required, load only allow-listed HTTPS URLs, block navigation to other domains in `NavigationDelegate`, and never expose JavaScript channels that can trigger sensitive actions.

### 6.4 API responses
- Parse JSON into typed models (`fromJson`) with null and type checks. Never trust the response structure blindly.
- Do not render server-provided HTML or Markdown without sanitization.

---

## 7. Platform Configuration (OWASP M8 – Security Misconfiguration)

### 7.1 `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Only the permissions actually needed. -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="@string/app_name"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <!-- launcher intent-filter -->
        </activity>

        <!-- Every other activity/service/receiver/provider:
             android:exported="false" unless it truly must be public. -->
    </application>
</manifest>
```

`res/xml/data_extraction_rules.xml` (Android 12+):

```xml
<data-extraction-rules>
    <cloud-backup><exclude domain="root" /><exclude domain="sharedpref" /><exclude domain="database" /></cloud-backup>
    <device-transfer><exclude domain="root" /><exclude domain="sharedpref" /><exclude domain="database" /></device-transfer>
</data-extraction-rules>
```

- Never set `android:debuggable="true"` manually. Release builds are non-debuggable by default.
- Never add `android:exported="true"` to a `provider`.

### 7.2 iOS `Info.plist`
- No `NSAllowsArbitraryLoads`.
- Every permission has a clear, honest usage description (`NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, ...).
- Remove usage descriptions for permissions the app does not use. App Store review also checks this.

### 7.3 Build modes
- Debug-only code is wrapped in `if (kDebugMode)` or `assert`, so it is tree-shaken from release builds.
- Debug menus, mock data, and test login buttons must not exist in release builds. Use separate entry points (`main_dev.dart`, `main_prod.dart`) or flavors if needed.

---

## 8. Binary Protection & Reverse Engineering (OWASP M7)

### 8.1 Release build commands

```bash
# Android
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=config/prod.json

# iOS
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=config/prod.json
```

- Keep `build/symbols/` **private** (CI artifact or crash reporter upload). It is needed to de-obfuscate stack traces with `flutter symbolize`.
- Obfuscation renames Dart classes and functions. It **does not encrypt string literals**. This is one more reason to never put secrets in the code.

### 8.2 Android R8/ProGuard (`android/app/build.gradle.kts`)

```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

`android/app/proguard-rules.pro`:

```
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
# Add -keep rules for plugins that use reflection (check each plugin's README).
# Remove Android Log calls in release:
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
```

### 8.3 Verification
Before major releases, inspect the release binary:
- Run `strings libapp.so | grep -iE "key|secret|token|password|http://"`. The result should contain nothing sensitive.
- Use decompiler tools (IDA Pro, Hopper, Ghidra, `blutter` for Dart AOT) to confirm that business-critical logic and data cannot be easily recovered.

---

## 9. Logging (OWASP M6 – Privacy / Extraneous Functionality)

`lib/core/logging/app_logger.dart`:

```dart
import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void d(String message) {
    if (kDebugMode) debugPrint('[D] $message');
  }

  static void e(String message, [Object? error, StackTrace? st]) {
    if (kDebugMode) {
      debugPrint('[E] $message ${error ?? ''}');
    } else {
      // Send to crash reporting WITHOUT PII, tokens, or request bodies.
      // e.g. FirebaseCrashlytics.instance.recordError(error, st, reason: message);
    }
  }
}
```

In `main.dart`, silence `debugPrint` in release builds:

```dart
void main() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  Env.validate();
  runApp(const App());
}
```

Never log:
- Authorization headers, tokens, cookies, passwords, OTP codes
- Full names, emails, phone numbers, addresses, national ID numbers, location coordinates
- Full API request/response bodies
- Internal server paths, stack traces from the server, or database errors shown to the user

User-facing error messages are generic ("Something went wrong, please try again"). Details go to the logger in debug mode only.

---

## 10. Runtime Protection (RASP, Root/Jailbreak, Screen Security)

### 10.1 freeRASP (Talsec)

`lib/core/security/rasp_service.dart`:

```dart
import 'package:freerasp/freerasp.dart';

class RaspService {
  static Future<void> init() async {
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.example.app',
        signingCertHashes: ['BASE64_SHA256_OF_RELEASE_SIGNING_CERT'],
        supportedStores: const [],
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.example.app'],
        teamId: 'TEAM_ID',
      ),
      watcherMail: 'security@example.com',
      isProd: Env.isProd,
    );

    final callback = ThreatCallback(
      onAppIntegrity: () => _handle('app_integrity'),       // repackaged / re-signed
      onPrivilegedAccess: () => _handle('root_jailbreak'),
      onDebug: () => _handle('debugger'),
      onHooks: () => _handle('hooks'),                      // Frida, Xposed
      onSimulator: () => _handle('simulator'),
      onUnofficialStore: () => _handle('unofficial_store'),
      onDeviceBinding: () => _handle('device_binding'),
      onObfuscationIssues: () => _handle('not_obfuscated'),
    );

    Talsec.instance.attachListener(callback);
    await Talsec.instance.start(config);
  }

  static void _handle(String threat) {
    AppLogger.e('Security threat detected: $threat');
    // Policy (choose per app risk level):
    // - Low risk app: log + warn the user
    // - Sensitive app (finance/health): block sensitive features or close the session
  }
}
```

Call `await RaspService.init();` in `main()` before `runApp`, only in production.

Lighter alternative: `flutter_jailbreak_detection`:

```dart
final isJailbroken = await FlutterJailbreakDetection.jailbroken;
final isDevMode = await FlutterJailbreakDetection.developerMode; // Android only
```

> Root/jailbreak detection can be bypassed. It is **defense in depth**, not a replacement for server-side checks.

### 10.2 Block screenshots and the app switcher preview

Use the `screen_protector` or `secure_application` package, or the native code below. Apply it **only on sensitive screens** (payment, wallet, personal/health data, OTP).

Android (`MainActivity.kt`), for the whole app:

```kotlin
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
```

For specific screens only, toggle the flag through a `MethodChannel` (or `screen_protector`) in `initState` / `dispose` of the sensitive page.

iOS (`AppDelegate`), which hides content in the app switcher:

```swift
override func applicationWillResignActive(_ application: UIApplication) {
    window?.isHidden = true
}

override func applicationDidBecomeActive(_ application: UIApplication) {
    window?.isHidden = false
}
```

### 10.3 Lifecycle handling for sensitive screens

```dart
class _PaymentPageState extends State<PaymentPage> {
  late final AppLifecycleListener _listener;
  final _cardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () => _cardController.clear(), // clear sensitive input in background
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    _cardController.dispose();
    super.dispose();
  }
}
```

Auto-logout: when the app returns from the background after a set timeout (for example, 5 minutes for sensitive apps), require biometrics or login again.

---

## 11. Permissions & Privacy (OWASP M6 – Inadequate Privacy Controls)

- Request a permission **at the moment the feature needs it**, with a short explanation screen first.
- Handle every state: granted, denied, permanently denied (open settings), and limited (iOS photos).

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureCameraPermission(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied) {
    await openAppSettings();
    return false;
  }
  status = await Permission.camera.request();
  return status.isGranted;
}
```

- Prefer the least-privileged option: `locationWhenInUse` over `locationAlways`, the photo picker over full gallery access, approximate location when precise location is not required.
- Collect only the data the feature needs (data minimization). Strip EXIF/location metadata from uploaded photos when it is not needed.
- Get and store explicit consent (KVKK/GDPR) for analytics, marketing, and the processing of personal data. Analytics must not start before consent.
- Provide account deletion and data export flows (both stores require account deletion for apps with sign-up).

---

## 12. Cryptography (OWASP M10 – Insufficient Cryptography)

### 12.1 Allowed algorithms

| Purpose | Use | Never use |
|---|---|---|
| Symmetric encryption | **AES-256-GCM** | AES-ECB, DES, 3DES, RC4 |
| Hashing (integrity) | **SHA-256 / SHA-512** | MD5, SHA-1 |
| Password hashing | **On the server**: Argon2id / bcrypt / scrypt | Plain SHA-256 of passwords, hashing on the client |
| MAC | **HMAC-SHA256** | Custom MAC schemes |
| Asymmetric | **RSA ≥ 2048 (OAEP), ECDSA/ECDH P-256, Ed25519** | RSA < 2048, PKCS#1 v1.5 for new code |
| Randomness | `Random.secure()` | `Random()` for any security purpose |

### 12.2 `EncryptionService` (AES-GCM with the `cryptography` package)

```dart
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  final _algorithm = AesGcm.with256bits();

  Future<SecretKey> _loadOrCreateKey() async {
    const keyName = 'aes_key';
    final stored = await SecureStorageService.instance.read(keyName);
    if (stored != null) return SecretKey(base64Decode(stored));
    final key = await _algorithm.newSecretKey();
    await SecureStorageService.instance.write(keyName, base64Encode(await key.extractBytes()));
    return key;
  }

  /// Returns base64(nonce + ciphertext + mac). A new random nonce is used every time.
  Future<String> encrypt(String plainText) async {
    final key = await _loadOrCreateKey();
    final box = await _algorithm.encrypt(utf8.encode(plainText), secretKey: key);
    return base64Encode(box.concatenation());
  }

  Future<String> decrypt(String encoded) async {
    final key = await _loadOrCreateKey();
    final box = SecretBox.fromConcatenation(
      base64Decode(encoded),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return utf8.decode(await _algorithm.decrypt(box, secretKey: key));
  }
}
```

Rules:
- Never hard-code keys, IVs, nonces, or salts.
- Never reuse a nonce with the same key.
- Always use authenticated encryption (GCM). Handle `SecretBoxAuthenticationError` as tampering.
- Do not invent your own crypto. Use `cryptography`, `crypto` (hashing/HMAC only), or `encrypt` with GCM mode.

---

## 13. Dependencies & Supply Chain (OWASP M2)

Before adding a package, check:
- [ ] Verified publisher, or a well-known maintainer
- [ ] Good pub.dev score and popularity; updated in the last ~12 months
- [ ] Open issues do not mention unresolved security problems
- [ ] Requested native permissions match what the package claims to do
- [ ] The license is compatible

Ongoing:
- `pubspec.lock` is committed.
- Run `flutter pub outdated` regularly. Update, test, and review changelogs for security fixes.
- Enable Dependabot in `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "gradle"
    directory: "/android"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

- Pin GitHub Actions to commit SHAs or major tags from trusted publishers.
- Enable GitHub **secret scanning** and **push protection**.

---

## 14. Static & Dynamic Analysis

### 14.1 Lints (`analysis_options.yaml`)

```yaml
include: package:very_good_analysis/analysis_options.yaml   # or package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    avoid_print: error

linter:
  rules:
    avoid_print: true
    avoid_dynamic_calls: true
    cancel_subscriptions: true
    close_sinks: true
```

### 14.2 CI security job (example)

```yaml
- run: flutter analyze --fatal-infos
- run: flutter test
- name: Secret scan
  uses: gitleaks/gitleaks-action@v2
- name: Check for http:// URLs
  run: "! grep -rn \"http://\" lib/ --include=*.dart | grep -v localhost"
- name: Check for print()
  run: "! grep -rn \"print(\" lib/ --include=*.dart | grep -v debugPrint"
```

### 14.3 Dynamic testing (before major releases)
- **MobSF** static and dynamic scan of the release APK/IPA.
- MITM test with Burp Suite / mitmproxy. Requests **must fail** in production builds (this confirms pinning works).
- Inspect app storage on a rooted emulator (`/data/data/<package>/`). There must be no plain-text tokens or PII.
- Check with Frida/Objection that RASP detects hooking.

---

## 15. Pre-Merge Checklist

The agent must go through this list for every change it touches:

**Principle check**
- [ ] For every new client-side check: "If an attacker removes this from the app, is the system still safe?" If not, a server-side check was added
- [ ] Controls match the project's risk profile (section C): nothing ✅ skipped, nothing unnecessary added

**Server**
- [ ] User identity comes from the verified token; ownership/role checked per request
- [ ] Prices, totals, scores, and balances are computed/verified on the server
- [ ] Rate limits on auth and expensive endpoints (L2+)

**Secrets & config**
- [ ] No secrets in code, config, or commits; new config keys added to `config/example.json`
- [ ] New third-party secret APIs go through the backend proxy

**Storage**
- [ ] Sensitive data uses `SecureStorageService` or an encrypted Hive box
- [ ] Logout clears all new sensitive data

**Network**
- [ ] All requests use `ApiClient`; HTTPS only; timeouts set
- [ ] Pinning still active in prod; pins not expired

**Auth**
- [ ] New endpoints and Firebase collections have server-side auth checks and rules
- [ ] No client-only authorization decisions

**Input/Output**
- [ ] User input, deep links, and API responses are validated
- [ ] Error messages shown to users are generic

**Logging & privacy**
- [ ] No `print()`; no tokens or PII in logs
- [ ] New permissions are justified, requested in context, and described in Info.plist

**Platform & build**
- [ ] No new exported Android components without a reason
- [ ] No ATS exceptions or cleartext added
- [ ] Release build works with `--obfuscate --split-debug-info` and R8 enabled
- [ ] Sensitive screens use screen protection

**Dependencies**
- [ ] New packages meet the section 13 criteria
- [ ] `flutter analyze` passes with no warnings

---

## 16. Vulnerability Reporting

The public vulnerability disclosure policy (supported versions, how to report, response times, scope) is in the repository's `SECURITY.md`. If you find a security issue while working on the code, **do not describe it in public commit messages, PR titles, or issues**. Report it to the maintainer privately.
