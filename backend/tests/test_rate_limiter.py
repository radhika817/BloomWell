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


def test_rate_limiter_ignores_spoofed_forwarded_for_from_untrusted_source():
    """Verify that X-Forwarded-For is ignored when the immediate client is not a trusted proxy."""
    app = FastAPI()
    # 2 requests per 60s, trusted proxy configured as 10.0.0.1
    limiter = rate_limit(max_requests=2, window_seconds=60, trusted_proxies=["10.0.0.1"])

    @app.get("/api-test", dependencies=[Depends(limiter)])
    def test_ep():
        return {"status": "ok"}

    # Attacker connects from untrusted IP 198.51.100.5
    client = TestClient(app, client=("198.51.100.5", 50000))

    # Attacker tries to spoof different client IPs using X-Forwarded-For
    r1 = client.get("/api-test", headers={"X-Forwarded-For": "203.0.113.1"})
    assert r1.status_code == 200

    r2 = client.get("/api-test", headers={"X-Forwarded-For": "203.0.113.2"})
    assert r2.status_code == 200

    # Third request from the same untrusted socket is blocked, despite different spoofed header
    r3 = client.get("/api-test", headers={"X-Forwarded-For": "203.0.113.3"})
    assert r3.status_code == 429


def test_rate_limiter_honors_forwarded_for_from_trusted_proxy():
    """Verify that X-Forwarded-For is honored when requests originate from a trusted proxy."""
    app = FastAPI()
    limiter = rate_limit(max_requests=2, window_seconds=60, trusted_proxies=["10.0.0.1"])

    @app.get("/proxy-test", dependencies=[Depends(limiter)])
    def test_ep():
        return {"status": "ok"}

    # Reverse proxy connects from trusted IP 10.0.0.1
    proxy_client = TestClient(app, client=("10.0.0.1", 50000))

    # Requests on behalf of User A (203.0.113.10)
    assert proxy_client.get("/proxy-test", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 200
    assert proxy_client.get("/proxy-test", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 200
    # Third request for User A is rate limited
    assert proxy_client.get("/proxy-test", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 429


def test_rate_limiter_separates_limits_for_different_client_ips_behind_proxy():
    """Verify two different client IPs behind the same trusted proxy receive separate limits."""
    app = FastAPI()
    limiter = rate_limit(max_requests=2, window_seconds=60, trusted_proxies=["10.0.0.1"])

    @app.get("/multi-client", dependencies=[Depends(limiter)])
    def test_ep():
        return {"status": "ok"}

    proxy_client = TestClient(app, client=("10.0.0.1", 50000))

    # User A exhausts their 2 requests
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 200
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 200
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.10"}).status_code == 429

    # User B arrives from the same proxy: should still have full quota
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.20"}).status_code == 200
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.20"}).status_code == 200
    # User B third request is now rate limited
    assert proxy_client.get("/multi-client", headers={"X-Forwarded-For": "203.0.113.20"}).status_code == 429
