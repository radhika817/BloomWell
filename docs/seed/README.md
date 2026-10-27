# BloomWell HelpHub Resource Seed Data Format

This directory contains seed files for verified campus and community resources in the HelpHub directory.

## Files

- `resources.demo.json`: Curated **purely fictional demo entries** for local development, automated testing, and demonstrations. All entries are flagged `"is_demo": true` with `example.org` placeholder URLs and fictional names marked `(Demo)`. No real-world contact numbers or locations are included.
- `resources.json`: Real-world verified resources to be supplied and maintained by administrators. Every real resource entry must be thoroughly checked against official published campus, government, or NGO documentation before entry.

## Schema & Validation Rules for Real Entries

Every entry in `resources.json` must adhere strictly to the following JSON schema:

```json
{
  "name": "Official Campus Counseling Center",
  "category": "counseling",
  "description": "Confidential, free psychological counseling services provided on campus for registered students.",
  "phone": "+91-20-00000000",
  "email": "counseling@campus.ac.in",
  "website_url": "https://campus.ac.in/counseling",
  "address": "Building 4, Room 202, North Campus",
  "city": "Pune",
  "hours_text": "Monday to Friday: 9:00 AM - 5:00 PM",
  "available_24x7": false,
  "languages": ["en", "hi", "mr"],
  "cost": "free",
  "product_details": null,
  "source_url": "https://campus.ac.in/student-welfare/counseling-services",
  "verification_status": "verified",
  "last_verified_at": "2026-10-01",
  "verified_by": "Radhika (Student Welfare Lead)",
  "is_published": true,
  "is_demo": false
}
```

### Strict Domain Constraints for Real Entries
1. **Mandatory Verification for Published Entries:**
   If `"is_published": true` and `"is_demo": false`, the entry **MUST** have:
   - `"verification_status": "verified"`
   - `"source_url"`: Official http(s) URL where the service is publicly documented
   - `"last_verified_at"`: Valid ISO date (`YYYY-MM-DD`) within the last 180 days
2. **24x7 Availability Rule:**
   `"available_24x7": true` is strictly permitted only if `"verification_status": "verified"` and `"source_url"` is provided.
3. **Period Products:**
   If `"category": "period_products"`, `"product_details"` may contain a structured dictionary:
   ```json
   {
     "items": ["pads", "disposal_bags"],
     "free_or_paid": "free",
     "how_to_access": "Located inside restroom vestibule next to Room 101"
   }
   ```
4. **Valid Enums:**
   - `category`: `counseling`, `helpline`, `welfare_office`, `period_products`, `ngo`, `health_clinic`, `workshop`
   - `cost`: `free`, `paid`, `unknown`
   - `verification_status`: `unverified`, `verified`, `outdated`
