"""Identity verification endpoints."""
import os
import requests
from flask import Blueprint, request, jsonify

from app.db import get_connection
from app.auth import require_auth
from app.security import verify_signature          # <-- ADDED: request signing
from app.audit import audit_log                    # <-- ADDED: audit logging

verify_bp = Blueprint("verify", __name__)

BVN_LOOKUP_URL = os.environ.get("BVN_LOOKUP_URL", "https://api.mock-cbn.local/bvn")


@verify_bp.route("/bvn", methods=["POST"])
@require_auth
def verify_bvn():
    """Verify a BVN against the upstream lookup service."""

    # ---------------------------------------------------------
    # ADDED: Request signing (broken authentication fix)
    # ---------------------------------------------------------
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    data = request.get_json() or {}
    bvn = data.get("bvn")
    provider_url = data.get("provider", BVN_LOOKUP_URL)

    if not bvn or len(bvn) != 11:
        return jsonify({"error": "valid 11-digit BVN required"}), 400

    try:
        resp = requests.post(provider_url, json={"bvn": bvn}, timeout=10)

        # ---------------------------------------------------------
        # ADDED: Audit logging
        # ---------------------------------------------------------
        audit_log(
            conn=None,
            user_id=request.current_user_id,
            action="verify.bvn",
            resource_type="bvn",
            resource_id=bvn,
            metadata={"provider_url": provider_url},
        )

        return jsonify({"status": "ok", "provider_response": resp.text[:2000]})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@verify_bp.route("/lookup", methods=["GET"])
@require_auth
def lookup_kyc():
    """Look up a KYC record by BVN or NIN."""

    # ---------------------------------------------------------
    # ADDED: Request signing (broken authentication fix)
    # ---------------------------------------------------------
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    bvn = request.args.get("bvn", "")
    nin = request.args.get("nin", "")

    conn = get_connection()
    cur = conn.cursor()
    try:
        # ---------------------------------------------------------
        # FIXED: SQL injection (parameterised queries)
        # ---------------------------------------------------------
        if bvn:
            query = "SELECT * FROM kyc_records WHERE bvn = %s"
            params = (bvn,)
        elif nin:
            query = "SELECT * FROM kyc_records WHERE nin = %s"
            params = (nin,)
        else:
            return jsonify({"error": "bvn or nin required"}), 400

        cur.execute(query, params)
        records = cur.fetchall()

        # ---------------------------------------------------------
        # ADDED: Audit logging
        # ---------------------------------------------------------
        audit_log(
            conn=None,
            user_id=request.current_user_id,
            action="verify.lookup",
            resource_type="kyc_record",
            resource_id=bvn or nin,
            metadata={"query_type": "bvn" if bvn else "nin"},
        )

        return jsonify([dict(r) for r in records])

    finally:
        cur.close()
        conn.close()

