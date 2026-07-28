# MoonJoin World — OTP / Verification Flow Architecture

> **Chapter B of the [MoonJoin World Enterprise Architecture](MOONJOIN_WORLD_ENTERPRISE_ARCHITECTURE.md).** OTP is a Platform Services Layer service (PSL, §2) inheriting the Universal Provider Contract (§3); this chapter documents the current flow + future design and the root-cause diagnosis.
>
> **Status:** Permanent architecture document. **Documentation only — no implementation.** Every "CURRENT" statement is traced from the actual codebase (Flutter frontend + observed 6amMart backend responses). Every "MOONJOIN WORLD" statement is clearly-separated **future** design and is **not** built. The current 6amMart backend is a temporary compatibility layer.

---

## 0. Verified facts (observed, not guessed)
- Firebase Phone OTP **works when enabled** (reCAPTCHA + native flow reached).
- Backend SMS gateway is currently **ON**; Firebase OTP **OFF**; active gateway **2Factor**.
- **Physical iPhone:** reaches the migrated OTP Verification screen correctly (no error).
- **iOS Simulator:** shows **"Internet error has occurred."**
- **Physical iPhone:** verification screen opens but **no SMS received**.
- Live log evidence: `POST /api/v1/auth/login` body `{phone:+2348153126144, login_type:otp, guest_id:6824}` → `[200] {token:null, is_phone_verified:0, is_email_verified:1, is_personal_info:1, is_exist_user:null, login_type:otp}`.

---

## 1. Frontend Flow — CURRENT (exists)
- **Entry:** `SignInView` (OTP method chosen by config) → `_otpLogin()` calls `AuthController.otpLogin(phone, loginType:'otp', otp:'', verified:'')`.
- **On success (`_processOtpSuccessSetup`):**
  - `if (!isPhoneVerified)`:
    - `if (firebaseOtpVerification)` → `AuthController.firebaseVerifyPhoneNumber(...)` (Firebase native + reCAPTCHA, then navigates to `VerificationScreen` with `firebaseSession`).
    - `else` (backend gateway path) → navigate to **`VerificationScreen`** (Phase 9C-4 migrated: `AuthScaffold + AuthHero + AuthCard + AuthOtpField + AuthPrimaryButton`).
  - `else` → `LocationController.navigateToLocationScreen('sign-in')` (already verified).
- **Verification screen:** 6-digit `AuthOtpField`, 60s resend timer (`_startTimer`), resend link, Verify button; branches by `firebaseSession` / `userModel` / `fromSignUp` / else (reset-token).
- **MoonJoin World:** frontend calls a **provider-agnostic** `otp/send` + `otp/verify`; the app never knows Firebase vs 2Factor vs Termii — the platform decides. UI stays identical.

## 2. API Request Flow — CURRENT (exists)
- **Send:** `POST /api/v1/auth/login` `{phone, login_type:"otp", guest_id}`, header `Authorization: Bearer null`. **The backend sends the SMS during this call** (frontend never contacts the gateway).
- **Verify:** `POST /api/v1/auth/verify-phone` (via `VerificationController.verifyPhone`, model `VerificationDataModel{phone,email,verificationType,otp,loginType,guestId}`).
- **Related:** `/api/v1/auth/forgot-password`, `/api/v1/auth/verify-token`, `/api/v1/auth/reset-password`, `/api/v1/auth/verify-email`, `/api/v1/auth/sign-up`.
- **Transport:** `ApiClient.postData()` → `http.post(...).timeout(timeoutInSeconds)`; JSON body strips null/empty fields.
- **MoonJoin World:** versioned, provider-agnostic endpoints `POST /communication/otp/send` → `{requestId,status}` and `POST /communication/otp/verify` → `{verified}`, returning a real **delivery status** (not a bare 200).

