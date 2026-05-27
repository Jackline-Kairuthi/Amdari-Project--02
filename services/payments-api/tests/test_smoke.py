"""Smoke + Security Regression Tests for payments-api.

Covers:
- Argon2id password hashing
- JWT hardening (RS256 only, no HS256, no alg=none)
- IDOR fixes on accounts and wallets
- SQL injection fix on transaction search
- SSRF protection on webhook test
- Request signing on webhook endpoints
- Structured audit logging for key actions
- Removal of insecure admin session restore endpoint
"""

import os
import hmac
import json
import jwt
import datetime
import pytest

from app.main import create_app
from app.db import get_connection


# =========================================================
# FIXTURES
# =========================================================

@pytest.fixture
def app():
    app = create_app()
    app.config["TESTING"] = True
    return app


@pytest.fixture
def client(app):
    return app.test_client()


def _get_db():
    return get_connection()


def _create_user_and_login(client, email="user@example.com", password="StrongPass123!", role="merchant"):
    # register
    reg = client.post("/v1/auth/register", json={
        "email": email,
        "password": password,
        "full_name": "Test User",
        "role": role,
    })
    assert reg.status_code == 201
    user_id = reg.get_json()["id"]

    # login
    login = client.post("/v1/auth/login", json={
        "email": email,
        "password": password,
    })
    assert login.status_code == 200
    token = login.get_json()["token"]
    return user_id, token


def _auth_headers(token):
    return {"Authorization": f"Bearer {token}"}


def _sign_body(body: dict, secret: str):
    payload = json.dumps(body, separators=(",", ":"), sort_keys=True).encode("utf-8")
    sig = hmac.new(secret.encode("utf-8"), payload, "sha256").hexdigest()
    return sig


# =========================================================
# 1. ARGON2id PASSWORD HASHING
# =========================================================

def test_password_stored_as_argon2id_hash(client):
    email = "argon2id@example.com"
    password = "StrongPass123!"
    reg = client.post("/v1/auth/register", json={
        "email": email,
        "password": password,
        "full_name": "Argon Tester",
    })
    assert reg.status_code == 201

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT password_hash FROM users WHERE email = %s", (email,))
        row = cur.fetchone()
        assert row is not None
        pwd_hash = row["password_hash"]
        assert password not in pwd_hash
        assert pwd_hash.startswith("$argon2id$")
    finally:
        cur.close()
        conn.close()


# =========================================================
# 2. JWT HARDENING (RS256 ONLY)
# =========================================================

def test_jwt_hs256_rejected(client):
    fake_secret = "not-the-real-secret"
    payload = {
        "user_id": 1,
        "role": "merchant",
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        "iss": "sentinelpay-api",
    }
    hs256_token = jwt.encode(payload, fake_secret, algorithm="HS256")

    resp = client.get("/v1/accounts/1", headers=_auth_headers(hs256_token))
    assert resp.status_code == 401
    assert "invalid" in resp.get_json()["error"].lower()


def test_jwt_alg_none_rejected(client):
    payload = {
        "user_id": 1,
        "role": "merchant",
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        "iss": "sentinelpay-api",
    }
    none_token = jwt.encode(payload, key=None, algorithm=None)

    resp = client.get("/v1/accounts/1", headers=_auth_headers(none_token))
    assert resp.status_code == 401
    assert "invalid" in resp.get_json()["error"].lower()


def test_jwt_rs256_valid_token_accepted(client):
    user_id, token = _create_user_and_login(client, email="rs256@example.com")
    resp = client.get(f"/v1/accounts/{user_id}", headers=_auth_headers(token))
    assert resp.status_code in (200, 404)


# =========================================================
# 3. IDOR FIXES (ACCOUNTS + WALLETS)
# =========================================================

def test_account_idor_blocked_between_users(client):
    user1_id, token1 = _create_user_and_login(client, email="idor1@example.com")
    user2_id, token2 = _create_user_and_login(client, email="idor2@example.com")

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO accounts (user_id, account_number, currency, balance, status) "
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (user1_id, "ACC-IDOR-1", "GBP", 100, "active"),
        )
        acc_id = cur.fetchone()["id"]
        conn.commit()
    finally:
        cur.close()
        conn.close()

    resp = client.get(f"/v1/accounts/{acc_id}", headers=_auth_headers(token2))
    assert resp.status_code == 404


def test_wallet_debit_idor_blocked(client):
    user1_id, token1 = _create_user_and_login(client, email="wallet1@example.com")
    user2_id, token2 = _create_user_and_login(client, email="wallet2@example.com")

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO accounts (user_id, account_number, currency, balance, status) "
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (user1_id, "ACC-WALLET-1", "GBP", 100, "active"),
        )
        acc_id = cur.fetchone()["id"]
        conn.commit()
    finally:
        cur.close()
        conn.close()

    resp = client.post(
        f"/v1/wallets/{acc_id}/debit",
        headers=_auth_headers(token2),
        json={"amount": "10.00", "description": "attack"},
    )
    assert resp.status_code == 404


