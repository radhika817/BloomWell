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

---

### 8. Mood Check-ins
#### `POST /v1/checkins`
Records a daily mood and wellness check-in.
- **Idempotency Rule:** `client_id` is unique per user. Initial creation returns `201 Created`; subsequent calls with an existing `client_id` for this user return `200 OK` with the existing check-in without creating duplicates.
- **Headers:** `Authorization: Bearer <access_token>`
- **Request Body:**
  ```json
  {
    "client_id": "c1f24d92-1b32-47c9-9524-738b5cf3c931",
    "local_date": "2026-10-18",
    "mood_score": 4,
    "stress_score": 2,
    "energy_score": 3,
    "sleep_quality_score": 4,
    "mood_label": "calm",
    "tags": ["studying", "walk"],
    "notes": "Feeling focused today."
  }
  ```
- **Validation Rules:**
  - `mood_score`, `stress_score`, `energy_score`: integer 1-5.
  - `sleep_quality_score`: nullable integer 1-5.
  - `mood_label`: nullable enum (`"happy"`, `"calm"`, `"okay"`, `"sad"`, `"stressed"`).
  - `tags`: nullable array of strings, max 5 items, max 24 chars each.
  - `notes`: nullable string, max 1000 characters.
  - `local_date`: date string `YYYY-MM-DD`. Must not exceed 1 day into the future relative to the user's stored timezone (`user_preferences.timezone`).
- **Success Response (201 Created or 200 OK):**
  ```json
  {
    "id": "7b36f73d-f2e1-4c7a-9db2-6dcfb940ad42",
    "client_id": "c1f24d92-1b32-47c9-9524-738b5cf3c931",
    "local_date": "2026-10-18",
    "mood_score": 4,
    "stress_score": 2,
    "energy_score": 3,
    "sleep_quality_score": 4,
    "mood_label": "calm",
    "tags": ["studying", "walk"],
    "notes": "Feeling focused today.",
    "created_at": "2026-10-18T10:30:00Z",
    "updated_at": "2026-10-18T10:30:00Z"
  }
  ```

#### `GET /v1/checkins`
Fetches cursor-paginated check-in records strictly owned by the caller.
- **Headers:** `Authorization: Bearer <access_token>`
- **Query Parameters:**
  - `limit`: integer, 1-100 (default: 20).
  - `cursor`: optional base64-encoded pagination cursor.
  - `from_date`: optional `YYYY-MM-DD` filter (inclusive).
  - `to_date`: optional `YYYY-MM-DD` filter (inclusive).
