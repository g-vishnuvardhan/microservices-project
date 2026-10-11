import os, socket
from datetime import datetime, timezone
from flask import Flask, jsonify
app = Flask(__name__)
PRODUCTS = [
 {"id":1,"name":"Studio Headphones","category":"Electronics","price":"2499.00","stock":24,"icon":"headphones","color":"lavender","description":"A quieter space for your next big idea."},
 {"id":2,"name":"Mechanical Keyboard","category":"Electronics","price":"3299.00","stock":18,"icon":"keyboard","color":"peach","description":"Comfortable keys. A satisfying daily rhythm."},
 {"id":3,"name":"Cloud Computing Handbook","category":"Books","price":"699.00","stock":40,"icon":"book","color":"mint","description":"Your companion for containers and the cloud."},
 {"id":4,"name":"Everyday Laptop Stand","category":"Cloud Gear","price":"1299.00","stock":16,"icon":"laptop","color":"blue","description":"Give your workspace a little breathing room."},
 {"id":5,"name":"DevOps Field Notes","category":"Books","price":"499.00","stock":32,"icon":"notes","color":"butter","description":"Capture experiments, commands and discoveries."},
 {"id":6,"name":"Cloud Explorer Backpack","category":"Cloud Gear","price":"1899.00","stock":12,"icon":"bag","color":"rose","description":"A lightweight home for your everyday essentials."}
]
@app.get('/api/products')
def products(): return jsonify(PRODUCTS)
@app.get('/api/products/<int:product_id>')
def product(product_id):
    item=next((p for p in PRODUCTS if p['id']==product_id),None)
    return (jsonify(item),200) if item else (jsonify(error='Product not found'),404)
@app.get('/healthz')
@app.get('/readyz')
def health(): return jsonify(status='ok', service='product-service',host=socket.gethostname(),timestamp=datetime.now(timezone.utc).isoformat())
if __name__=='__main__': app.run(host=os.getenv('BIND_ADDRESS','0.0.0.0'),port=int(os.getenv('PORT','5001')))