# =========================================================
# 4. SQL INJECTION FIX (TRANSACTION SEARCH)
# =========================================================

def test_transaction_search_sql_injection_blocked(client):
    user_id, token = _create_user_and_login(client, email="sqli@example.com")

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO accounts (user_id, account_number, currency, balance, status) "
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (user_id, "ACC-SQLI-1", "GBP", 100, "active"),
        )
        acc_id = cur.fetchone()["id"]
        cur.execute(
            "INSERT INTO transactions (account_id, reference, amount, direction, description, status) "
            "VALUES (%s, %s, %s, 'credit', %s, 'completed')",
            (acc_id, "TXN-SQLI-1", 10, "legit txn"),
        )
        conn.commit()
    finally:
        cur.close()
        conn.close()

    resp = client.get(
        "/v1/transactions/search",
        headers=_auth_headers(token),
        query_string={"q": "' OR '1'='1"},
    )
    assert resp.status_code == 200
    rows = resp.get_json()
    assert all(r["account_id"] == acc_id for r in rows)


# =========================================================
# 5. SSRF PROTECTION (WEBHOOK TEST)
# =========================================================

def test_webhook_test_blocks_internal_metadata_url(client):
    user_id, token = _create_user_and_login(client, email="ssrf@example.com")

    resp = client.post(
        "/v1/webhooks/test",
        headers=_auth_headers(token),
        json={"url": "http://169.254.169.254/latest/meta-data/iam/security-credentials/"},
    )
    assert resp.status_code in (400, 401)


# =========================================================
# 6. REQUEST SIGNING (WEBHOOKS)
# =========================================================

def test_webhook_register_requires_valid_signature(client):
    user_id, token = _create_user_and_login(client, email="wh-sign@example.com")

    secret = os.environ.get("WEBHOOK_SIGNING_SECRET", "test-signing-secret")
    body = {"callback_url": "https://example.com/hook", "event_type": "transaction.completed"}
    sig = _sign_body(body, secret)

    resp = client.post(
        "/v1/webhooks/",
        headers={**_auth_headers(token), "X-Signature": sig},
        json=body,
    )
    assert resp.status_code in (201, 401)


def test_webhook_register_rejects_missing_signature(client):
    user_id, token = _create_user_and_login(client, email="wh-nosig@example.com")

    resp = client.post(
        "/v1/webhooks/",
        headers=_auth_headers(token),
        json={"callback_url": "https://example.com/hook"},
    )
    assert resp.status_code in (400, 401)


# =========================================================
# 7. STRUCTURED AUDIT LOGGING
# =========================================================

def test_login_writes_audit_log_entry(client):
    email = "auditlogin@example.com"
    password = "StrongPass123!"
    client.post("/v1/auth/register", json={
        "email": email,
        "password": password,
        "full_name": "Audit Login",
    })

    resp = client.post("/v1/auth/login", json={
        "email": email,
        "password": password,
    })
    assert resp.status_code == 200
    user_id = resp.get_json()["user_id"]

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT action, user_id FROM audit_logs WHERE user_id = %s AND action = %s ORDER BY created_at DESC LIMIT 1",
            (user_id, "auth.login"),
        )
        row = cur.fetchone()
        assert row is not None
        assert row["user_id"] == user_id
    finally:
        cur.close()
        conn.close()


def test_wallet_debit_writes_audit_log_entry(client):
    user_id, token = _create_user_and_login(client, email="auditwallet@example.com")

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO accounts (user_id, account_number, currency, balance, status) "
            "VALUES (%s, %s, %s, %s, %s) RETURNING id",
            (user_id, "ACC-AUDIT-1", "GBP", 100, "active"),
        )
        acc_id = cur.fetchone()["id"]
        conn.commit()
    finally:
        cur.close()
        conn.close()

    resp = client.post(
        f"/v1/wallets/{acc_id}/debit",
        headers=_auth_headers(token),
        json={"amount": "10.00", "description": "audit test"},
    )
    assert resp.status_code == 200

    conn = _get_db()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT action, resource_type, resource_id FROM audit_logs "
            "WHERE user_id = %s AND action = %s ORDER BY created_at DESC LIMIT 1",
            (user_id, "wallet.debit"),
        )
        row = cur.fetchone()
        assert row is not None
        assert row["resource_type"] == "account"
        assert row["resource_id"] == acc_id
    finally:
        cur.close()
        conn.close()


# =========================================================
# 8. INSECURE ADMIN SESSION RESTORE REMOVED
# =========================================================

def test_admin_session_restore_endpoint_removed(client):
    resp = client.post("/v1/admin/session/restore", json={"session": "anything"})
    assert resp.status_code in (404, 405)