- **Success Response (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "7b36f73d-f2e1-4c7a-9db2-6dcfb940ad42",
        "client_id": "c1f24d92-1b32-47c9-9524-738b5cf3c931",
        "local_date": "2026-10-18",
        "mood_score": 4,
        "stress_score": 2,
        "energy_score": 3,
        "sleep_quality_score": 4,
        "mood_label": "calm",
        "tags": ["studying", "walk"],
        "notes": "Feeling focused today.",
        "created_at": "2026-10-18T10:30:00Z",
        "updated_at": "2026-10-18T10:30:00Z"
      }
    ],
    "next_cursor": "eyJjcmVhdGVkX2F0IjogIjIwMjYtMTAtMThUMTA6MzA6MDBaIiwgImlkIjogIjdiMzZmNzNkLWYyZTEtNGM3YS05ZGIyLTZkY2ZiOTQwYWQ0MiIsICJsb2NhbF9kYXRlIjogIjIwMjYtMTAtMTgifQ==",
    "has_more": false
  }
  ```

#### `GET /v1/checkins/{id}`
Fetches a single check-in record by UUID.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):** Check-in object.
- **Cross-Account Security (404 Not Found):** If the record exists but belongs to another user, or does not exist, the API returns `404 Not Found` (never 403 Forbidden) to eliminate resource-existence leakage.

#### `PATCH /v1/checkins/{id}`
Updates editable fields (`mood_score`, `stress_score`, `energy_score`, `sleep_quality_score`, `mood_label`, `tags`, `notes`).
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):** Updated check-in object.
- **Error Response (404 Not Found):** If non-existent or owned by another user.

#### `DELETE /v1/checkins/{id}`
Permanently deletes the check-in record.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response:** `204 No Content`.
- **Error Response (404 Not Found):** If non-existent or owned by another user.

---

### 9. Private Journal
#### `POST /v1/journal`
Creates a private journal entry.
- **Idempotency Rule:** `client_id` is unique per user. Initial creation returns `201 Created`; replay with existing `client_id` returns `200 OK`.
- **Headers:** `Authorization: Bearer <access_token>`
- **Request Body:**
  ```json
  {
    "client_id": "a9d82341-b952-473d-8629-656df926c043",
    "title": "Reflections on Exams",
    "body": "Had a demanding study session in the library this morning..."
  }
  ```
- **Validation Rules:**
  - `title`: nullable string, max 120 characters.
  - `body`: required string, 1 to 10,000 characters. Whitespace-only bodies are rejected with `422 Unprocessable Entity`.
- **Success Response (201 Created or 200 OK):**
  ```json
  {
    "id": "99b0c741-2a1e-4509-9fc6-9e8751db1162",
    "client_id": "a9d82341-b952-473d-8629-656df926c043",
    "title": "Reflections on Exams",
    "body": "Had a demanding study session in the library this morning...",
    "created_at": "2026-10-18T10:45:00Z",
    "updated_at": "2026-10-18T10:45:00Z"
  }
  ```

#### `GET /v1/journal`
Lists the authenticated user's journal entries in cursor-paginated summary form.
- **Privacy Guarantee (No Full Body Over Wire):** List responses contain a clean `preview` string (at most 80 characters, normalized whitespace) and strictly omit `body`. Full bodies must be retrieved individually.
- **Headers:** `Authorization: Bearer <access_token>`
- **Query Parameters:**
  - `limit`: integer, 1-100 (default: 20).
  - `cursor`: optional base64-encoded pagination cursor.
- **Success Response (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "99b0c741-2a1e-4509-9fc6-9e8751db1162",
        "client_id": "a9d82341-b952-473d-8629-656df926c043",
        "title": "Reflections on Exams",
        "preview": "Had a demanding study session in the library this morning...",
        "created_at": "2026-10-18T10:45:00Z",
        "updated_at": "2026-10-18T10:45:00Z"
      }
    ],
    "next_cursor": "eyJjcmVhdGVkX2F0IjogIjIwMjYtMTAtMThUMTA6NDU6MDBaIiwgImlkIjogIjk5YjBjNzQxLTJhMWUtNDUwOS05ZmM2LTllODc1MWRiMTE2MiJ9",
    "has_more": false
  }
  ```

#### `GET /v1/journal/{id}`
Retrieves a specific journal entry with its complete `body`.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):** Journal detail object (including `body`).
- **Cross-Account Security (404 Not Found):** If owned by another user or non-existent, returns `404 Not Found` (never 403 Forbidden).

#### `PATCH /v1/journal/{id}`
Updates `title` or `body` of a journal entry.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):** Updated journal detail object.
- **Error Response (404 Not Found):** If non-existent or owned by another user.

#### `DELETE /v1/journal/{id}`
Permanently deletes the journal entry.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response:** `204 No Content`.
- **Error Response (404 Not Found):** If non-existent or owned by another user.

---

### 10. Cycle Tracking & Study Planner Consent

#### `GET /v1/me/planner-cycle-consent`
Retrieves whether the caller has consented to using cycle records in the Study Planner.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):**
  ```json
  {
    "enabled": false,
    "consent_recorded_at": null,
    "deleted_cycle_plans_count": 0
  }
  ```

#### `PUT /v1/me/planner-cycle-consent`
Enables or disables cycle inputs for study planning.
- **Enabling Prerequisite:** Cycle tracking must be enabled first (`/v1/me/cycle-tracking`). If cycle tracking is off, returns HTTP 409 with code `cycle_tracking_required`.
- **Revocation Rule:** Disabling consent transactionally deletes all study plans where `uses_cycle_data` is true in the same transaction, returning deleted counts only.
- **Request Body:**
  ```json
  {
    "enabled": true
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "enabled": true,
    "consent_recorded_at": "2026-10-26T10:00:00Z",
    "deleted_cycle_plans_count": 0
  }
  ```
