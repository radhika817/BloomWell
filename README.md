# BloomWell 🌸

### A privacy-first menstrual wellness, self-care, and peer-support platform for women students

**Project:** Hackathon-ready full-stack mobile app\
**Timeline:** 6 weeks for MVP; 1--2 extra weeks for polish\
**Mobile:** Flutter · **Backend:** FastAPI · **Database:** PostgreSQL ·
**Cloud:** AWS · **AI:** LLM API called through the backend\
**Languages (planned):** English, Hindi, Marathi

BloomWell helps women students understand their menstrual and emotional
well-being, plan study life around how they actually feel, find practical
self-care and period-product access, and feel less alone through
moderated peer support and trusted resources. It combines cycle
tracking, private journaling, non-diagnostic insights, an exam-aware
study planner, optional AI-assisted reflection, comfort routines,
menstrual education, and community support --- all behind a discreet,
privacy-first design.

> **Important:** BloomWell is a wellness and educational tool---not a
> diagnostic system, medical device, therapy service, or emergency
> response service.

## Contents

1.  [Problem and vision](#1-problem-and-vision)
2.  [What makes BloomWell different](#2-what-makes-bloomwell-different)
3.  [Features](#3-features)
4.  [Roles and user journeys](#4-roles-and-user-journeys)
5.  [MVP scope](#5-mvp-scope)
6.  [Technology stack](#6-technology-stack)
7.  [Architecture](#7-architecture)
8.  [Repository structure](#8-repository-structure)
9.  [Database schema](#9-database-schema)
10. [API plan](#10-api-plan)
11. [Privacy, security, and responsible
    AI](#11-privacy-security-and-responsible-ai)
12. [Cycle insights and study planner rules](#12-cycle-insights-and-study-planner-rules)
13. [Safety layer](#13-safety-layer)
14. [Community moderation](#14-community-moderation)
15. [Six-week roadmap](#15-six-week-roadmap)
16. [Testing and acceptance
    criteria](#16-testing-and-acceptance-criteria)
17. [Local setup](#17-local-setup)
18. [Environment variables](#18-environment-variables)
19. [Deployment](#19-deployment)
20. [Hackathon demo](#20-hackathon-demo)
21. [Future scope](#21-future-scope)
22. [Success metrics and disclaimer](#22-success-metrics-and-disclaimer)

------------------------------------------------------------------------

## 1. Problem and vision

College life can involve academic pressure, stress, loneliness, changes
in routine, and uncertainty about where to find trustworthy support.
Menstruation can add physical discomfort or emotional challenges, but
experiences vary widely. Some students want to track cycles and
symptoms; others want comfort suggestions, private reflection, practical
access to period products, or someone who listens without judgment.

In many campuses, stigma around periods, shared phones and living
spaces, limited access to products, and language barriers make it harder
to seek help. Existing apps usually cover only one need (tracking, or
mood, or community) and rarely connect it to student life.

BloomWell brings these connected needs together while protecting
sensitive information.

### Goals

-   Let users record periods, symptoms, mood, energy, sleep, and private
    reflections.
-   Show personal patterns without diagnosing or making medical
    conclusions.
-   Help students plan study and rest around their own energy and exam
    calendar --- as suggestions, never predictions.
-   Offer manageable self-care routines and comfort plans.
-   Provide optional AI-assisted reflection and activity
    recommendations.
-   Connect users with menstrual education, verified campus resources,
    period-product access points, and moderated peer support.
-   Keep the app usable and discreet for students who share devices or
    live in low-privacy environments.
-   Give users control over their data, consent, and participation.

### Product principles

-   Privacy first; personal records are private by default.
-   Cycle tracking, AI, reminders, the study planner, and community
    participation are optional.
-   No mood rankings, shame-based streaks, or pressure to be productive.
-   Educational content and support resources have sources and review
    dates.
-   Users do not need to disclose period or health information to access
    community support.
-   The app directs users to appropriate professional help when needed
    and never pretends to provide clinical care.
-   Discretion is a feature: nothing sensitive appears on a lock screen,
    in a notification, or in an app switcher by default.

## 2. What makes BloomWell different

| Differentiator | What it does | Why it matters |
|---|---|---|
| **Cycle-aware, exam-aware Study Planner** | Combines the user's own energy check-ins, optional cycle records, and entered exams/deadlines to suggest lighter or heavier study blocks and rest breaks | Most apps track a cycle *or* moods *or* study; few connect them to student life, and none of it is presented as a prediction |
| **Discreet Mode** | App lock (PIN/biometric), neutral notification text, hidden previews in the app switcher, optional alternate icon/label where the platform allows | Many students share phones or live with family; privacy has to work in daily life, not just on paper |
| **Regional language support** | Hindi and Marathi alongside English, with stigma-sensitive, reviewed wording | Support is more useful when it is in the language people think in |
| **Period-product access (HelpHub)** | Verified listings of campus dispensers, NGOs, government schemes, and pharmacies, with user reports for outdated/out-of-order points | Turns the app from "information" into practical help |
| **Doctor-visit Summary** | One-page PDF of the user's own recorded symptoms and dates, which she chooses to export and show a clinician | Helps students who find it hard to describe symptoms; supports "know when to seek care" |
| **Gentle Safety Layer** | Shows verified support resources when journal text or posts contain distress language --- without alerting anyone or storing the text | Responsible handling of difficult moments in an app that invites vulnerability |
| **Consent-separated AI** | Recommendations and journal reflection have independent consents; curated library first, AI second; full fallback | AI that users can understand, control, and turn off |
| **Role-enforced privacy** | Moderators and administrators can never see private records; verified by automated tests | Privacy that is demonstrable in a live demo |

## 3. Features

### 3.1 CycleCare --- menstrual cycle tracker

-   Log period start/end dates and view a calendar/history.
-   Record symptoms such as cramps, bloating, fatigue, headaches, and
    user-defined symptoms.
-   Record symptom severity and optional notes.
-   Track mood, energy, and sleep alongside cycle records.
-   Show estimated next-period dates only when there is enough usable
    history.
-   Offer optional discreet reminders.
-   Edit and delete cycle and symptom records.

**Rules:** Recorded dates and estimated dates must look different.
Predictions are uncertain and are not medical, pregnancy, or fertility
guidance. Do not assume stress caused a late or changed period. Cycle
tracking is not required to use other features.

### 3.2 MoodMap --- mood, private journal, and insights

-   Daily mood, stress, energy, and sleep-quality check-ins.
-   Optional tags and private journal entries.
-   Calendar/history and weekly/monthly charts.
-   Edit/delete past records.
-   Personal observations based on the user's own entries.
-   Optional comparison with user-entered exams or deadlines.

Example: "You recorded higher stress on several days near deadlines."
This is an observation, not proof of causation.

### 3.3 Comfort Mode --- support for difficult days

-   One-tap access to gentle comfort activities.
-   Breathing, grounding, relaxation, and reflection exercises.
-   General comfort suggestions, such as rest or a warm compress, with
    appropriate caveats.
-   A saved personal comfort plan.
-   A low-pressure "keep it simple today" experience.
-   Optional access to the "I'm Here" support experience.
-   No penalties for skipping activities.

The app must not claim these activities treat medical conditions.
Severe, unusual, persistent, or concerning symptoms should be directed
to qualified medical care.

### 3.4 Self-Care Studio --- routines and challenges

-   Curated short activities for relaxation, study breaks, journaling,
    confidence, and menstrual comfort.
-   Daily/weekly routines, favorites, completion tracking, and optional
    helpfulness feedback.
-   Seven-day self-care challenges.
-   Progress celebrations without competitive mood scores or shame-based
    streaks.

### 3.5 Study Planner *(new --- flagship differentiator)*

An optional planner that helps students balance academic load with their
own energy.

-   Enter exams and deadlines (also used by exam-stress insights).
-   Receive a **suggested weekly rhythm**: heavier study blocks on days
    the user has historically logged higher energy, lighter blocks and
    breaks on days she has logged low energy or high discomfort.
-   Optional inclusion of cycle records as an input (separate opt-in).
    The planner works fully without cycle data, using only energy and
    sleep check-ins.
-   Suggested study breaks linked to Self-Care Studio activities.
-   The user can accept, edit, or ignore every suggestion.

Example: "Your history shows lower energy on some days near your period.
Your chemistry exam is on the 22nd. Would you like a lighter plan for
those days, with extra revision earlier in the week?"

**Rules:** Suggestions, not predictions. No claim that cycle phase causes
low energy; the planner only reflects what the user herself recorded.
Cycle data is never sent to the AI provider for planning. See
[section 12](#12-cycle-insights-and-study-planner-rules).

### 3.6 Optional AI Self-Care Companion

-   Recommend activities from a curated wellness library.
-   Explain why an activity may match stated preferences.
-   Offer reflective prompts and summarize a selected journal entry with
    explicit consent.
-   Help discover relevant educational resources.
-   Provide a useful fallback when AI is unavailable.

**AI requirements:** All AI calls go through the backend; provider keys
never ship in Flutter. Recommendation consent and journal-processing
consent are separate. Send only necessary data. Do not log raw journal
text by default. Label AI-generated content. Never diagnose, prescribe
treatment, or claim to predict health conditions. Validate responses and
handle unsafe or failed outputs. Disclose provider data handling
accurately.

### 3.7 "I'm Here" --- emotional support

Users can choose what they need: - "I need to vent" - "I want
encouragement" - "I want advice" - "I need a distraction" - "I have a
period-related question" - "I want to feel less alone"

Support preferences help other members respond appropriately. Posting is
optional; users can use private features without joining a group.

### 3.8 Cycle Circles --- moderated peer-support groups

Initial topics: - Menstrual experiences and education. - Periods during
college. - Exam stress and college adjustment. - Body confidence and
self-care. - Emotional well-being and loneliness.

Features: topic-based groups, pseudonymous display names, text
posts/replies, community guidelines, reporting, a moderator queue, and
content removal. Blocking follows as soon as reporting is stable.

Version 1 excludes direct messages, public follower counts, mood
leaderboards, unmoderated medical advice, and automatic matching based
on menstrual dates. Users never need to disclose cycle data to join a
group.

### 3.9 HelpHub --- verified support, access, and education

-   Searchable directory of campus counseling, student-welfare offices,
    workshops, support organizations, and relevant helplines.
-   **Period-product access points:** campus dispensers/disposal units,
    NGO distribution drives, government schemes, and nearby pharmacies,
    each with location/contact details when verified.
-   Resource categories, descriptions, contact details, and hours when
    verified.
-   Source URL, verification status, and last-reviewed date.
-   Reporting for outdated information (including "dispenser empty / out
    of order") and an authorized update workflow.
-   Reviewed menstrual-health content covering periods, hygiene, common
    symptoms, and when to seek professional assessment.
-   Optional education for friends, partners, and parents on how to
    support someone, written in neutral, stigma-free language.

Never invent a helpline or imply a service is available 24/7 unless
verified. Seed data must be checked against official sources before
publication. Candidate categories to verify for an Indian campus context
include national mental-health helplines, state/central menstrual-hygiene
schemes, campus counseling or internal committees, and local NGOs.

### 3.10 Exam-stress insights

-   Optional exams and deadline entries.
-   Compare check-in trends with user-entered academic events.
-   Show personal observations only when enough data exists.
-   Suggest study breaks or relevant self-care activities.

Do not present correlations as causes.

### 3.11 Discreet Mode *(new)*

-   App lock with PIN and/or device biometrics (stored on the device).
-   Neutral notification wording such as "Time for your daily check-in";
    no period, mood, or symptom terms on the lock screen.
-   Hide screen contents in the app switcher/recent apps and block
    screenshots on sensitive screens where the platform allows.
-   Optional alternate app icon/label where supported.
-   Quick-hide gesture that returns to a neutral screen.
-   Discreet mode is off by default but offered during onboarding.

### 3.12 Languages *(new)*

-   English first, then Hindi and Marathi.
-   Use Flutter localization from day one (no hard-coded strings) so
    languages can be added without rewrites.
-   Curated activity and education content is translated and reviewed by
    a fluent reader, not machine-translated alone.
-   AI responses use the user's chosen language where the provider
    supports it, with the same labeling and safety rules.

### 3.13 Doctor-visit Summary *(new)*

-   On request, generate a one-page PDF from the user's own records for a
    selected date range.
-   The user chooses which categories to include (period dates,
    symptoms/severity, notes she selects). Journal text and mood scores
    are excluded by default.
-   Shows **recorded** data only; any estimate is clearly labeled and can
    be left out.
-   Includes a short "questions to ask" section and the standard
    non-diagnostic disclaimer.
-   Generated on demand, delivered to the user only, and not stored
    beyond a short-lived temporary file.
-   Never sent to anyone automatically.

**Optional "worth mentioning to a doctor" nudge (P2, off until
clinically reviewed):** a conservative, rule-based reminder shown when
the user's own logs include repeated high-severity symptoms. It uses
generic wording and does not label the user or her cycle abnormal.

### 3.14 Privacy Center

-   Plain-language data and AI-processing explanations.
-   Separate settings for AI recommendations, journal processing,
    cycle data in the study planner, reminders, and community
    participation.
-   Discreet Mode and language settings.
-   Export personal records and delete account/data.
-   Blocked-user controls and discreet notification settings.
-   No sharing of individual cycle, mood, or journal data with colleges,
    other users, or moderators.

## 4. Roles and user journeys

### Roles

-   **Student:** manages their own records, routines, preferences, and
    group participation; can report/block and export/delete data.
-   **Moderator:** reviews reported content and applies community rules;
    cannot browse private journals, cycle logs, or mood histories.
-   **Resource administrator:** manages resource listings and
    verification dates.

Enforce all roles on the backend, not merely by hiding UI controls.

### Main journeys

**Check-in to self-care:** sign in → record mood/stress → view a
personal observation → choose an activity → optionally record
helpfulness.

**Cycle to comfort:** opt into CycleCare → record period/symptoms →
review history and uncertain estimates → save a comfort routine.

**Exam week planning:** add an exam → log energy for a few days →
review a suggested weekly rhythm → accept or edit it → schedule a study
break activity.

**AI reflection:** select a journal entry → read the processing notice →
explicitly consent → backend sends minimum necessary text → validated AI
reflection appears with a clear label.

**Peer support:** accept guidelines → join a topic group → post/reply →
report if needed → moderator reviews reports.

**Finding practical help:** open HelpHub → filter "period products" →
view a verified access point → report it if outdated.

**Visiting a doctor:** open Privacy Center or Insights → choose date
range and categories → generate a summary PDF → keep or share it
herself.

**Privacy:** open Privacy Center → adjust preferences → request export
or deletion → backend authenticates and completes the request.

## 5. MVP scope

| Priority | Scope |
|---|---|
| **P0 --- Essential** | Authentication, private mood/journal, cycle and symptom logging, Comfort Mode, curated self-care library, basic insights, HelpHub (incl. period-product access), consent controls, data deletion, app lock, localization scaffolding (English) |
| **P1 --- Differentiating** | Study Planner, exam-context insights, AI recommendations, consent-based journal reflection, Safety Layer, Discreet notifications, Doctor-visit Summary, basic moderated text communities (pre-seeded groups, posting, reporting) |
| **P2 --- If time permits** | Hindi/Marathi content, blocking and richer moderation dashboard, supportive reactions, alternate app icon, clinically reviewed "worth mentioning to a doctor" nudge |
| **Out of scope for v1** | Direct messaging, video calls, clinical screening/diagnosis, predictive health models, custom-trained LLMs, complex social feeds, anonymous product-swap requests, college-level analytics, microservices, Kubernetes |

**MVP acceptance scenario:** A student can register, enable app lock,
record a check-in and optional cycle symptoms, review private history,
add an exam and see a suggested study rhythm, choose a comfort activity,
optionally request an AI reflection with consent, find a verified
resource or period-product access point, generate a doctor-visit summary,
and participate in a moderated group while her private records remain
inaccessible to others.

**Scope rule:** if time is short, cut in this order: extra languages →
community depth → AI features → Doctor-visit Summary. Never compromise
privacy/security or the core cycle-to-comfort and study-planning
workflows.

## 6. Technology stack

| Layer | Choice | Purpose |
|---|---|---|
| Mobile | Flutter + Dart | Cross-platform app |
| State management | Riverpod | Testable app state |
| Navigation | GoRouter | Navigation/protected routes |
| API client | Dio | HTTP and error handling |
| Localization | Flutter `intl` / ARB files | English, Hindi, Marathi |
| On-device security | Secure storage, `local_auth` (PIN/biometrics) | Tokens, app lock |
| Backend | Python + FastAPI | REST API and business logic |
| Database | PostgreSQL | Persistent data |
| ORM/migrations | SQLAlchemy + Alembic | Database access/schema changes |
| Authentication | Password hashing + access/refresh token strategy | Authenticated access |
| PDF generation | Server-side PDF library (e.g., ReportLab) | Doctor-visit Summary |
| AI | LLM API via backend | Optional reflection/recommendations |
| Container | Docker | Repeatable deployment |
| Cloud | AWS EC2 and secured PostgreSQL deployment | Hosting |
| CI | GitHub Actions | Automated tests and quality checks |

Keep the architecture modular but simple. Do not add S3 until file
uploads are required. Select an AI provider only after reviewing its
data-handling terms.

## 7. Architecture

``` text
Flutter Mobile App
  ├── UI / Riverpod / GoRouter / localization
  ├── Discreet Mode (app lock, privacy screen, neutral notifications)
  ├── On-device safety-phrase check (no text leaves the device)
  └── Dio API client
          │ HTTPS
          ▼
FastAPI Backend
  ├── Authentication and authorization
  ├── Mood and journal service
  ├── Cycle and symptom service
  ├── Activities and insights service
  ├── Study planner service
  ├── AI gateway and consent checks
  ├── Resources, access points, and education service
  ├── Community and moderation service
  ├── Doctor-visit summary (PDF) service
  └── Privacy/export/deletion service
          │
          ├── PostgreSQL
          └── External LLM API (consent-controlled)

Optional React Admin Dashboard
  └── Same API with restricted admin/moderator routes
```

Rules: Flutter never connects directly to the production database; every
private endpoint checks identity and ownership; AI keys stay on the
backend; migrations and deployment must be reproducible.

## 8. Repository structure

``` text
bloomwell/
├── README.md
├── .gitignore
├── docker-compose.yml
├── .env.example
├── docs/
│   ├── requirements.md
│   ├── architecture.md
│   ├── database-erd.md
│   ├── api-contract.md
│   ├── privacy-and-safety.md
│   ├── study-planner-rules.md
│   ├── content-review-log.md
│   └── demo-script.md
├── mobile/
│   └── lib/
│       ├── app/
│       ├── l10n/                     # en, hi, mr ARB files
│       ├── core/                     # api, auth, routing, theme, widgets, privacy_lock
│       └── features/
│           ├── authentication/
│           ├── home/
│           ├── mood/
│           ├── journal/
│           ├── cycle_care/
│           ├── comfort_mode/
│           ├── self_care/
│           ├── study_planner/
│           ├── ai_companion/
│           ├── resources/
│           ├── communities/
│           ├── doctor_summary/
│           └── privacy/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   ├── db/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── api/
│   │   ├── services/
│   │   └── repositories/
│   ├── migrations/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
└── admin-web/                        # Optional React dashboard
```

This is the target structure. Create modules incrementally rather than
generating everything before the first feature works.

## 9. Database schema

Use UUID primary keys, foreign keys, timestamps, migrations, and
indexes. Store the user's time zone for date-based displays and
reminders.

| Table | Important fields | Purpose |
|---|---|---|
| `users` | `id`, `email`, `password_hash`, `display_name`, `role`, `created_at`, `deleted_at` | Account/role |
| `user_preferences` | `user_id`, `timezone`, `language`, `reminders_enabled`, `discreet_notifications`, `ai_recommendations_enabled`, `journal_ai_consent_at`, `planner_cycle_consent_at` | Preferences/consent |
| `mood_checkins` | `id`, `user_id`, `mood_score`, `stress_score`, `energy_score`, `sleep_quality_score`, `notes`, `created_at` | Daily check-ins |
| `journal_entries` | `id`, `user_id`, `title`, `body`, `created_at`, `updated_at` | Private journal |
| `cycle_logs` | `id`, `user_id`, `period_start`, `period_end`, `created_at` | Period dates |
| `symptom_logs` | `id`, `user_id`, `cycle_log_id`, `symptom_type`, `severity`, `notes`, `recorded_at` | Symptoms |
| `academic_events` | `id`, `user_id`, `title`, `event_date`, `event_type` | Exams/deadlines |
| `study_plans` | `id`, `user_id`, `week_start`, `uses_cycle_data`, `created_at` | Planner weeks |
| `study_plan_items` | `id`, `study_plan_id`, `plan_date`, `suggested_load` (light/normal/focus), `academic_event_id`, `activity_id`, `status` (suggested/accepted/edited/skipped) | Planner suggestions and user decisions |
| `activities` | `id`, `title`, `category`, `duration_minutes`, `content`, `language`, `source`, `is_published` | Curated activities |
| `user_activity_logs` | `id`, `user_id`, `activity_id`, `completed_at`, `helpfulness_rating` | Completion/feedback |
| `routines` | `id`, `user_id`, `title`, `start_date`, `end_date` | Personal plans |
| `routine_items` | `id`, `routine_id`, `activity_id`, `scheduled_date`, `completed_at` | Routine activities |
| `resources` | `id`, `name`, `category`, `description`, `contact_details`, `location`, `source_url`, `verification_status`, `last_verified_at` | Support directory (incl. `period_products` category) |
| `resource_reports` | `id`, `resource_id`, `reporter_id`, `reason` (outdated/out_of_order/incorrect), `status`, `created_at` | Outdated-info reports |
| `education_resources` | `id`, `title`, `category`, `language`, `body_or_url`, `source`, `reviewed_at`, `is_published` | Reviewed content |
| `groups` | `id`, `name`, `topic`, `description`, `is_active` | Peer circles |
| `group_memberships` | `group_id`, `user_id`, `joined_at`, `membership_status` | Membership |
| `community_posts` | `id`, `group_id`, `author_id`, `body`, `status`, `created_at` | Posts |
| `community_comments` | `id`, `post_id`, `author_id`, `body`, `status`, `created_at` | Replies |
| `content_reports` | `id`, `reporter_id`, `target_type`, `target_id`, `reason`, `status`, `reviewed_by` | Moderation |
| `blocked_users` | `blocker_id`, `blocked_id`, `created_at` | Blocking |
| `ai_interactions` | `id`, `user_id`, `interaction_type`, `created_at`, `status` | Minimal audit metadata; no raw journal by default |
| `safety_events` | `id`, `user_id` (nullable), `source_type`, `created_at` | Counts that a support card was shown; **never stores text** |
| `data_export_jobs` | `id`, `user_id`, `status`, `created_at`, `completed_at`, `expires_at` | Optional async export |

### Data rules

-   Scope every private-data query to the authenticated user.
-   Treat cycle, symptom, mood, and journal records as sensitive.
-   Do not expose private records to moderators or resource
    administrators.
-   Do not log raw journal text or AI prompts by default.
-   Do not store generated doctor-visit PDFs; delete temporary files
    promptly.
-   Do not store the text that triggered a safety card.
-   Index `user_id`, `created_at`, `period_start`, `group_id`, `plan_date`,
    and moderation `status`.
-   Support incomplete period records.
-   Compute estimates from history and label them as estimates.
-   Consider encrypting journal bodies and symptom notes at rest at the
    application level (stretch goal); do not claim end-to-end encryption
    unless it is implemented and tested.
-   Document deletion behavior for related records, exports, caches, and
    applicable backup-retention procedures.

### Relationship overview

``` mermaid
erDiagram
    USERS ||--o{ MOOD_CHECKINS : records
    USERS ||--o{ JOURNAL_ENTRIES : writes
    USERS ||--o{ CYCLE_LOGS : records
    CYCLE_LOGS ||--o{ SYMPTOM_LOGS : includes
    USERS ||--o{ ACADEMIC_EVENTS : records
    USERS ||--o{ STUDY_PLANS : receives
    STUDY_PLANS ||--o{ STUDY_PLAN_ITEMS : contains
    ACADEMIC_EVENTS ||--o{ STUDY_PLAN_ITEMS : informs
    USERS ||--o{ USER_ACTIVITY_LOGS : completes
    ACTIVITIES ||--o{ USER_ACTIVITY_LOGS : tracks
    USERS ||--o{ ROUTINES : creates
    ROUTINES ||--o{ ROUTINE_ITEMS : contains
    ACTIVITIES ||--o{ ROUTINE_ITEMS : references
    RESOURCES ||--o{ RESOURCE_REPORTS : receives
    USERS ||--o{ GROUP_MEMBERSHIPS : joins
    GROUPS ||--o{ GROUP_MEMBERSHIPS : contains
    GROUPS ||--o{ COMMUNITY_POSTS : hosts
    USERS ||--o{ COMMUNITY_POSTS : authors
    COMMUNITY_POSTS ||--o{ COMMUNITY_COMMENTS : has
    USERS ||--o{ CONTENT_REPORTS : submits
```

## 10. API plan

Use REST endpoints, validation, consistent errors, pagination, and
FastAPI OpenAPI docs.

| Area | Example endpoints | Access |
|---|---|---|
| Auth | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` | Public registration/login; token rules otherwise |
| Profile | `GET /me`, `PATCH /me/preferences` | Authenticated |
| Mood | `POST /checkins`, `GET /checkins`, `PATCH /checkins/{id}`, `DELETE /checkins/{id}` | Own records |
| Journal | `POST /journal`, `GET /journal`, `PATCH /journal/{id}`, `DELETE /journal/{id}` | Own records |
| Cycle | `POST /cycles`, `GET /cycles`, `PATCH /cycles/{id}`, `DELETE /cycles/{id}` | Own records |
| Symptoms | `POST /symptoms`, `GET /symptoms`, `DELETE /symptoms/{id}` | Own records |
| Academic events | `POST /academic-events`, `GET /academic-events`, `DELETE /academic-events/{id}` | Own records |
| Insights | `GET /insights/weekly`, `/insights/cycle-history`, `/insights/exam-context` | Own data |
| Study planner | `GET /study-plans/current`, `POST /study-plans/generate`, `PATCH /study-plans/items/{id}` | Own data; cycle input requires `planner_cycle_consent_at` |
| Activities | `GET /activities`, `GET /activities/{id}` | Published content |
| Routines | `POST /routines`, `GET /routines`, `POST /routines/{id}/items` | Owner only |
| Resources | `GET /resources` (filter by `category`, `language`), `GET /resources/{id}`, `POST /resources/{id}/report` | Published listings; authenticated reporting |
| Education | `GET /education`, `GET /education/{id}` | Published content |
| AI | `POST /ai/recommendations`, `POST /ai/journal-reflection` | Authenticated; consent for journal |
| Doctor summary | `POST /me/doctor-summary` (date range + categories → PDF) | Authenticated; re-authenticate recommended |
| Groups | `GET /groups`, `POST /groups/{id}/join`, `/groups/{id}/leave` | Authenticated |
| Community | `GET /groups/{id}/posts`, `POST /groups/{id}/posts`, `POST /posts/{id}/comments` | Authorized members |
| Safety | `POST /reports`, `POST /users/{id}/block`, `DELETE /users/{id}/block` | Authenticated |
| Moderation | `GET /moderation/reports`, `PATCH /moderation/reports/{id}`, `PATCH /moderation/posts/{id}` | Moderator only |
| Resources admin | `POST /admin/resources`, `PATCH /admin/resources/{id}`, `GET /admin/resource-reports` | Authorized admin |
| Privacy | `GET /me/export`, `DELETE /me` | Authenticated; re-authenticate for sensitive actions |

Do not trust a client-supplied user ID to determine ownership. Check
group membership, blocking, and moderator permissions on the server.

## 11. Privacy, security, and responsible AI

### Required safeguards

-   Modern password hashing; never plaintext passwords.
-   HTTPS in deployed environments.
-   Short-lived access tokens and a carefully implemented
    refresh/revocation strategy.
-   Platform-appropriate secure token storage on mobile.
-   App lock and screen-privacy options for Discreet Mode.
-   Secrets outside source control and client builds.
-   Validation and rate limits for auth, AI, PDF, and community
    endpoints.
-   Restricted CORS origins for web clients.
-   Parameterized ORM/database access.
-   No sensitive text in analytics or ordinary logs.
-   Explicit consent before external AI processing of journal text.
-   Separate consent for recommendations, journal reflection, and cycle
    data in the study planner.
-   Export and deletion with a documented retention policy.
-   No sharing of identifiable wellness records with colleges.
-   Fictional data for demos.

### Responsible AI

-   Suggestions, not medical advice.
-   No diagnosis, prescription, or prediction of health conditions.
-   Prefer curated activities and reviewed resources.
-   Validate model responses and handle failures safely.
-   Provide human-support pathways for distress or immediate danger.
-   Do not claim to infer a user's mental-health state reliably from
    writing.
-   Disclose AI-provider data processing accurately.
-   Never send cycle records to the AI provider for study planning; the
    planner's logic runs in the backend.

### Menstrual-health safeguards

-   Cycle estimates can be inaccurate.
-   Do not infer causation between stress and cycle changes.
-   No pregnancy/fertility predictions in v1.
-   Do not label users abnormal based on cycle length or symptom scores.
-   Provide reviewed guidance for severe, unusual, persistent, or
    concerning symptoms.
-   Allow users to opt out of cycle tracking.

## 12. Cycle insights and study planner rules

### Cycle insights

1.  Store recorded dates separately from predictions.
2.  Support incomplete records, including a start date without an end
    date.
3.  Estimate only when enough usable history exists; document the
    method.
4.  Clearly label estimates and uncertainty.
5.  Do not infer ovulation, fertility, pregnancy, or a diagnosis.
6.  Present symptom and mood trends as personal observations.
7.  Avoid causal statements about stress, hormones, or symptoms.
8.  Do not send cycle records to AI unless a specific feature needs them
    and the user consents.
9.  Let users delete cycle/symptom records independently of community
    participation.
10. Use the user's local calendar date and time zone for logs/reminders.

### Study planner

1.  The planner is optional and works without cycle data.
2.  Cycle data is used only after a separate, revocable opt-in.
3.  Require a minimum amount of the user's own history (for example,
    several weeks of energy check-ins) before showing pattern-based
    suggestions; otherwise show a simple default plan.
4.  Suggestions are labeled as suggestions and explain which of the
    user's own records they came from.
5.  Never state or imply that a cycle phase causes low energy, poor
    performance, or stress.
6.  Never reduce exam preparation to "go easy"; always include an
    option to keep a normal or focused plan.
7.  Users can accept, edit, or skip each item; skipping has no penalty.
8.  Document the algorithm in `docs/study-planner-rules.md` so it is
    explainable and testable.
9.  Revoking cycle consent immediately removes cycle inputs from future
    plans.

## 13. Safety layer

The Safety Layer shows support options when distress language appears. It
is a gentle prompt, not a detector of mental-health state.

-   **Journal and check-in notes:** a simple phrase check runs **on the
    device**. If triggered, the app offers a card with verified support
    resources and Comfort Mode. No text leaves the device because of
    this check, and nothing is logged.
-   **Community posts:** on submission, the backend may hold a post for
    moderator review if it matches distress phrases, and shows the author
    a supportive message with verified resources. Moderators see only the
    post, not private records.
-   **AI outputs:** responses that mention self-harm or emergencies are
    replaced with a fixed, reviewed message pointing to human help.
-   Users can dismiss the card; nobody is alerted or contacted.
-   Phrase lists and wording are reviewed by someone with relevant
    expertise and documented in `docs/privacy-and-safety.md`.
-   Resources shown must come from verified HelpHub listings; do not
    hard-code unverified numbers.
-   Do not claim the layer finds everyone in distress; state its limits
    in the Privacy Center.

## 14. Community moderation

### Report reasons

-   Harassment or bullying.
-   Hate or discriminatory content.
-   Spam or scams.
-   Unsafe medical claims.
-   Sharing another person's private information.
-   Other guideline violations.

### Workflow

1.  User reports a post/reply.
2.  Backend validates the report and creates a queue item.
3.  Moderator sees relevant reported content---not the reporter's
    private wellness data.
4.  Moderator dismisses, warns, hides/removes content, or suspends an
    account under policy.
5.  Action is recorded with timestamp and moderator ID.
6.  User-facing status is updated where appropriate.

For v1, use text-only posts and replies in pre-seeded groups. Do not
launch unmoderated forums or private messaging.

## 15. Six-week roadmap

### Week 1 --- Foundation

-   Finalize screen flows, schema, and API contract.
-   Set up Flutter (with localization from the start), FastAPI,
    PostgreSQL, migrations, and repository.
-   Implement registration, login, and authenticated profile.
-   Add tests and local development instructions.

**Exit:** a user can sign in and retrieve their own profile; all UI
strings come from localization files.

### Week 2 --- Mood, journal, and Discreet Mode basics

-   Build check-in and private journal screens.
-   Implement create/read/update/delete endpoints.
-   Add history and weekly charts.
-   Add app lock (PIN/biometrics), app-switcher privacy, and neutral
    notification wording.
-   Test ownership with multiple accounts.

**Exit:** private check-ins and journal work end to end, behind an
optional app lock.

### Week 3 --- CycleCare and self-care

-   Implement period/symptom logging.
-   Add cycle history and conservative estimates.
-   Build Comfort Mode, activity library, routines, and favorites.
-   Add academic events.

**Exit:** a user can log a cycle, record symptoms, save a comfort
routine, and enter an exam.

### Week 4 --- Study Planner, insights, and HelpHub

-   Build exam-context insights and the Study Planner (default plan, then
    energy-based suggestions, then optional cycle input).
-   Build HelpHub with source and verification metadata, including
    period-product access points and outdated-info reporting.
-   Add reviewed education content.

**Exit:** a user sees a clearly labeled suggested weekly rhythm and can
find a verified access point.

### Week 5 --- AI, Safety Layer, and community (lite)

-   Implement AI recommendations and consent-based journal reflection;
    validate outputs and add fallbacks.
-   Add the Safety Layer for journal notes, posts, and AI outputs.
-   Add pre-seeded groups, posts, replies, reporting, and the moderation
    queue; enforce moderator permissions.
-   Test inappropriate content and unauthorized access.

**Exit:** AI is optional, the app remains useful without it, and
report-to-moderator-review works.

### Week 6 --- Privacy, summary, cloud, and release

-   Implement export and account deletion.
-   Build the Doctor-visit Summary PDF.
-   Dockerize and deploy backend.
-   Configure HTTPS, secrets, backups, and logging.
-   Add CI and run regression/security tests.
-   Prepare demo data, screenshots, README, and pitch.

**Exit:** a reviewer can verify the main workflows in a stable demo.

### Weeks 7--8, if available

Add Hindi and Marathi content, blocking, and an alternate app icon;
polish accessibility; improve moderation tools; test usability with
non-sensitive scenarios; and improve deployment automation.

**Scope rule:** see [section 5](#5-mvp-scope). If time is short, reduce
community depth and extra languages before compromising privacy/security
or the core workflows.

## 16. Testing and acceptance criteria

### Core

-   Register, sign in, and sign out.
-   Check-ins persist and appear in the correct history.
-   Users can edit/delete their own journal entries.
-   Cycle dates and symptoms can be created, edited, and deleted.
-   Estimates are clearly labeled.
-   Activities/routines can be completed and reviewed.
-   HelpHub shows source and verification metadata.
-   Switching language changes all visible text without errors.

### Study planner

-   Planner works with no cycle data.
-   Cycle inputs are ignored until consent is given and removed after it
    is revoked.
-   With too little history, a default plan appears instead of
    pattern-based suggestions.
-   Suggestions are labeled and can be accepted, edited, or skipped.
-   No planner text contains causal claims about cycle and performance.

### Privacy/security

-   Account A cannot read or modify Account B's records.
-   Journal reflection cannot run without consent.
-   Secrets and journal text do not appear in logs.
-   Account deletion handles associated data under policy.
-   Moderator endpoints reject unauthorized users.
-   Blocking/reporting is enforced server-side.
-   App lock prevents access after backgrounding; notification text
    contains no sensitive terms.
-   Doctor-visit Summary contains only selected categories and only the
    requesting user's data; no PDF persists after delivery.
-   Safety events store no message text.

### AI/community

-   AI failures produce a useful fallback.
-   AI output does not present diagnoses as facts.
-   Distress-related AI output is replaced by the fixed support message.
-   Users can report inappropriate content.
-   Moderators can review and act on reports.
-   Blocking restrictions cannot be bypassed through another endpoint.
-   Community features never expose private cycle, mood, or journal
    data.

### Release

-   Deployed API uses HTTPS.
-   Migrations run reproducibly.
-   Core tests run in CI.
-   Backup/recovery steps are documented.
-   A new tester can follow the README on a clean environment.

## 17. Local setup

Commands below describe the intended workflow; adapt them to the
implementation as it is created.

### Prerequisites

-   Flutter SDK and Dart.
-   Python version supported by the chosen FastAPI dependencies.
-   PostgreSQL or Docker.
-   Git.
-   Optional AI provider account for AI testing.
-   AWS credentials only for deployment.

### Clone and configure

``` bash
git clone <your-repository-url>
cd bloomwell
cp .env.example .env
```

Fill in local values. Never commit `.env`.

### Start infrastructure

If `docker-compose.yml` exists:

``` bash
docker compose up -d
```

### Start backend

``` bash
cd backend
python -m venv .venv
```

Activate the virtual environment.

Linux/macOS:

``` bash
source .venv/bin/activate
```

Windows PowerShell:

``` powershell
.venv\Scripts\Activate.ps1
```

Then:

``` bash
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

Local API docs: `http://127.0.0.1:8000/docs`

### Start Flutter

In another terminal:

``` bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run
```

Configure the API base URL for the selected emulator/device. `localhost`
inside a mobile emulator may not refer to the developer's computer.

### Run tests

``` bash
cd backend
pytest
```

``` bash
cd mobile
flutter test
```

Add linting and formatting commands to CI when project configuration is
finalized.

## 18. Environment variables

Create `.env.example` with placeholders only; variable names must match
the implementation.

``` dotenv
APP_ENV=development
APP_SECRET_KEY=replace-with-local-development-secret
DATABASE_URL=postgresql+psycopg://bloomwell:change-me@localhost:5432/bloomwell

ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

AI_PROVIDER=disabled
AI_API_KEY=
AI_MODEL=

DEFAULT_LANGUAGE=en
SUPPORTED_LANGUAGES=en,hi,mr
PDF_TEMP_DIR=/tmp/bloomwell-pdf

CORS_ORIGINS=http://localhost:3000
LOG_LEVEL=INFO
```

Never use example credentials in production. Generate strong secrets and
use protected deployment configuration or a secret manager. Verify
provider terms before enabling AI.

## 19. Deployment

1.  Build and test FastAPI.
2.  Build a Docker image.
3.  Deploy to AWS EC2 or another suitable cloud runtime.
4.  Use secured PostgreSQL with restricted network access.
5.  Configure HTTPS and a stable endpoint.
6.  Store secrets outside the image/repository.
7.  Configure backups and test restoration.
8.  Add health checks, error logging, and basic monitoring.
9.  Run migrations as a controlled release step.
10. Configure GitHub Actions for tests on pull requests and main.

A single modular API and secured database are enough for v1. Avoid
unnecessary infrastructure complexity.

## 20. Hackathon demo

A three-minute demo using synthetic data:

1.  Open the app behind the app lock; show neutral notification text.
2.  Create a mood/stress/energy check-in.
3.  Record a fictional period and symptom history.
4.  Add a fictional exam and show the **Study Planner's** suggested
    week, with the "why" explained and cycle input optional.
5.  Show a personal insight with uncertainty explained.
6.  Save and complete a comfort activity.
7.  Demonstrate AI reflection with fictional text and explicit consent;
    show the support card for a fictional distress phrase.
8.  Find a verified campus resource and a period-product access point.
9.  Generate a **Doctor-visit Summary** PDF from fictional data.
10. Publish a fictional community post, report another post, and show
    moderation.
11. Demonstrate that one test account cannot access another's private
    data, and that a moderator account cannot see journals.
12. Switch the app language to show localization.

Use synthetic data. Do not collect real menstrual or journal data from
judges or participants.

## 21. Future scope

After the MVP is stable:

-   Hindi and Marathi content reviewed by fluent readers; more
    languages and accessibility improvements.
-   Optional on-device storage or end-to-end encryption for journals,
    with a clear explanation of trade-offs (such as recovery on a new
    device).
-   Discreet local notifications and alternate app icons across
    platforms.
-   Carefully designed offline access.
-   Richer cycle-history visualizations.
-   Campus resource partnerships and verified access-point networks.
-   Anonymous, moderated peer product-sharing requests within a campus.
-   Aggregated, anonymized, threshold-based campus insights (for example,
    only when a large number of students contribute) with privacy
    review and no individual data shared.
-   Moderated group events or peer-support sessions.
-   Clinically reviewed "worth mentioning to a doctor" guidance.
-   Improved moderation and export tools.
-   Independent security/privacy review.

Do not add fertility predictions, clinical screening, or health-outcome
claims without appropriate expertise, validation, and regulatory review.

## 22. Success metrics and disclaimer

### Engineering metrics

-   Core API test pass rate.
-   Unauthorized-access test results.
-   API availability/error rate during demo.
-   Completion of the main end-to-end workflow.
-   Reproducible setup and deployment.

### Product metrics

-   Percentage of testers completing check-in → activity.
-   Percentage of testers who understand why a study-planner suggestion
    was made.
-   Usability feedback, including on Discreet Mode and language clarity.
-   Voluntary activity helpfulness ratings.
-   Successful support-resource and access-point discovery.
-   Share of testers who can generate and understand a Doctor-visit
    Summary.
-   User understanding of privacy and AI consent.

Do not claim improved mental-health outcomes from a small hackathon
demo. Mood scores are personal records, not a product-success metric by
themselves.

### Disclaimer

BloomWell is an educational and wellness companion. It does not
diagnose, treat, or prevent medical conditions, and cycle estimates and
study-planner suggestions are not guaranteed. Menstrual-health content
should come from reviewed, trustworthy sources. Users with severe,
unusual, persistent, or concerning symptoms should seek advice from a
qualified healthcare professional. For immediate danger or emergencies,
use appropriate local emergency services.

**Build philosophy:** protect users first, finish one end-to-end
workflow, and add complexity only when it strengthens the product.
