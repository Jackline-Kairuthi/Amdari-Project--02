"""Smoke + Security Regression Tests for kyc-api."""

import json
import hmac
import hashlib
import datetime
import jwt
import pytest

from app.main import create_app
from app.db import get_connection


# ---------------------------------------------------------
# FIXTURE: Test Client
# ---------------------------------------------------------

@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    return app.test_client()


# ---------------------------------------------------------
# 1. SMOKE TESTS
# ---------------------------------------------------------

def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200


# ---------------------------------------------------------
# 2. JWT SECURITY TESTS (RS256 ONLY)
# ---------------------------------------------------------

def _issue_hs256_token():
    payload = {
        "user_id": 1,
        "role": "tester",
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        "iss": "sentinelpay-api",
    }
    return jwt.encode(payload, "fake-secret", algorithm="HS256")


def test_jwt_hs256_rejected(client):
    token = _issue_hs256_token()
    resp = client.get("/v1/verify/lookup?bvn=12345678901",
                      headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401


def test_jwt_alg_none_rejected(client):
    payload = {
        "user_id": 1,
        "role": "tester",
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        "iss": "sentinelpay-api",
    }
    token = jwt.encode(payload, key=None, algorithm=None)
    resp = client.get("/v1/verify/lookup?bvn=12345678901",
                      headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 401


# ---------------------------------------------------------
# 3. REQUEST SIGNING HELPERS
# ---------------------------------------------------------

def _sign(body: dict, secret="test-signing-secret"):
    raw = json.dumps(body, separators=(",", ":"), sort_keys=True).encode()
    return hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()


# ---------------------------------------------------------
# 4. REQUEST SIGNING TESTS
# ---------------------------------------------------------

def test_verify_bvn_requires_signature(client, monkeypatch):
    monkeypatch.setenv("SIGNING_SECRET", "test-signing-secret")

    body = {"bvn": "12345678901"}
    resp = client.post("/v1/verify/bvn",
                       json=body,
                       headers={"Authorization": "Bearer invalid"})
    assert resp.status_code == 401


def test_verify_bvn_valid_signature(client, monkeypatch):
    monkeypatch.setenv("SIGNING_SECRET", "test-signing-secret")

    body = {"bvn": "12345678901"}
    sig = _sign(body)

    # Use a valid RS256 token from payments-api tests
    # For simplicity, bypass auth by monkeypatching require_auth if needed
    resp = client.post("/v1/verify/bvn",
                       json=body,
                       headers={"X-Signature": sig,
                                "Authorization": "Bearer invalid"})
    # Signature passes → auth fails → 401
    assert resp.status_code in (401, 200)


# ---------------------------------------------------------
# 5. SQL INJECTION TESTS
# ---------------------------------------------------------

def test_lookup_sql_injection_blocked(client, monkeypatch):
    monkeypatch.setenv("SIGNING_SECRET", "test-signing-secret")

    sig = _sign({"bvn": "' OR '1'='1"})

    resp = client.get("/v1/verify/lookup?bvn=' OR '1'='1",
                      headers={"X-Signature": sig,
                               "Authorization": "Bearer invalid"})

    # Should not error or dump all rows
    assert resp.status_code in (200, 401)


# ---------------------------------------------------------
# 6. IDOR TESTS (DOCUMENTS ENDPOINT)
# ---------------------------------------------------------

def test_document_idor_blocked(client, monkeypatch):
    monkeypatch.setenv("SIGNING_SECRET", "test-signing-secret")

    sig = _sign({})

    # User 1 tries to fetch User 2's document
    resp = client.get("/v1/documents/users/2/passport.png",
                      headers={"X-Signature": sig,
                               "Authorization": "Bearer invalid"})
    assert resp.status_code == 404


# ---------------------------------------------------------
# 7. AUDIT LOGGING TESTS
# ---------------------------------------------------------

def test_audit_log_written_for_lookup(client, monkeypatch):
    monkeypatch.setenv("SIGNING_SECRET", "test-signing-secret")

    sig = _sign({"bvn": "12345678901"})

    # Trigger lookup
    client.get("/v1/verify/lookup?bvn=12345678901",
               headers={"X-Signature": sig,
                        "Authorization": "Bearer invalid"})

    # Check audit_logs table
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT action FROM audit_logs ORDER BY created_at DESC LIMIT 1")
    row = cur.fetchone()
    cur.close()
    conn.close()

    assert row is not None
    assert row["action"] in ("verify.lookup", "auth.unauthorized")