- **Conflict Error (409 Conflict):**
  ```json
  {
    "code": "cycle_tracking_required",
    "message": "Cycle tracking must be enabled before planner cycle consent can be granted.",
    "details": null,
    "request_id": "..."
  }
  ```

#### `GET /v1/me/cycle-tracking`
Retrieves cycle tracking consent and status.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):**
  ```json
  {
    "cycle_tracking_enabled": true,
    "consent_recorded_at": "2026-10-26T09:30:00Z",
    "deleted_cycle_plans_count": 0,
    "deleted_cycle_records_count": 0
  }
  ```

#### `PUT /v1/me/cycle-tracking`
Enables or disables cycle tracking, with optional data deletion.
- **Disabling Rule:** Turning tracking off or requesting `delete_data=true` transactionally deletes all study plans where `uses_cycle_data` is true.
- **Request Body:**
  ```json
  {
    "cycle_tracking_enabled": false,
    "delete_data": true
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "cycle_tracking_enabled": false,
    "consent_recorded_at": null,
    "deleted_cycle_plans_count": 1,
    "deleted_cycle_records_count": 5
  }
  ```

---

### 11. Personal Insights

#### `GET /v1/insights/weekly?week_start=YYYY-MM-DD`
Compares daily averages for mood, stress, energy, and sleep scores for the target week against the user's prior 4 weeks.
- **Data Threshold:** Requires check-ins on at least 4 distinct days in the week and at least 7 distinct days in the baseline 4 weeks.
- **Observation Codes:** `HIGHER_THAN_USUAL`, `LOWER_THAN_USUAL`, `SIMILAR` (threshold +/- 0.5 points).
- **Headers:** `Authorization: Bearer <access_token>`
- **Sufficient Data Response (200 OK):**
  ```json
  {
    "status": "sufficient_data",
    "week_start": "2026-10-19",
    "metrics": {
      "mood": {
        "week_average": 4.0,
        "baseline_average": 3.2,
        "diff": 0.8,
        "code": "HIGHER_THAN_USUAL"
      },
      "stress": {
        "week_average": 2.0,
        "baseline_average": 3.1,
        "diff": -1.1,
        "code": "LOWER_THAN_USUAL"
      },
      "energy": {
        "week_average": 3.2,
        "baseline_average": 3.0,
        "diff": 0.2,
        "code": "SIMILAR"
      },
      "sleep": {
        "week_average": 3.5,
        "baseline_average": 3.5,
        "diff": 0.0,
        "code": "SIMILAR"
      }
    },
    "sample_sizes": {
      "week_distinct_days": 5,
      "baseline_distinct_days": 14
    }
  }
  ```
- **Insufficient Data Response (200 OK):**
  ```json
  {
    "status": "not_enough_data",
    "week_start": "2026-10-19",
    "days_needed": {
      "week": 1,
      "baseline": 0
    }
  }
  ```

#### `GET /v1/insights/exam-context`
Compares average stress and energy in the 7 days before academic events in the last 60 days against the user's baseline outside those windows.
- **Data Threshold:** Requires at least 2 events each with at least 3 check-in days in its pre-event window.
- **Observation Codes:** `STRESS_HIGHER_BEFORE_EVENTS`, `STRESS_LOWER_BEFORE_EVENTS`, `STRESS_SIMILAR_BEFORE_EVENTS`, `ENERGY_HIGHER_BEFORE_EVENTS`, `ENERGY_LOWER_BEFORE_EVENTS`, `ENERGY_SIMILAR_BEFORE_EVENTS`.
- **Headers:** `Authorization: Bearer <access_token>`
- **Sufficient Data Response (200 OK):**
  ```json
  {
    "status": "sufficient_data",
    "qualifying_events_count": 2,
    "stress": {
      "pre_event_average": 4.5,
      "baseline_average": 2.8,
      "diff": 1.7,
      "code": "STRESS_HIGHER_BEFORE_EVENTS"
    },
    "energy": {
      "pre_event_average": 2.2,
      "baseline_average": 3.8,
      "diff": -1.6,
      "code": "ENERGY_LOWER_BEFORE_EVENTS"
    },
    "sample_sizes": {
      "pre_event_distinct_days": 6,
      "baseline_distinct_days": 12,
      "qualifying_events": 2
    }
  }
  ```

