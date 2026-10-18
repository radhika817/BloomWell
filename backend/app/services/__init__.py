"""
Services layer package.

Architectural Rules (docs/architecture.md Section 5):
1. Services contain business logic and domain workflows; zero HTTP or routing concerns.
2. ModerationService and CommunityService MUST NEVER import private repositories.
3. Services return domain objects; Pydantic schemas live at the API boundary.
"""
