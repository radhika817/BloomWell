# BloomWell Study Planner Rules 🌸

This document describes the deterministic study planning algorithm used by BloomWell to generate balanced, supportive weekly study rhythms for students.

---

## 1. Principles and Core Philosophy

- **Suggestions, Not Predictions:** The planner offers suggested study blocks and rest breaks based strictly on what the user recorded. It never claims to predict energy or outcomes.
- **Observations, Never Causation:** Suggestions reflect historical patterns (for example, "You logged lower energy on several Tuesdays"). The system never asserts why (no claims that periods or stress caused changes).
- **Non-Diagnostic & Educational Tone:** The planner contains zero medical claims, diagnostic statements, or clinical terminology.
- **Privacy and Consent Isolation:** Cycle records are evaluated only with explicit, separate, revocable consent (`planner_cycle_consent_at`) while cycle tracking is active. The planner operates fully without cycle data using check-in energy alone.
- **100% Deterministic & Local:** Running entirely within the backend service with zero AI models and zero external network calls.
- **Autonomy and Flexibility:** The user can accept, edit, or skip any suggestion without penalty. An option to keep a normal or focused study load is always preserved.

---

## 2. Inputs

The algorithm takes the following inputs:
1. **Week Window:** The 7 calendar dates starting from `week_start`.
2. **Energy History:** Daily average energy scores from mood check-ins across the 28 days immediately preceding `week_start`.
3. **Academic Events:** Student-entered exams and assignment deadlines falling between `week_start` and 14 days after the plan week ends.
4. **Recorded Cycle Days (Optional):** Start and end dates from the user's last up to 6 recorded cycles, accessed only when consented.
5. **Break Activity Catalog:** Curated, published study-break activities from Self-Care Studio, including user favorites.

---

## 3. Algorithm Step-by-Step

### Step 1: Mode Determination (14-Day History Threshold)
- If the user has logged check-ins on **fewer than 14 distinct days** in the past 28 days:
  - **Mode:** `default`.
  - All days are assigned a `normal` study load with reason code `NOT_ENOUGH_HISTORY`.
  - **Exam Prep Rule:** For each entered exam, days 2 through 5 before the exam are designated as `focus` load (`EVENT_PREP`). The exam day itself is `normal` load (`EVENT_DAY`).
- If the user has logged check-ins on **14 or more distinct days** in the past 28 days:
  - **Mode:** `personalized`. Proceed to Step 2.

### Step 2: Personalized Energy Pattern Analysis
1. Calculate the mean and sample standard deviation (SD) of the user's daily energy check-ins.
2. **Low Variability Check:** If the standard deviation is **below 0.5**, daily energy differences are too small to represent a meaningful pattern. Every day defaults to a `normal` load (`DEFAULT_PLAN`).
3. **Weekday Energy Baselines:** When SD is **0.5 or greater**, group energy check-ins by day of the week (Monday through Sunday):
   - **Fewer than 2 samples for a weekday:** Insufficient weekday history; assign `normal` load (`DEFAULT_PLAN`).
   - **2 or more samples for a weekday:**
     - If weekday average is more than **0.5 SD below the overall mean**: assign `light` load (`WEEKDAY_ENERGY_LOWER`).
     - If weekday average is more than **0.5 SD above the overall mean**: assign `focus` load (`WEEKDAY_ENERGY_HIGHER`).
     - Otherwise: assign `normal` load (`DEFAULT_PLAN`).

### Step 3: Consented Cycle Adjustment
Cycle records are evaluated **only** when `planner_cycle_consent_at` is active and cycle tracking is enabled:
1. Look back at the user's last up to 6 recorded periods. Period days cover recorded start through recorded end (if end date was not logged, days start through start + 4 are used).
2. **Qualification Thresholds:**
   - Must have at least **3 recorded periods**.
   - Must have at least **6 period-day energy check-ins**.
   - The user's average energy on period days must be at least **0.7 points lower** than on non-period days.
3. **Adjustment:** For any date in the 7-day plan that coincides with a **currently recorded period day**:
   - The suggested load moves one step lighter: `focus` becomes `normal`; `normal` becomes `light`.
   - The reason code `CYCLE_RECORDED_PERIOD_LOW_ENERGY` is appended.
4. **Estimated Dates Never Used:** Adjustments apply strictly to recorded dates, never to estimated or projected dates.
5. **Tracking Flag:** `uses_cycle_data` is marked `true` only when this check was evaluated with consent.

### Step 4: Exam Constraints (Applied Last)
Academic priorities always take precedence to ensure preparation options are preserved:
1. **Three-Day Light Stretch Prevention:** In the 7 days leading up to an academic event, no consecutive 3-day window may be entirely `light`. If a 3-day stretch would be all `light`, the day with the highest historical energy baseline in that stretch is upgraded to `normal` with reason code `KEEP_OPTION_PRESERVED`.
2. **Exam Day Protection:** The day of an academic event is never `light`. If it was classified as `light`, it is raised to `normal` with reason code `EVENT_DAY`.

### Step 5: Study Break Rotation
Each planned day is assigned a restorative activity:
1. Filter the curated catalog for published activities in the `study_break` category.
2. Prioritize user favorites while maintaining deterministic alphabetical / ID ordering.
3. Rotate activities so that consecutive days never receive the same activity.
4. If no published study break activities exist, `activity_id` remains `null`.

---

## 4. Reason Codes Reference

Every planned item contains standardized, language-neutral reason codes. The mobile client localizes these codes into supportive, natural sentences:

| Reason Code | Meaning |
|---|---|
| `NOT_ENOUGH_HISTORY` | General plan assigned because fewer than 14 check-in days were recorded in the past 4 weeks. |
| `DEFAULT_PLAN` | Balanced normal study load assigned for days with typical energy or small variations. |
| `WEEKDAY_ENERGY_HIGHER` | Higher study load suggested because the user historically logged higher energy on this weekday. |
| `WEEKDAY_ENERGY_LOWER` | Lighter study load suggested because the user historically logged lower energy on this weekday. |
| `CYCLE_RECORDED_PERIOD_LOW_ENERGY` | Lighter load suggested because the day coincides with a recorded period where historical energy was lower. |
| `EVENT_PREP` | Focused study block suggested in preparation for an upcoming exam or deadline. |
| `EVENT_DAY` | Balanced study load assigned for the day of an academic event. |
| `KEEP_OPTION_PRESERVED` | Study load raised from light to normal to prevent three consecutive light days before an exam. |
