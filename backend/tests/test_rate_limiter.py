from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from app.core.security import rate_limit


def test_in_memory_rate_limiter():
    """Verify that the in-memory rate limiter enforces request limits per client."""
    app = FastAPI()

    # Configure a tight rate limit for testing: 2 requests per 60s
    limiter = rate_limit(max_requests=2, window_seconds=60)

    @app.get("/limited", dependencies=[Depends(limiter)])
    def limited_endpoint():
        return {"status": "ok"}

    client = TestClient(app)

    # First request: 200 OK
    resp1 = client.get("/limited")
    assert resp1.status_code == 200

    # Second request: 200 OK
    resp2 = client.get("/limited")
    assert resp2.status_code == 200

    # Third request: 429 Too Many Requests
    resp3 = client.get("/limited")
    assert resp3.status_code == 429
    assert resp3.json()["detail"] == "Rate limit exceeded. Please try again later."
    assert "Retry-After" in resp3.headers
