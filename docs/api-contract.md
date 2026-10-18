# BloomWell API Contract 🌸

The canonical REST API contract for BloomWell backend services.

---

## Global Conventions

- **Base URL Prefix:** All versioned endpoints live under `/v1/...`.
- **Health Probes:** Unversioned root probe at `GET /health`.
- **Request Tracing:** Every request receives or preserves an `X-Request-ID` correlation UUID in headers and error responses.
- **Content Type:** `application/json` for all request and response bodies.
- **Authentication:** Bearer token authorization header: `Authorization: Bearer <access_token>`.
- **Error Format:** Consistent Problem Details JSON format across all status codes:
  ```json
  {
    "code": "HTTP_401",
    "message": "Invalid email or password.",
    "details": null,
    "request_id": "87edcd07-b027-4cc4-8d65-985165a2782e"
  }
  ```

---

## Token Lifetimes & Security Design

| Token | Lifetime | Format | Storage Rules |
|---|---|---|---|
| **Access Token** | 15 minutes (`900s`) | Signed JWT (HS256) | Memory only. Claims: `sub` (user UUID), `role`, `iat`, `exp`, `jti`. |
| **Refresh Token** | 7 days | Cryptographically secure opaque string | Client: encrypted secure storage (`flutter_secure_storage` on mobile, memory-only on web). Server: stored strictly as SHA-256 hash. |

### Token Rotation & Family Revocation
- Every call to `POST /v1/auth/refresh` rotates the token: the presented token is invalidated (`revoked_at` set, `replaced_by` points to the new token), and a new token in the same `family_id` is issued.
- **Reuse Detection:** If an already-rotated or revoked token is presented again (indicating token theft or replay), the backend **immediately revokes the entire token family**. All subsequent refresh attempts with any token in that family fail with HTTP 401.

---

## Endpoints

### 1. Health Probe
#### `GET /health`
Verifies backend service and database connectivity without leaking internal database strings or credentials.

- **Success Response (200 OK):**
  ```json
  {
    "status": "healthy",
    "database": "connected"
  }
  ```
- **Error Response (503 Service Unavailable):**
  ```json
  {
    "code": "HTTP_503",
    "message": "Database connectivity unavailable.",
    "details": null,
    "request_id": "076af073-208e-4abe-83f1-0b7d4f4dfa26"
  }
  ```

---

### 2. User Registration
#### `POST /v1/auth/register`
Creates a student user account and initializes default `user_preferences` (`language="en"`, `timezone="UTC"`, `reminders_enabled=true`, `discreet_notifications=true`, AI flags false, consent timestamps null).

- **Rate Limit:** 10 requests / minute per client IP.
- **Request Body:**
  ```json
  {
    "email": "student@college.edu",
    "password": "SecurePassword123!",
    "display_name": "Aarohi",
    "timezone": "Asia/Kolkata"
  }
  ```
- **Validation Rules:**
  - `email`: valid format, automatically trimmed and lowercased.
  - `password`: minimum 10 characters, checked against common password denylist.
  - `timezone`: valid IANA timezone string (defaults to `"UTC"` if omitted).
- **Success Response (201 Created):**
  ```json
  {
    "tokens": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "k9s_7LmQ2P8_random_refresh_token_string",
      "token_type": "bearer",
      "expires_in": 900
    },
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "display_name": "Aarohi",
      "role": "student",
      "created_at": "2026-10-18T10:00:00Z",
      "language": "en",
      "timezone": "Asia/Kolkata"
    }
  }
  ```
- **Error Responses:**
  - `409 Conflict`: `{"code": "HTTP_409", "message": "An account with this email address already exists."}`
  - `422 Unprocessable Entity`: Validation failure (short password, weak password, invalid timezone).

> **Security Note on Account-Enumeration Trade-off for 409 on Register:**  
> Returning `409 Conflict` on duplicate registration explicitly signals that an account already exists. This deliberate trade-off prioritizes usability for students (so they know to log in or reset their password rather than wondering why an email didn't arrive). The risk of enumeration is mitigated by strict per-IP rate limiting (10 attempts/min). Conversely, login strictly disallows enumeration.

---

### 3. User Login
#### `POST /v1/auth/login`
Authenticates user credentials and issues a fresh access/refresh token pair.

- **Rate Limit:** 15 requests / minute per client IP; 5 attempts / minute per normalized email.
- **Request Body:**
  ```json
  {
    "email": "student@college.edu",
    "password": "SecurePassword123!"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "m4k_9LmQ2P8_new_opaque_refresh_token",
    "token_type": "bearer",
    "expires_in": 900
  }
  ```
- **Error Response (401 Unauthorized):**
  ```json
  {
    "code": "HTTP_401",
    "message": "Invalid email or password.",
    "details": null,
    "request_id": "..."
  }
  ```
  *(A dummy Argon2id hash verification executes when the email is not found to guarantee identical execution timing and prevent timing-based email enumeration).*

---

### 4. Refresh Token Rotation
#### `POST /v1/auth/refresh`
Presents an opaque refresh token, invalidates it, and issues a new access and refresh token pair.

- **Rate Limit:** 20 requests / minute per client IP.
- **Request Body:**
  ```json
  {
    "refresh_token": "m4k_9LmQ2P8_new_opaque_refresh_token"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "q8x_1NpB5T2_rotated_refresh_token",
    "token_type": "bearer",
    "expires_in": 900
  }
  ```
- **Error Responses (401 Unauthorized):**
  - Expired token: `{"code": "HTTP_401", "message": "Refresh token has expired."}`
  - Reused / revoked token: `{"code": "HTTP_401", "message": "Refresh token reuse detected. Token family has been revoked."}`

---

### 5. Logout
#### `POST /v1/auth/logout`
Revokes the token family associated with the presented refresh token. Idempotent.

- **Request Body:**
  ```json
  {
    "refresh_token": "q8x_1NpB5T2_rotated_refresh_token"
  }
  ```
- **Success Response:** `204 No Content` (Empty response body).

---

### 6. Get Current Profile
#### `GET /v1/me`
Fetches the authenticated user's profile and preferences.

- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "display_name": "Aarohi",
    "role": "student",
    "created_at": "2026-10-18T10:00:00Z",
    "language": "en",
    "timezone": "Asia/Kolkata"
  }
  ```
- **Error Response (401 Unauthorized):**
  - Missing, invalid, expired, or tampered access token.

---

### 7. Update User Preferences
#### `PATCH /v1/me/preferences`
Updates non-consent user preferences.

- **Headers:** `Authorization: Bearer <access_token>`
- **Whitelisted Fields Only:**
  - `timezone` (IANA valid string)
  - `language` (`"en"`, `"hi"`, or `"mr"`)
  - `reminders_enabled` (`boolean`)
  - `discreet_notifications` (`boolean`)
- **Forbidden / Rejected Fields:**
  - `ai_recommendations_enabled`, `journal_ai_consent_at`, `planner_cycle_consent_at`, or any unknown property triggers `422 Unprocessable Entity`.
- **Request Body:**
  ```json
  {
    "language": "hi",
    "discreet_notifications": true
  }
  ```
- **Success Response (200 OK):**
  Returns the updated `UserProfileResponse`.