---

### 12. Study Planner

#### `POST /v1/study-plans/generate`
Generates a deterministic 7-day study plan schedule.
- **Headers:** `Authorization: Bearer <access_token>`
- **Request Body:**
  ```json
  {
    "week_start": "2026-11-02",
    "replace": false
  }
  ```
- **Duplicate Conflict (409 Conflict):** Returns code `plan_exists` if a plan already exists for that week and `replace` is false.
- **Success Response (201 Created):**
  ```json
  {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "week_start": "2026-11-02",
    "days": 7,
    "mode": "personalized",
    "uses_cycle_data": false,
    "personalization": {
      "status": "personalized",
      "checkin_days_used": 15,
      "checkin_days_needed": 14
    },
    "items": [
      {
        "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        "study_plan_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "plan_date": "2026-11-02",
        "suggested_load": "focus",
        "reason_codes": ["WEEKDAY_ENERGY_HIGHER"],
        "academic_event_id": null,
        "activity_id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "suggested",
        "updated_at": "2026-10-26T10:00:00Z"
      }
    ],
    "created_at": "2026-10-26T10:00:00Z"
  }
  ```

#### `GET /v1/study-plans/current`
Returns the study plan covering today's date for the caller.
- **Headers:** `Authorization: Bearer <access_token>`
- **Success Response (200 OK):** `StudyPlanResponse`.
- **Error Response (404 Not Found):** If no plan covers today.

#### `GET /v1/study-plans?week_start=YYYY-MM-DD`
Retrieves the study plan for a specific week start date.
- **Success Response (200 OK):** `StudyPlanResponse`.
- **Error Response (404 Not Found):** If not found.

#### `GET /v1/study-plans/{id}`
Retrieves a specific study plan by ID strictly owned by the caller.
- **Cross-Account Security (404 Not Found):** Returns 404 (never 403) if owned by another user.

#### `DELETE /v1/study-plans/{id}`
Permanently deletes a study plan owned by the caller.
- **Success Response:** `204 No Content`.
- **Cross-Account Security (404 Not Found):** Returns 404 (never 403) if owned by another user.


#### `PATCH /v1/study-plans/items/{id}`
Updates an item's user decision status (`accepted`, `edited`, `skipped`).
- **Load Modification Rule:** `suggested_load` (`light`, `normal`, `focus`) is permitted strictly when `status == "edited"`.
- **No Penalty on Skipping:** Skipping any item is supported with zero penalties.
- **Request Body:**
  ```json
  {
    "status": "edited",
    "suggested_load": "focus"
  }
  ```
- **Success Response (200 OK):** `StudyPlanItemResponse`.
- **Validation Error (422 Unprocessable Entity):** If `suggested_load` is provided when `status != "edited"` or unknown fields are sent.
- **Cross-Account Security (404 Not Found):** Returns 404 if owned by another user.

---

### 13. HelpHub: Resources & Access Points

#### `GET /v1/resources`
Lists verified campus and community resources, helplines, and period-product access points.
- **Access:** Public.
- **Query Parameters:**
  - `category` (optional, string): Filter by category (`counseling`, `helpline`, `welfare_office`, `period_products`, `ngo`, `health_clinic`, `workshop`).
  - `city` (optional, string): Case-insensitive city search.
  - `cost` (optional, string): Filter by cost (`free`, `paid`, `unknown`).
  - `product_type` (optional, string): Filter period products (`pads`, `cups`, `disposal`, etc.).
  - `verified_only` (optional, boolean, default `true`): Only return verified resources.
  - `q` (optional, string): Plain-text search on name or description (zero-logged).
  - `page` (optional, integer, default `1`).
  - `page_size` (optional, integer, default `20`, max `100`).
