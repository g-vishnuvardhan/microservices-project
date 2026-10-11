import os
import socket
import time
from datetime import datetime
from flask import Flask, render_template, jsonify, request
import requests

app = Flask(__name__)

PRODUCT_SERVICE_URL = os.environ.get("PRODUCT_SERVICE_URL", "http://product-service:5001")
ORDER_SERVICE_URL = os.environ.get("ORDER_SERVICE_URL", "http://order-service:5002")
APP_ENV = os.environ.get("APP_ENV", "kubernetes-production")

@app.route("/")
def index():
    pod_name = socket.gethostname()
    return render_template(
        "index.html",
        pod_name=pod_name,
        app_env=APP_ENV,
        product_url=PRODUCT_SERVICE_URL,
        order_url=ORDER_SERVICE_URL
    )

@app.route("/healthz")
def healthz():
    return jsonify({
        "status": "UP",
        "service": "frontend-service",
        "hostname": socket.gethostname(),
        "environment": APP_ENV,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }), 200

@app.route("/api/proxy/products", methods=["GET"])
def proxy_products():
    try:
        t0 = time.time()
        resp = requests.get(f"{PRODUCT_SERVICE_URL}/api/products", timeout=3)
        latency_ms = round((time.time() - t0) * 1000, 2)
        data = resp.json()
        data["proxy_latency_ms"] = latency_ms
        data["frontend_pod"] = socket.gethostname()
        return jsonify(data), resp.status_code
    except Exception as e:
        return jsonify({
            "error": "Failed to connect to Product Service",
            "details": str(e),
            "target_url": PRODUCT_SERVICE_URL,
            "frontend_pod": socket.gethostname()
        }), 502

@app.route("/api/proxy/orders", methods=["GET", "POST"])
def proxy_orders():
    if request.method == "GET":
        try:
            t0 = time.time()
            resp = requests.get(f"{ORDER_SERVICE_URL}/api/orders", timeout=3)
            latency_ms = round((time.time() - t0) * 1000, 2)
            data = resp.json()
            data["proxy_latency_ms"] = latency_ms
            data["frontend_pod"] = socket.gethostname()
            return jsonify(data), resp.status_code
        except Exception as e:
            return jsonify({
                "error": "Failed to connect to Order Service",
                "details": str(e),
                "target_url": ORDER_SERVICE_URL,
                "frontend_pod": socket.gethostname()
            }), 502

    elif request.method == "POST":
        try:
            payload = request.get_json(silent=True) or {}
            t0 = time.time()
            resp = requests.post(f"{ORDER_SERVICE_URL}/api/orders", json=payload, timeout=5)
            latency_ms = round((time.time() - t0) * 1000, 2)
            data = resp.json()
            data["proxy_latency_ms"] = latency_ms
            data["frontend_pod"] = socket.gethostname()
            return jsonify(data), resp.status_code
        except Exception as e:
            return jsonify({
                "error": "Failed to forward order to Order Service",
                "details": str(e),
                "frontend_pod": socket.gethostname()
            }), 502

@app.route("/api/cluster/status", methods=["GET"])
def cluster_status():
    """Gathers status across all microservices for the live topology view"""
    services_status = {}
    
    # 1. Frontend status
    services_status["frontend"] = {
        "service": "frontend-service",
        "pod": socket.gethostname(),
        "status": "UP",
        "latency_ms": 0.0
    }
    
    # 2. Product service check
    try:
        t0 = time.time()
        p_resp = requests.get(f"{PRODUCT_SERVICE_URL}/healthz", timeout=2)
        p_latency = round((time.time() - t0) * 1000, 2)
        if p_resp.status_code == 200:
            p_data = p_resp.json()
            services_status["product"] = {
                "service": "product-service",
                "pod": p_data.get("hostname", "unknown"),
                "status": "UP",
                "latency_ms": p_latency
            }
        else:
            services_status["product"] = {"service": "product-service", "status": "DEGRADED", "latency_ms": p_latency}
    except Exception as e:
        services_status["product"] = {"service": "product-service", "status": "DOWN", "error": str(e)}

    # 3. Order service check
    try:
        t0 = time.time()
        o_resp = requests.get(f"{ORDER_SERVICE_URL}/healthz", timeout=2)
        o_latency = round((time.time() - t0) * 1000, 2)
        if o_resp.status_code == 200:
            o_data = o_resp.json()
            services_status["order"] = {
                "service": "order-service",
                "pod": o_data.get("hostname", "unknown"),
                "status": "UP",
                "database": o_data.get("database", "unknown"),
                "latency_ms": o_latency
            }
        else:
            services_status["order"] = {"service": "order-service", "status": "DEGRADED", "latency_ms": o_latency}
    except Exception as e:
        services_status["order"] = {"service": "order-service", "status": "DOWN", "error": str(e)}

    return jsonify({
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "environment": APP_ENV,
        "services": services_status
    }), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