## 3. Backend OTP Flow — CURRENT (observed) + MoonJoin World
- **CURRENT (observed):** `/auth/login` with `login_type:otp` returns **200** with `is_phone_verified:0` and **no SMS-status field**. The backend dispatches the OTP via the configured gateway **synchronously and fire-and-forget** — success/failure of the gateway is **not reflected** in the response body.
- **MOONJOIN WORLD:** an **OTP orchestration service** — generate code, persist `{requestId, hashedCode, expiry, attempts}`, select provider via routing, enqueue send, and return `{requestId, status:QUEUED}`. Gateway outcome tracked and exposed.

## 4. Gateway Flow — CURRENT + MoonJoin World
- **CURRENT:** backend → **2Factor** SMS API. 2Factor is **India-centric** (DLT templates, `+91`). No frontend visibility of the gateway request/response.
- **MOONJOIN WORLD:** `SmsProvider` abstraction (Twilio/Nexmo/MSG91/AlphaNet/2Factor/Termii/Infobip/Africa's Talking/AWS SNS). **Country routing** (`+234 → Termii`), **priority/Primary-Secondary**, **failover**, **health**, **delivery receipts** — see `MOONJOIN_WORLD_COMMUNICATION_ARCHITECTURE.md`.

## 5. Verification Flow — CURRENT (exists)
- User enters 6 digits → Verify → branch:
  - **Firebase:** `verifyFirebaseOtp(phoneNumber, session, otp, token, ...)`.
  - **userModel present:** `ProfileController.updateUserInfo(userModel, token, fromButton:true)`.
  - **fromSignUp:** `verifyPhone(VerificationDataModel{...})`.
  - **else (reset):** `verifyToken(phone,email)` → success routes to `NewPassScreen` / reset-password route.
- On success → `_handleVerifyResponse` (existing-user sheet / NewUserSetup / location screen / back). On failure → shake animation + error text + snackbar.
- **MoonJoin World:** single `otp/verify {requestId, code}` → `{verified, next}`; server enforces attempts/expiry/lockout centrally.

## 6. Failure Flow — CURRENT (exists) + MoonJoin World
- **CURRENT:** `ApiClient.postData` wraps calls in `try/catch`; **any exception → `Response(statusCode:1, statusText:'connection_to_api_server_failed')`** = the **"Internet error"** message. The real exception `e` is **swallowed** (not logged/surfaced). HTTP error bodies (non-2xx) are parsed via `ErrorResponse` and shown as snackbars.
- **Gateway failure is invisible** to the app (backend returns 200 regardless).
- **MOONJOIN WORLD:** typed error taxonomy (`NETWORK`, `TIMEOUT`, `GATEWAY_REJECTED`, `NO_CREDIT`, `UNSUPPORTED_COUNTRY`, `RATE_LIMITED`, `INVALID_CODE`, `EXPIRED`), surfaced with actionable messages; real exception preserved in logs; gateway failure reflected to the client + auto-failover.

## 7. Logging Flow — CURRENT (exists) + MoonJoin World
- **CURRENT:** `kDebugMode` prints of API call/body/response in `ApiClient` (debug only). No structured OTP delivery log on the client; the caught exception is **not** logged.
- **MOONJOIN WORLD:** structured server log per OTP: `{requestId, channel, provider, country, senderId, template, status, latency, cost, errorCode, rawProviderResponse, retryCount, failoverChain, timestamps}`; OTP codes **never** logged; feeds analytics/health.

## 8. Retry Flow — CURRENT (exists) + MoonJoin World
- **CURRENT:** resend is **user-initiated** — `VerificationScreen` 60s countdown (`_startTimer`), then `_resendOtp()` re-calls `otpLogin`/`login`/`forgetPassword` (or `firebaseVerifyPhoneNumber` for Firebase). No automatic backend retry/failover.
- **MOONJOIN WORLD:** transient-error retry (exponential backoff + jitter, bounded) on the **same** provider, then **cross-provider failover**; permanent errors (invalid number, no credit, unsupported country) skip retry and failover/surface immediately; idempotent by `requestId`.

## 9. Admin Configuration Flow — CURRENT (exists) + MoonJoin World
- **CURRENT:** `configModel.centralizeLoginSetup.{otpLoginStatus, manualLoginStatus, socialLoginStatus, phoneVerificationStatus}` + `firebaseOtpVerification` + `isSmsActive`/`isMailActive` come from `/api/v1/config` (admin-controlled). The 6amMart admin "Login Setup / 3rd-party (SMS)" chooses Firebase vs a gateway (e.g. 2Factor). Frontend is **already provider-agnostic** for OTP method selection (`CentralizeLoginHelper`).
- **MOONJOIN WORLD:** Admin controls provider enable/disable, **priority per country**, routing table, sender IDs/templates, rate limits, timeouts, retry/circuit-breaker thresholds, and views delivery analytics/health — **no redeploy, no Flutter change**.

## 10. Future Improvements (MoonJoin World, not built)
1. Return **OTP delivery status + `requestId`** instead of a bare 200 (kills silent failures).
2. **Country-aware routing** (`+234 → Termii/Africa's Talking`; `+91 → 2Factor/MSG91`).
3. **Auto-failover** across gateways + circuit breakers.
4. **Delivery receipts / DLR webhooks** → accurate "sent/delivered/expired".
5. Central **attempts/expiry/lockout** + anti-abuse (rate limits, velocity checks).
6. **Structured logging + analytics + health dashboards** (delivery rate, cost, latency by provider/country).
7. **Surface real errors** instead of the generic "Internet error" (frontend `ApiClient` catch improvement — app-wide, deferred).
8. **Queue-based async send** for scale.

---

## PART 5 — OTP ROOT-CAUSE DIAGNOSIS (by layer, with confidence)

| Layer | Verdict | Confidence | Evidence |
|---|---|---|---|
| **Frontend** | ✅ **Not the cause.** The migrated screen opens correctly on the physical iPhone; `/auth/login` handled and navigation correct. | **High (95%)** | Physical device reaches the screen; `flutter analyze` clean; presentation-only migration; Firebase path still triggers (unbroken). |
| **Backend** | ⚠️ Returns **200 with no SMS-status** and **swallows the gateway result** — silent failure surface. | **High (90%)** | Live log: `[200] /auth/login` `{is_phone_verified:0}`, no delivery field. |
| **Gateway (2Factor)** | ❌ **Primary root cause of "no SMS."** 2Factor is India/DLT-centric; delivering OTP to **Nigeria `+234`** is typically unsupported/unrouted, and/or **no credit / unconfigured sender-template/API key**. | **Medium-High (75%)** — needs 2Factor dashboard/backend log to reach certainty (frontend can't see the gateway response). | 2Factor product scope (India/DLT); phone `+234`; SMS never arrives despite backend 200. |
| **Simulator** | ⚠️ **"Internet error" = simulator limitation**, masked by `ApiClient`'s generic swallowed-exception message. Not reproducible on the real device. | **High (85%)** | Device works; simulator throws; earlier Imunify360 bot-interstitial observed intercepting simulator requests; catch maps any exception → `connection_to_api_server_failed`. |
| **Configuration** | ⚠️ Wrong gateway for the destination country (2Factor for `+234`). | **Medium-High (75%)** | Same as gateway row. |

**Summary:** The **frontend is correct** (device reaches the migrated OTP screen). "No SMS" is a **backend + gateway configuration** issue — **2Factor is the wrong/unfunded gateway for Nigeria `+234`**, and the backend hides the gateway failure behind a 200. The simulator "Internet error" is a **simulator networking limitation** masked by a generic error string. **Definitive confirmation** of the gateway cause requires the 2Factor dashboard / backend send-log (outside the app). **Recommended fix:** route `+234` to **Termii** (or another Africa-capable gateway) and fund/configure it; no frontend change required.
