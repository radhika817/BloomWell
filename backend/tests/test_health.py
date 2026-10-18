from fastapi.testclient import TestClient
from app.db.session import get_db
from app.main import app


def test_health_check_healthy(client: TestClient):
    """Test that GET /health returns 200 with healthy database status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"
    # Ensure no internal hostnames or sensitive details leak
    assert "postgresql" not in response.text.lower()
    assert "password" not in response.text.lower()


def test_health_check_db_failure(client: TestClient):
    """Test that GET /health returns 503 without leaking credentials when DB is unavailable."""
    class BrokenDBSession:
        def execute(self, *args, **kwargs):
            raise RuntimeError("Simulated connection timeout")

    def broken_db():
        yield BrokenDBSession()

    app.dependency_overrides[get_db] = broken_db
    try:
        response = client.get("/health")
        assert response.status_code == 503
        data = response.json()
        assert data["code"] == "HTTP_503"
        assert "Database connectivity unavailable." in data["message"]
        # Ensure no stack trace or credentials leak in error response
        assert "Simulated connection timeout" not in response.text
        assert "password" not in response.text.lower()
    finally:
        app.dependency_overrides.clear()