- **Response Format (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440001",
        "name": "Campus Student Wellness Center (Demo)",
        "category": "counseling",
        "description": "Confidential counseling and mental health support for students.",
        "phone": "+91-0000000001",
        "email": "demo-counselor@example.org",
        "website_url": "https://example.org/demo-wellness",
        "address": "Building A, Ground Floor, Campus (Demo)",
        "city": "Pune",
        "hours_text": "Mon-Fri 09:00 - 17:00",
        "available_24x7": false,
        "languages": ["en", "hi", "mr"],
        "cost": "free",
        "product_details": null,
        "source_url": "https://example.org/source/demo-wellness",
        "verification_status": "verified",
        "last_verified_at": "2026-10-01",
        "is_published": true,
        "is_demo": true,
        "created_at": "2026-10-27T12:00:00Z",
        "updated_at": "2026-10-27T12:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 20
  }
  ```

#### `GET /v1/resources/support`
Curated shortcut endpoint returning 24x7 verified emergency helplines and free counseling resources.
- **Access:** Public.
- **Response Format (200 OK):** `ResourceListResponse`.

#### `GET /v1/resources/{id}`
Retrieves detailed information for a specific resource by ID.
- **Access:** Public.
- **Response Format (200 OK):** `ResourceResponse`.
- **Error (404 Not Found):** If resource does not exist or is unpublished (and non-demo when `ALLOW_DEMO_RESOURCES=false`).

#### `POST /v1/resources/{id}/report`
Submits an outdated/broken info report for a resource (e.g. empty dispenser, disconnected helpline).
- **Access:** Authenticated student (`Authorization: Bearer <token>`).
- **Request Body:**
  ```json
  {
    "reason": "out_of_order",
    "note": "Dispenser was empty on Monday morning."
  }
  ```
  *(Reason options: `outdated`, `out_of_order`, `incorrect`, `closed`, `other`).*
- **Response Format (201 Created):**
  ```json
  {
    "id": "880e8400-e29b-41d4-a716-446655440001",
    "resource_id": "770e8400-e29b-41d4-a716-446655440001",
    "reason": "out_of_order",
    "note": "Dispenser was empty on Monday morning.",
    "status": "open",
    "created_at": "2026-10-27T12:30:00Z",
    "resolved_at": null,
    "resolved_note": null
  }
  ```
- **Conflict (409 Conflict):** Returns code `report_exists` if the user already has an `open` report for this resource.

#### `GET /v1/me/resource-reports`
Retrieves reports submitted by the authenticated user.
- **Access:** Authenticated student (`Authorization: Bearer <token>`).
- **Response Format (200 OK):**
  ```json
  [
    {
      "id": "880e8400-e29b-41d4-a716-446655440001",
      "resource_id": "770e8400-e29b-41d4-a716-446655440001",
      "reason": "out_of_order",
      "note": "Dispenser was empty on Monday morning.",
      "status": "open",
      "created_at": "2026-10-27T12:30:00Z",
      "resolved_at": null,
      "resolved_note": null
    }
  ]
  ```

---

### 14. Reviewed Education Content

#### `GET /v1/education`
Lists reviewed, published educational articles.
- **Access:** Public.
- **Query Parameters:**
  - `category` (optional, string): Filter by category (`periods_basics`, `hygiene`, `common_symptoms`, `when_to_seek_care`, `emotional_wellbeing`, `supporting_someone`).
  - `language` (optional, string, default `"en"`): Article language (`en`, `hi`, `mr`). If an article in the requested language is not published, English version is listed as fallback with a `fallback_to_en: true` indicator.
  - `page` (optional, integer, default `1`).
  - `page_size` (optional, integer, default `20`).
- **Response Format (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "990e8400-e29b-41d4-a716-446655440001",
        "slug": "what-is-a-period",
        "title": "Understanding What a Period Is",
        "category": "periods_basics",
        "language": "en",
        "summary": "A friendly introduction to what happens during a menstrual cycle and why it is a routine part of bodily wellness.",
        "source_name": "BloomWell team draft",
        "source_url": "https://example.org/education/menstrual-cycle-basics",
        "review_status": "draft",
        "reviewed_at": null,
        "is_published": true,
        "created_at": "2026-10-27T12:00:00Z",
        "updated_at": "2026-10-27T12:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 20
  }
  ```

