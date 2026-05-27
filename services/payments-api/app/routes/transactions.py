"""Transaction search and listing endpoints."""
from flask import Blueprint, request, jsonify

from app.db import get_connection
from app.auth import require_auth

# Structured audit logging
from app.audit import audit_log


transactions_bp = Blueprint("transactions", __name__)


@transactions_bp.route("/search", methods=["GET"])
@require_auth
def search_transactions():
    """Search transactions by reference, counterparty, or description."""
    q = request.args.get("q", "")
    account_id = request.args.get("account_id", "")
    current_user_id = request.current_user_id

    conn = get_connection()
    cur = conn.cursor()
    try:
        # SQL Injection Fix — use parameterised LIKE patterns
        like_pattern = f"%{q}%"

        base_query = """
            SELECT t.id, t.account_id, t.reference, t.amount, t.currency, t.direction,
                   t.counterparty, t.description, t.status, t.created_at
            FROM transactions t
            JOIN accounts a ON t.account_id = a.id
            WHERE a.user_id = %s
              AND (t.reference LIKE %s
                   OR t.counterparty LIKE %s
                   OR t.description LIKE %s)
        """

        params = [current_user_id, like_pattern, like_pattern, like_pattern]

        if account_id:
            base_query += " AND t.account_id = %s"
            params.append(account_id)

        base_query += " ORDER BY t.created_at DESC LIMIT 50"

        cur.execute(base_query, tuple(params))
        rows = cur.fetchall()

        # AUDIT LOG — must run BEFORE return
        audit_log(
            conn,
            user_id=current_user_id,
            action="transactions.search",
            resource_type="transaction",
            resource_id=None,
            metadata={
                "query": q,
                "account_id": account_id,
                "result_count": len(rows),
                "endpoint": "search_transactions"
            }
        )

        return jsonify([dict(r) for r in rows])

    finally:
        cur.close()
        conn.close()


@transactions_bp.route("/<reference>", methods=["GET"])
@require_auth
def get_transaction(reference):
    """Fetch a single transaction by reference, scoped to the current user."""
    current_user_id = request.current_user_id

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT t.*
            FROM transactions t
            JOIN accounts a ON t.account_id = a.id
            WHERE t.reference = %s
              AND a.user_id = %s
            """,
            (reference, current_user_id),
        )
        txn = cur.fetchone()

        if not txn:
            return jsonify({"error": "transaction not found"}), 404

        # AUDIT LOG — must run BEFORE return
        audit_log(
            conn,
            user_id=current_user_id,
            action="transactions.get",
            resource_type="transaction",
            resource_id=txn["id"],
            metadata={"reference": reference, "endpoint": "get_transaction"}
        )

        return jsonify(dict(txn))

    finally:
        cur.close()
        conn.close()


