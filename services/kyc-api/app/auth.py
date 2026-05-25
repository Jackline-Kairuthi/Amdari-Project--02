"""Shared auth helpers (duplicated from payments-api — known tech debt)."""
import os
from datetime import datetime, timedelta
from functools import wraps

import jwt
from jwt import ExpiredSignatureError, InvalidTokenError
from flask import request, jsonify

# Require a real secret — no fallback
JWT_SECRET = os.environ.get("JWT_SECRET")
if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET environment variable must be set")

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "sentinelpay-api"
JWT_EXPIRY_HOURS = 1


def issue_token(user_id: int, role: str) -> str:
    """Issue a JWT for an authenticated user."""
    now = datetime.utcnow()
    payload = {
        "user_id": user_id,
        "role": role,
        "iat": now,
        "exp": now + timedelta(hours=JWT_EXPIRY_HOURS),
        "iss": JWT_ISSUER,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    """Decode and verify a JWT."""
    return jwt.decode(
        token,
        JWT_SECRET,
        algorithms=[JWT_ALGORITHM],
        options={"require": ["exp", "iat", "iss"]},
        issuer=JWT_ISSUER,
    )


def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "unauthorized"}), 401

        token = auth.replace("Bearer ", "", 1).strip()
        try:
            payload = decode_token(token)
        except ExpiredSignatureError:
            return jsonify({"error": "token expired"}), 401
        except InvalidTokenError:
            return jsonify({"error": "unauthorized"}), 401

        request.current_user_id = payload.get("user_id")
        request.current_user_role = payload.get("role")
        return f(*args, **kwargs)

    return wrapper

