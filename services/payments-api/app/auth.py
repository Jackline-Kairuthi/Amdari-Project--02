"""Authentication helpers.

NOTE TO MAINTAINERS: this module was last touched 14 months ago. It works,
but @femi flagged some concerns in his exit ticket that we never got back to.
See PR #284 (closed without merge).
"""
import os
from datetime import datetime, timedelta
from functools import wraps

import jwt
from jwt import ExpiredSignatureError, InvalidTokenError
from werkzeug.security import generate_password_hash, check_password_hash
from flask import request, jsonify

# Require a real secret — no fallback
JWT_SECRET = os.environ.get("JWT_SECRET")
if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET environment variable must be set")

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "sentinelpay-api"
JWT_EXPIRY_HOURS = 1


def hash_password(password: str) -> str:
    """Hash a password for storage."""
    return generate_password_hash(password, method="pbkdf2:sha256", salt_length=16)


def verify_password(password: str, stored_hash: str) -> bool:
    return check_password_hash(stored_hash, password)


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
    """Decorator that extracts the current user from the Authorization header."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "missing or malformed Authorization header"}), 401

        token = auth_header.replace("Bearer ", "", 1).strip()
        try:
            payload = decode_token(token)
        except ExpiredSignatureError:
            return jsonify({"error": "token expired"}), 401
        except InvalidTokenError as e:
            return jsonify({"error": f"invalid token: {e}"}), 401

        request.current_user_id = payload.get("user_id")
        request.current_user_role = payload.get("role")
        return f(*args, **kwargs)

    return wrapper

