import os
import json
import socket
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

DB_HOST = os.environ.get("DB_HOST", "postgres-service")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "cloudmart")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "postgres123")
PRODUCT_SERVICE_URL = os.environ.get("PRODUCT_SERVICE_URL", "http://product-service:5001")

# In-memory storage fallback if PostgreSQL is not yet reachable during boot
IN_MEMORY_ORDERS = []

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=3
        )
        return conn
    except Exception as e:
        logger.warning(f"Database connection failed: {e}. Using in-memory fallback.")
        return None

def init_db():
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS orders (
                        id SERIAL PRIMARY KEY,
                        customer_name VARCHAR(100) NOT NULL,
                        customer_email VARCHAR(100) NOT NULL,
                        items JSONB NOT NULL,
                        total_amount NUMERIC(10, 2) NOT NULL,
                        served_by_pod VARCHAR(100),
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                conn.commit()
                logger.info("Orders database table initialized successfully.")
        except Exception as e:
            logger.error(f"Error initializing orders table: {e}")
        finally:
            conn.close()

# Attempt table creation upon startup
init_db()

@app.route("/healthz", methods=["GET"])
def healthz():
    conn = get_db_connection()
    db_status = "connected" if conn else "fallback_mode"
    if conn:
        conn.close()
    return jsonify({
        "status": "UP",
        "service": "order-service",
        "hostname": socket.gethostname(),
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }), 200

@app.route("/api/orders", methods=["GET"])
def get_orders():
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT * FROM orders ORDER BY created_at DESC LIMIT 50;")
                rows = cur.fetchall()
                orders = []
                for row in rows:
                    orders.append({
                        "id": row["id"],
                        "customer_name": row["customer_name"],
                        "customer_email": row["customer_email"],
                        "items": row["items"],
                        "total_amount": float(row["total_amount"]),
                        "served_by_pod": row["served_by_pod"],
                        "created_at": row["created_at"].isoformat() if row["created_at"] else ""
                    })
                return jsonify({
                    "service": "order-service",
                    "hostname": socket.gethostname(),
                    "storage": "PostgreSQL",
                    "total": len(orders),
                    "orders": orders
                }), 200
        except Exception as e:
            logger.error(f"Error fetching orders from database: {e}")
        finally:
            conn.close()

    # Fallback to in-memory orders
    return jsonify({
        "service": "order-service",
        "hostname": socket.gethostname(),
        "storage": "In-Memory Fallback",
        "total": len(IN_MEMORY_ORDERS),
        "orders": list(reversed(IN_MEMORY_ORDERS))
    }), 200

@app.route("/api/orders", methods=["POST"])
def create_order():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid request payload"}), 400

    customer_name = data.get("customer_name", "DevOps Student")
    customer_email = data.get("customer_email", "student@cloudmart.lab")
    items = data.get("items", [])

    if not items:
        return jsonify({"error": "Cart cannot be empty"}), 400

    total_amount = sum(float(item.get("price", 0)) * int(item.get("quantity", 1)) for item in items)
    current_pod = socket.gethostname()

    # Try reserving inventory in product-service (Microservice-to-Microservice communication)
    for item in items:
        prod_id = item.get("id")
        qty = item.get("quantity", 1)
        try:
            res = requests.post(
                f"{PRODUCT_SERVICE_URL}/api/products/{prod_id}/reserve",
                json={"quantity": qty},
                timeout=2
            )
            if res.status_code == 200:
                logger.info(f"Inventory reserved for product {prod_id}")
        except Exception as e:
            logger.warning(f"Could not reach product-service to reserve stock: {e}")

    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO orders (customer_name, customer_email, items, total_amount, served_by_pod)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id, created_at;
                    """,
                    (customer_name, customer_email, json.dumps(items), total_amount, current_pod)
                )
                order_id, created_at = cur.fetchone()
                conn.commit()
                return jsonify({
                    "success": True,
                    "order_id": order_id,
                    "customer_name": customer_name,
                    "total_amount": total_amount,
                    "served_by_pod": current_pod,
                    "storage": "PostgreSQL",
                    "created_at": created_at.isoformat()
                }), 201
        except Exception as e:
            logger.error(f"Failed to insert into PostgreSQL: {e}")
        finally:
            conn.close()

    # Fallback storage
    order_id = len(IN_MEMORY_ORDERS) + 1001
    now_iso = datetime.utcnow().isoformat() + "Z"
    new_order = {
        "id": order_id,
        "customer_name": customer_name,
        "customer_email": customer_email,
        "items": items,
        "total_amount": total_amount,
        "served_by_pod": current_pod,
        "created_at": now_iso
    }
    IN_MEMORY_ORDERS.append(new_order)

    return jsonify({
        "success": True,
        "order_id": order_id,
        "customer_name": customer_name,
        "total_amount": total_amount,
        "served_by_pod": current_pod,
        "storage": "In-Memory Fallback",
        "created_at": now_iso
    }), 201

@app.route("/api/orders", methods=["DELETE"])
def clear_orders():
    global IN_MEMORY_ORDERS
    IN_MEMORY_ORDERS = []
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute("TRUNCATE TABLE orders;")
                conn.commit()
        except Exception as e:
            logger.error(f"Error truncating table: {e}")
        finally:
            conn.close()
    return jsonify({"success": True, "message": "All orders cleared"}), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5002))
    app.run(host="0.0.0.0", port=port)
