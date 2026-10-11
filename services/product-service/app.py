import os
import socket
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# In-memory product inventory for CloudMart demonstration
PRODUCTS = [
    {
        "id": 1,
        "name": "Kubernetes Cluster In A Box (Mini-Node)",
        "category": "Hardware",
        "price": 249.99,
        "stock": 15,
        "icon": "bi-hdd-network",
        "description": "Quad-core ARM micro-server with pre-configured K3s and Docker runtime."
    },
    {
        "id": 2,
        "name": "DevOps Engineer Mechanical Keyboard",
        "category": "Peripherals",
        "price": 119.50,
        "stock": 25,
        "icon": "bi-keyboard",
        "description": "Tactile switch mechanical keyboard with dedicated kubectl macro keys."
    },
    {
        "id": 3,
        "name": "Cloud Native Architecture Handbook",
        "category": "Books",
        "price": 45.00,
        "stock": 40,
        "icon": "bi-book",
        "description": "Comprehensive guide to 12-factor apps, service meshes, and CI/CD pipelines."
    },
    {
        "id": 4,
        "name": "Docker Whale Plushie & Sticker Pack",
        "category": "Swag",
        "price": 19.99,
        "stock": 60,
        "icon": "bi-box-seam",
        "description": "Official cotton mascot plushie with waterproof containerization stickers."
    },
    {
        "id": 5,
        "name": "High-Throughput Dual-Band Cloud Gateway",
        "category": "Hardware",
        "price": 189.00,
        "stock": 10,
        "icon": "bi-router",
        "description": "Gigabit edge router with hardware-accelerated ingress packet filtering."
    }
]

@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({
        "status": "UP",
        "service": "product-service",
        "hostname": socket.gethostname(),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }), 200

@app.route("/api/products", methods=["GET"])
def get_products():
    return jsonify({
        "service": "product-service",
        "hostname": socket.gethostname(),
        "total": len(PRODUCTS),
        "products": PRODUCTS
    }), 200

@app.route("/api/products/<int:product_id>", methods=["GET"])
def get_product(product_id):
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    if product:
        return jsonify({
            "service": "product-service",
            "hostname": socket.gethostname(),
            "product": product
        }), 200
    return jsonify({"error": "Product not found", "hostname": socket.gethostname()}), 404

@app.route("/api/products/<int:product_id>/reserve", methods=["POST"])
def reserve_product(product_id):
    data = request.get_json(silent=True) or {}
    quantity = int(data.get("quantity", 1))
    
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    if not product:
        return jsonify({"error": "Product not found"}), 404
        
    if product["stock"] < quantity:
        return jsonify({
            "error": "Insufficient stock",
            "available": product["stock"],
            "requested": quantity
        }), 400
        
    product["stock"] -= quantity
    return jsonify({
        "success": True,
        "message": f"Reserved {quantity} item(s) of '{product['name']}'",
        "remaining_stock": product["stock"],
        "hostname": socket.gethostname()
    }), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)
