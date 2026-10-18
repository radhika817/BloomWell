import base64
import json
from typing import Any, Dict, Optional


def encode_cursor(data: Dict[str, Any]) -> str:
    """Encode a dictionary to a base64 URL-safe cursor string."""
    json_bytes = json.dumps(data, sort_keys=True).encode("utf-8")
    return base64.urlsafe_b64encode(json_bytes).decode("ascii")


def decode_cursor(cursor: Optional[str]) -> Optional[Dict[str, Any]]:
    """Decode a base64 URL-safe cursor string into a dictionary.
    Returns None if empty, invalid base64, or invalid JSON.
    """
    if not cursor:
        return None
    try:
        json_bytes = base64.urlsafe_b64decode(cursor.encode("ascii"))
        data = json.loads(json_bytes.decode("utf-8"))
        if isinstance(data, dict):
            return data
        return None
    except Exception:
        return None
