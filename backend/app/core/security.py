import time
from collections import defaultdict
from typing import Callable, Dict, List
from fastapi import HTTPException, Request, status


class InMemoryRateLimiter:
    """
    Simple sliding-window in-memory rate limiter.

    ARCHITECTURAL NOTE:
    This rate limiter operates in-memory and is strictly per-process.
    If the API is scaled out horizontally across multiple processes or container instances
    (e.g., multiple uvicorn workers or ECS/EC2 instances behind a load balancer),
    this implementation must be replaced or augmented with a centralized distributed store
    (such as Redis) to synchronize rate limits across workers.
    """

    def __init__(self, max_requests: int = 60, window_seconds: int = 60) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._records: Dict[str, List[float]] = defaultdict(list)

    def _get_client_key(self, request: Request) -> str:
        """Derive client identifier from request (client host IP or forwarded header)."""
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        if request.client and request.client.host:
            return request.client.host
        return "unknown"

    async def __call__(self, request: Request) -> None:
        """Check whether the client request is within the allowed rate limit."""
        client_key = self._get_client_key(request)
        now = time.time()
        window_start = now - self.window_seconds

        # Filter out timestamps older than the sliding window
        valid_timestamps = [
            ts for ts in self._records[client_key] if ts > window_start
        ]
        self._records[client_key] = valid_timestamps

        if len(valid_timestamps) >= self.max_requests:
            retry_after = int(window_start + self.window_seconds - valid_timestamps[0]) + 1
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Please try again later.",
                headers={"Retry-After": str(max(1, retry_after))},
            )

        self._records[client_key].append(now)


def rate_limit(max_requests: int = 60, window_seconds: int = 60) -> Callable:
    """Dependency factory for rate limiting routes."""
    return InMemoryRateLimiter(max_requests=max_requests, window_seconds=window_seconds)
