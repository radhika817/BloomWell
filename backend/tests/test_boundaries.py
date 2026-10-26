import ast
from pathlib import Path
import pytest


def test_moderation_and_community_import_boundaries():
    """
    CRITICAL ARCHITECTURAL BOUNDARY RULE (AGENTS.md Rule 6 & docs/architecture.md Section 5):
    ModerationService and CommunityService (and all moderation/community modules)
    must NEVER import private repositories (CheckinRepository, JournalRepository).
    This guarantees that moderators cannot access private wellness records by structural design.
    """
    backend_app_dir = Path(__file__).resolve().parent.parent / "app"
    assert backend_app_dir.is_dir(), f"Cannot find app directory: {backend_app_dir}"

    forbidden_symbols = {
        "CheckinRepository",
        "JournalRepository",
        "StudyPlanRepository",
        "MoodCheckin",
        "JournalEntry",
        "StudyPlan",
        "StudyPlanItem",
        "CycleLog",
    }
    forbidden_modules = {
        "app.repositories.checkin_repository",
        "app.repositories.journal_repository",
        "app.repositories.study_plan_repository",
        "app.models.checkin",
        "app.models.journal",
        "app.models.study_plan",
        "app.models.cycle",
    }

    # Find all moderation and community related files
    python_files = list(backend_app_dir.rglob("*.py"))
    boundary_targets = [
        f for f in python_files
        if "moderation" in f.name.lower() or "community" in f.name.lower()
    ]

    violations = []
    for target in boundary_targets:
        tree = ast.parse(target.read_text(encoding="utf-8"), filename=str(target))
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    if alias.name in forbidden_modules or alias.name in forbidden_symbols:
                        violations.append(f"{target.name}: imports forbidden '{alias.name}'")
            elif isinstance(node, ast.ImportFrom):
                mod = node.module or ""
                if mod in forbidden_modules:
                    violations.append(f"{target.name}: imports from forbidden '{mod}'")
                for alias in node.names:
                    if alias.name in forbidden_symbols:
                        violations.append(f"{target.name}: imports forbidden symbol '{alias.name}' from '{mod}'")

    assert not violations, f"Architectural boundary violations found:\n" + "\n".join(violations)


def test_private_repositories_require_user_id_scoping():
    """
    CRITICAL RULE (AGENTS.md Rule 5):
    Every private-data repository method must take an explicit user_id and filter by it.
    The client never supplies the owner ID.
    """
    from app.repositories.checkin_repository import CheckinRepository
    from app.repositories.journal_repository import JournalRepository
    from app.repositories.study_plan_repository import StudyPlanRepository
    import inspect

    for repo_cls in [CheckinRepository, JournalRepository, StudyPlanRepository]:
        methods = [
            m for m in inspect.getmembers(repo_cls, predicate=inspect.isfunction)
            if not m[0].startswith("_")
        ]
        for name, func in methods:
            sig = inspect.signature(func)
            params = list(sig.parameters.keys())
            assert "user_id" in params, (
                f"Private repository method '{repo_cls.__name__}.{name}' is missing mandatory 'user_id' parameter!"
            )
