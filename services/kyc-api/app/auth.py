"""Shared auth helpers (duplicated from payments-api — known tech debt)."""
import os
from datetime import datetime, timedelta
from functools import wraps

import jwt
from jwt import ExpiredSignatureError, InvalidTokenError
from flask import request, jsonify


# ---------------------------
# JWT RS256 WITH KEY ROTATION
# ---------------------------

# Load active private key for signing
with open(os.environ["JWT_PRIVATE_KEY_PATH"], "r") as f:
    JWT_PRIVATE_KEY = f.read()

# Load all public keys for verification
def load_public_keys():
    return {
        "kid1": open(os.environ["JWT_PUBLIC_KEY_PATH"], "r").read()
    }

JWT_PUBLIC_KEYS = load_public_keys()
JWT_ALGORITHM = "RS256"
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

    headers = {"kid": "kid1"}  # active key ID
    return jwt.encode(payload, JWT_PRIVATE_KEY, algorithm="RS256", headers=headers)


def decode_token(token: str) -> dict:
    """Decode and verify a JWT with key rotation."""
    header = jwt.get_unverified_header(token)
    kid = header.get("kid")

    public_key = JWT_PUBLIC_KEYS.get(kid)
    if not public_key:
        raise InvalidTokenError("Unknown key ID")

    return jwt.decode(
        token,
        public_key,
        algorithms=["RS256"],
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