#### `GET /v1/education/{slug}`
Retrieves a full educational article by slug with automatic language fallback.
- **Access:** Public.
- **Query Parameters:**
  - `language` (optional, string, default `"en"`): Preferred language (`en`, `hi`, `mr`). If not found in requested language, falls back to English.
- **Response Format (200 OK):** `EducationDetailResponse` (includes full plain text `body`).
- **Error (404 Not Found):** If article does not exist or is unpublished (and not `ALLOW_DRAFT_CONTENT=true`).

---

### 15. Admin Workflows (`resource_admin` role)

All `/v1/admin/*` endpoints require authentication with a user having `role == "resource_admin"`.
Non-admin users receive `403 Forbidden` with code `forbidden`.

#### `POST /v1/admin/resources`
Creates a new campus/community resource or period-product point.
- **Request Body:** `ResourceCreateRequest`.
- **Response Format (201 Created):** `ResourceResponse`.

#### `PATCH /v1/admin/resources/{id}`
Updates details of an existing resource.
- **Request Body:** `ResourceUpdateRequest`.
- **Response Format (200 OK):** `ResourceResponse`.

#### `DELETE /v1/admin/resources/{id}`
Permanently deletes a resource and its associated reports.
- **Response Format (204 No Content)**.

#### `POST /v1/admin/resources/{id}/verify`
Verifies a resource after conducting manual official check.
- **Request Body:**
  ```json
  {
    "source_url": "https://example.org/verified-official-source"
  }
  ```
- **Response Format (200 OK):** `ResourceResponse` with `verification_status: "verified"`, `last_verified_at: "<today>"`, and `verified_by: "<admin_email>"`.

#### `POST /v1/admin/resources/{id}/mark-outdated`
Flags a resource as outdated (e.g. after reports or broken verification).
- **Response Format (200 OK):** `ResourceResponse` with `verification_status: "outdated"`.

#### `GET /v1/admin/resources?stale=true`
Lists resources for audit, including a `stale=true` query filter that lists resources unverified for longer than `RESOURCE_STALE_DAYS` (default 180 days).
- **Response Format (200 OK):** `ResourceListResponse`.

#### `GET /v1/admin/resource-reports`
Lists submitted community reports.
- **Query Parameters:**
  - `status` (optional, string): `open`, `resolved`, `dismissed`.
  - `resource_id` (optional, UUID).
  - `page` (optional, integer, default `1`).
  - `page_size` (optional, integer, default `20`).
