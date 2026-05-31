"""Document upload and retrieval for KYC submissions."""
import os
import boto3
from flask import Blueprint, request, jsonify

from app.auth import require_auth
from app.audit import audit_log                     # <-- ADDED: audit logging
from app.security import verify_signature           # <-- ADDED: request signing

documents_bp = Blueprint("documents", __name__)

KYC_BUCKET = os.environ.get("KYC_BUCKET", "sentinelpay-kyc-documents")


def _s3():
    return boto3.client(
        "s3",
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
        region_name=os.environ.get("AWS_REGION", "af-south-1"),
    )


@documents_bp.route("/upload", methods=["POST"])
@require_auth
def upload_document():
    """Upload a KYC document."""

    # -------------------------------
    # ADDED: Request signing required
    # -------------------------------
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    if "file" not in request.files:
        return jsonify({"error": "file required"}), 400

    f = request.files["file"]
    user_id = request.current_user_id
    filename = f.filename  # NOTE: path traversal is out of scope for this task.

    key = f"users/{user_id}/{filename}"

    try:
        _s3().put_object(
            Bucket=KYC_BUCKET,
            Key=key,
            Body=f.read(),
            ACL="public-read",  # left unchanged — cloud hardening not in scope
        )

        # -----------------------------------------
        # ADDED: Structured audit logging (required)
        # -----------------------------------------
        audit_log(
            conn=None,
            user_id=user_id,
            action="documents.upload",
            resource_type="document",
            resource_id=key,
            metadata={"filename": filename},
        )

        return jsonify({"key": key, "bucket": KYC_BUCKET}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@documents_bp.route("/<path:key>", methods=["GET"])
@require_auth
def get_document(key):
    """Fetch a previously uploaded document."""

    # -------------------------------
    # ADDED: Request signing required
    # -------------------------------
    if not verify_signature(request):
        return jsonify({"error": "invalid signature"}), 401

    user_id = request.current_user_id

    # ------------------------------------------------------
    # ADDED: IDOR FIX — enforce ownership of the S3 document
    # ------------------------------------------------------
    expected_prefix = f"users/{user_id}/"
    if not key.startswith(expected_prefix):
        return jsonify({"error": "not found"}), 404

    try:
        obj = _s3().get_object(Bucket=KYC_BUCKET, Key=key)

        # -----------------------------------------
        # ADDED: Structured audit logging (required)
        # -----------------------------------------
        audit_log(
            conn=None,
            user_id=user_id,
            action="documents.get",
            resource_type="document",
            resource_id=key,
            metadata={"bucket": KYC_BUCKET},
        )

        return (
            obj["Body"].read(),
            200,
            {"Content-Type": obj.get("ContentType", "application/octet-stream")},
        )

    except Exception:
        return jsonify({"error": "not found"}), 404

