"""Webhook registration and callback testing."""
import os
import requests
from urllib.parse import urlparse
from flask import Blueprint, request, jsonify

from app.db import get_connection
from app.auth import require_auth

# Structured audit logging
from app.audit import audit_log

# Request signing
from app.security import verify_signature

webhooks_bp = Blueprint("webhooks", __name__)

WEBHOOK_TIMEOUT = int(os.environ.get("WEBHOOK_TIMEOUT", "10"))


def is_safe_url(url: str) -> bool:
    """Basic SSRF protection: allow only https:// and block internal IPs."""
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ("https",):
            return False

        # Block internal IP ranges
        hostname = parsed.hostname or ""
        forbidden_prefixes = (
            "127.", "10.", "172.16.", "172.17.", "172.18.", "172.19.",
            "172.20.", "172.21.", "172.22.", "172.23.", "172.24.",
            "172.25.", "172.26.", "172.27.", "172.28.", "172.29.",
            "172.30.", "172.31.", "192.168.", "169.254."
        )
        return not hostname.startswith(forbidden_prefixes)
    except Exception:
        return False


@webhooks_bp.route("/", methods=["POST"])
@require_auth
def register_webhook():
    """Register a callback URL for transaction events."""
    data = request.get_json() or {}
    callback_url = data.get("callback_url")
    event_type = data.get("event_type", "transaction.completed")

    if not callback_url:
        return jsonify({"error": "callback_url required"}), 400

    # Request signing verification
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO webhooks (user_id, callback_url, event_type) VALUES (%s, %s, %s) RETURNING id",
            (request.current_user_id, callback_url, event_type)
        )
        webhook_id = cur.fetchone()["id"]

        # AUDIT LOG
        audit_log(
            conn,
            user_id=request.current_user_id,
            action="webhooks.register",
            resource_type="webhook",
            resource_id=webhook_id,
            metadata={"callback_url": callback_url, "event_type": event_type}
        )

        conn.commit()
        return jsonify({"id": webhook_id, "callback_url": callback_url}), 201

    finally:
        cur.close()
        conn.close()


@webhooks_bp.route("/test", methods=["POST"])
@require_auth
def test_webhook():
    """Test-fire a webhook by fetching the supplied URL with a sample payload."""
    data = request.get_json() or {}
    url = data.get("url")

    if not url:
        return jsonify({"error": "url required"}), 400

    # Request signing verification
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    # SSRF protection
    if not is_safe_url(url):
        return jsonify({"error": "unsafe or disallowed URL"}), 400

    try:
        resp = requests.get(url, timeout=WEBHOOK_TIMEOUT)

        # AUDIT LOG
        audit_log(
            conn=None,  # no DB writes here
            user_id=request.current_user_id,
            action="webhooks.test",
            resource_type="webhook",
            resource_id=None,
            metadata={"url": url, "status_code": resp.status_code}
        )

        return jsonify({
            "status_code": resp.status_code,
            "headers": dict(resp.headers),
            "body": resp.text[:5000]
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500
