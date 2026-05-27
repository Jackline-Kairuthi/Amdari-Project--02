"""Wallet credit and debit operations."""
import uuid
from decimal import Decimal
from flask import Blueprint, request, jsonify

from app.db import get_connection
from app.auth import require_auth

# Structured audit logging
from app.audit import audit_log

wallets_bp = Blueprint("wallets", __name__)


@wallets_bp.route("/<int:account_id>/credit", methods=["POST"])
@require_auth
def credit_wallet(account_id):
    """Credit funds to a wallet (e.g. inbound transfer settlement)."""
    current_user_id = request.current_user_id
    data = request.get_json() or {}
    amount = Decimal(str(data.get("amount", "0")))
    description = data.get("description", "credit")

    if amount <= 0:
        return jsonify({"error": "amount must be positive"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        # Ownership check (IDOR fix)
        cur.execute(
            "SELECT balance FROM accounts WHERE id = %s AND user_id = %s",
            (account_id, current_user_id),
        )
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "account not found"}), 404

        new_balance = Decimal(str(row["balance"])) + amount

        cur.execute(
            "UPDATE accounts SET balance = %s WHERE id = %s AND user_id = %s",
            (new_balance, account_id, current_user_id),
        )

        reference = f"TXN-{uuid.uuid4().hex[:12].upper()}"
        cur.execute(
            "INSERT INTO transactions (account_id, reference, amount, direction, description, status) "
            "VALUES (%s, %s, %s, 'credit', %s, 'completed')",
            (account_id, reference, amount, description),
        )

        conn.commit()

        # AUDIT LOG — must run BEFORE return
        audit_log(
            conn,
            user_id=current_user_id,
            action="wallet.credit",
            resource_type="account",
            resource_id=account_id,
            metadata={
                "amount": str(amount),
                "new_balance": str(new_balance),
                "reference": reference,
                "description": description,
                "endpoint": "credit_wallet"
            }
        )

        return jsonify({"reference": reference, "new_balance": str(new_balance)})

    finally:
        cur.close()
        conn.close()


@wallets_bp.route("/<int:account_id>/debit", methods=["POST"])
@require_auth
def debit_wallet(account_id):
    """Debit funds from a wallet."""
    current_user_id = request.current_user_id
    data = request.get_json() or {}
    amount = Decimal(str(data.get("amount", "0")))
    counterparty = data.get("counterparty", "")
    description = data.get("description", "debit")

    if amount <= 0:
        return jsonify({"error": "amount must be positive"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        # Ownership check (IDOR fix) + row lock to prevent race conditions
        cur.execute(
            """
            SELECT balance
            FROM accounts
            WHERE id = %s AND user_id = %s
            FOR UPDATE
            """,
            (account_id, current_user_id),
        )

        row = cur.fetchone()
        if not row:
            return jsonify({"error": "account not found"}), 404

        current_balance = Decimal(str(row["balance"]))
        if current_balance < amount:
            return jsonify({"error": "insufficient funds"}), 400

        new_balance = current_balance - amount

        cur.execute(
            "UPDATE accounts SET balance = %s WHERE id = %s AND user_id = %s",
            (new_balance, account_id, current_user_id),
        )

        reference = f"TXN-{uuid.uuid4().hex[:12].upper()}"
        cur.execute(
            "INSERT INTO transactions (account_id, reference, amount, direction, counterparty, description, status) "
            "VALUES (%s, %s, %s, 'debit', %s, %s, 'completed')",
            (account_id, reference, amount, counterparty, description),
        )

        conn.commit()

        # AUDIT LOG — must run BEFORE return
        audit_log(
            conn,
            user_id=current_user_id,
            action="wallet.debit",
            resource_type="account",
            resource_id=account_id,
            metadata={
                "amount": str(amount),
                "new_balance": str(new_balance),
                "reference": reference,
                "counterparty": counterparty,
                "description": description,
                "endpoint": "debit_wallet"
            }
        )

        return jsonify({"reference": reference, "new_balance": str(new_balance)})

    finally:
        cur.close()
        conn.close()