- **Privacy Enforcement:** Responses return `AdminResourceReportResponse`, which **strictly omits `reporter_id`** to protect user anonymity from administrators.
- **Response Format (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "880e8400-e29b-41d4-a716-446655440001",
        "resource_id": "770e8400-e29b-41d4-a716-446655440001",
        "reason": "out_of_order",
        "note": "Dispenser was empty on Monday morning.",
        "status": "open",
        "created_at": "2026-10-27T12:30:00Z",
        "resolved_at": null,
        "resolved_note": null
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 20
  }
  ```

#### `PATCH /v1/admin/resource-reports/{id}`
Resolves or dismisses a report.
- **Request Body:**
  ```json
  {
    "status": "resolved",
    "resolved_note": "Refilled dispenser and verified functional."
  }
  ```
- **Response Format (200 OK):** `AdminResourceReportResponse`.

#### `POST /v1/admin/education`
Creates a new educational content article.
- **Request Body:** `EducationCreateRequest` (must include `title`, `slug`, `category`, `language`, `summary`, `body`, `source_name`, `source_url`, `is_published`).
- **Response Format (201 Created):** `EducationDetailResponse`.

#### `PATCH /v1/admin/education/{id}`
Updates an article, marks as reviewed, or publishes.
- **Request Body:** `EducationUpdateRequest`.
- **Response Format (200 OK):** `EducationDetailResponse`.

#### `DELETE /v1/admin/education/{id}`
Permanently deletes an educational article.
- **Response Format (204 No Content)**.

---

### 14. Privacy Center & Account Management

#### `POST /v1/me/reauth`
Verifies user password and returns a short-lived step-up token for sensitive actions.
- **Rate Limit:** 5 requests per minute per user and per IP.
- **Request Body:**
  ```json
  {
    "password": "UserPassword123!"
  }
  ```
- **Response Format (200 OK):**
  ```json
  {
    "step_up_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 300
  }
  ```

#### `GET /v1/me/export`
Generates and downloads on-the-fly JSON export of the caller's complete data bundle.
- **Headers Required:** `Authorization: Bearer <access_token>`, `X-Reauth-Token: <step_up_token>`.
- **Rate Limit:** 3 requests per user per day.
- **Response Headers:**
  - `Content-Disposition: attachment; filename="bloomwell-data-export.json"`
  - `Cache-Control: no-store`
  - `Content-Type: application/json`
- **Response Format (200 OK):** Complete user data export including metadata, profile, preferences, check-ins, journal entries, academic events, activity logs, cycle logs, study plans, and account events.
- **Error (413 Request Entity Too Large):** If total records exceed `EXPORT_MAX_RECORDS` (default: 50,000).

#### `DELETE /v1/me`
Permanently deletes the caller's account and all associated personal data in one database transaction.
- **Headers Required:** `Authorization: Bearer <access_token>`, `X-Reauth-Token: <step_up_token>`.
- **Request Body:**
  ```json
  {
    "confirm": "DELETE"
  }
  ```
- **Response Format (204 No Content)**. Old access token fails with 401 immediately after deletion.

#### `GET /v1/me/consents`
Returns the overview of feature and privacy consents.
- **Response Format (200 OK):**
  ```json
  {
    "cycle_tracking": {
      "enabled": true,
      "enabled_at": "2026-10-26T10:00:00Z"
    },
    "planner_cycle": {
      "enabled": true,
      "enabled_at": "2026-10-26T10:05:00Z"
    },
    "ai_recommendations": {
      "enabled": false
    },
    "journal_ai": {
      "enabled": false,
      "consented_at": null
    },
    "ai_available": false,
    "reminders_enabled": true
  }
  ```

#### `PUT /v1/me/consents/ai-recommendations`
Toggles AI recommendations consent.
- **Request Body:**
  ```json
  {
    "enabled": true
  }
  ```
- **Response Format (200 OK):**
  ```json
  {
    "enabled": true,
    "consented_at": null,
    "ai_available": false
  }
  ```

#### `PUT /v1/me/consents/journal-ai`
Toggles Journal AI reflection consent.
- **Request Body:**
  ```json
  {
    "enabled": true
  }
  ```
- **Response Format (200 OK):**
  ```json
  {
    "enabled": true,
    "consented_at": "2026-10-31T12:00:00Z",
    "ai_available": false
  }
  ```

#### `POST /v1/me/password`
Changes account password, verifies current password, enforces minimum 10 chars and denylist, revokes all sessions, and returns a fresh token pair.
- **Request Body:**
  ```json
  {
    "current_password": "OldPassword123!",
    "new_password": "NewSecretPassword456!"
  }
  ```
- **Response Format (200 OK):** `TokenResponse` with `access_token` and `refresh_token`.

#### `POST /v1/me/sessions/revoke-all`
Revokes all refresh tokens ("log out everywhere").
- **Response Format (204 No Content)**. Note: current access token stays valid until expiration (15 minutes max).

#### `GET /v1/me/sessions`
Returns active session count without storing or exposing device or IP info.
- **Response Format (200 OK):**
  ```json
  {
    "active_sessions": 2
  }
  ```

#### `GET /v1/me/account-events`
Returns cursor-paginated security activity audit log, newest first.
- **Query Parameters:** `limit` (default: 20, max: 100), `cursor` (UUID).
- **Response Format (200 OK):**
  ```json
  {
    "items": [
      {
        "id": "e4587ba2-8e10-4e31-8f4b-2259161a067a",
        "event_type": "password_changed",
        "created_at": "2026-10-31T12:15:00Z"
      }
    ],
    "next_cursor": null,
    "has_more": false
  }
  ```



