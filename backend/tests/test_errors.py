import uuid
from fastapi.testclient import TestClient


def test_error_format_404_not_found(client: TestClient):
    """Test that 404 responses conform to the consistent JSON error shape."""
    response = client.get("/v1/non-existent-route")
    assert response.status_code == 404
    data = response.json()

    assert "code" in data
    assert "message" in data
    assert "details" in data
    assert "request_id" in data
    assert data["code"] == "HTTP_404"
    assert data["message"] == "Not Found"
    assert data["request_id"] is not None


def test_request_id_middleware_generated(client: TestClient):
    """Test that an X-Request-ID header is generated if not provided."""
    response = client.get("/health")
    assert response.status_code == 200
    assert "X-Request-ID" in response.headers
    generated_id = response.headers["X-Request-ID"]
    # Verify it is a valid UUID
    uuid_obj = uuid.UUID(generated_id)
    assert str(uuid_obj) == generated_id


def test_request_id_middleware_propagated(client: TestClient):
    """Test that a caller-provided X-Request-ID is preserved and echoed."""
    custom_id = "custom-trace-id-12345"
    response = client.get("/health", headers={"X-Request-ID": custom_id})
    assert response.status_code == 200
    assert response.headers.get("X-Request-ID") == custom_id


def test_error_response_contains_matching_request_id(client: TestClient):
    """Test that error responses include the matching request_id in the JSON body."""
    custom_id = "test-error-trace-999"
    response = client.get("/v1/missing-path", headers={"X-Request-ID": custom_id})
    assert response.status_code == 404
    assert response.headers.get("X-Request-ID") == custom_id
    data = response.json()
    assert data["request_id"] == custom_id
