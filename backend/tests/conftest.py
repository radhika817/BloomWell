import os
from typing import Generator
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

# Ensure test configuration is active
os.environ["APP_ENV"] = "test"
os.environ["APP_SECRET_KEY"] = "test-secret-key-for-unit-testing-min-32-chars"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

from app.db.base import Base
from app.db.session import get_db
from app.main import app

# In-memory SQLite engine for fast, isolated test execution
test_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)


from sqlalchemy import event


@event.listens_for(test_engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=test_engine,
)


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """Create all tables in the test database schema for the test session."""
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Provide a transactional database session rolled back after every test."""
    connection = test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    """Provide a FastAPI TestClient with the database dependency overridden."""
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_rate_limiters():
    """Reset rate limiter buckets before each test for test isolation."""
    from app.api.v1.auth import (
        login_email_limiter,
        login_ip_limiter,
        refresh_rate_limiter,
        register_rate_limiter,
    )

    register_rate_limiter._records.clear()
    refresh_rate_limiter._records.clear()
    login_ip_limiter._records.clear()
    login_email_limiter._records.clear()
    yield
