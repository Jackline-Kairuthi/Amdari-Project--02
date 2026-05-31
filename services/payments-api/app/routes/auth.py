"""Authentication routes: registration, login, and OTP."""
from flask import Blueprint, request, jsonify

from app.db import get_connection
from app.auth import hash_password, verify_password, issue_token

# Structured audit logging
from app.audit import audit_log


auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["POST"])
def register():
    """Register a new merchant account."""
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")
    full_name = data.get("full_name", "")
    role = data.get("role", "merchant")

    if not email or not password:
        return jsonify({"error": "email and password required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO users (email, password_hash, full_name, role) "
            "VALUES (%s, %s, %s, %s) RETURNING id",
            (email, hash_password(password), full_name, role)
        )

        user_id = cur.fetchone()["id"]

        # NEW: audit log for registration
        audit_log(
            conn,
            user_id=user_id,
            action="auth.register",
            resource_type="user",
            resource_id=user_id,
            metadata={"email": email, "role": role},
        )

        conn.commit()
        return jsonify({"id": user_id, "email": email, "role": role}), 201

    finally:
        cur.close()
        conn.close()


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate a user and issue a JWT."""
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT id, password_hash, role, is_active FROM users WHERE email = %s",
            (email,)
        )
        user = cur.fetchone()

        if not user or not verify_password(password, user["password_hash"]):
            return jsonify({"error": "invalid credentials"}), 401

        if not user["is_active"]:
            return jsonify({"error": "account suspended"}), 403

        token = issue_token(user["id"], user["role"])

        # NEW: audit log for login
        audit_log(
            conn,
            user_id=user["id"],
            action="auth.login",
            resource_type="user",
            resource_id=user["id"],
            metadata={"email": email, "role": user["role"]},
        )

        return jsonify({"token": token, "user_id": user["id"], "role": user["role"]})

    finally:
        cur.close()
        conn.close()


@auth_bp.route("/otp", methods=["POST"])
def request_otp():
    """Request an OTP code for step-up authentication."""
    import random
    data = request.get_json() or {}
    phone = data.get("phone")

    otp = str(random.randint(100000, 999999))

    # Removed insecure OTP debug logging

    return jsonify({"status": "sent", "phone": phone})
