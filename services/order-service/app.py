import os, socket, sqlite3, json, uuid, hashlib
from datetime import datetime, timezone
from decimal import Decimal
import requests, psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request
app=Flask(__name__)
app.config['MAX_CONTENT_LENGTH']=16384
SQLITE=os.getenv('DB_MODE')=='sqlite'
def connect():
    if SQLITE:
        c=sqlite3.connect(os.getenv('SQLITE_PATH','cloudmart-demo.db'),timeout=10); c.row_factory=sqlite3.Row; return c
    return psycopg2.connect(host=os.getenv('DB_HOST','postgres-db'),dbname=os.getenv('DB_NAME','cloudmart'),user=os.getenv('DB_USER','cloudmart'),password=os.environ['DB_PASSWORD'],connect_timeout=3,cursor_factory=RealDictCursor)
def sql(query): return query.replace('%s','?') if SQLITE else query
def initialize(c):
    with_cursor=c.cursor()
    if not SQLITE: with_cursor.execute('SELECT pg_advisory_xact_lock(424242)')
    with_cursor.execute('CREATE TABLE IF NOT EXISTS orders (id TEXT PRIMARY KEY, created_at TEXT NOT NULL, total TEXT NOT NULL, items TEXT NOT NULL, idempotency_key TEXT UNIQUE NOT NULL, request_hash TEXT NOT NULL)')
    c.commit(); with_cursor.close()
def serialize(row):
    r=dict(row);return {'id':r['id'],'created_at':r['created_at'],'total':r['total'],'items':json.loads(r['items']),'status':'Placed'}
def payload_items(data):
    if not isinstance(data,dict) or not isinstance(data.get('items'),list) or not 1<=len(data['items'])<=25: raise ValueError('Provide 1 to 25 cart items')
    result={}
    for item in data['items']:
        if not isinstance(item,dict): raise ValueError('Invalid cart item')
        i,q=item.get('product_id'),item.get('quantity')
        if type(i) is not int or i<1 or type(q) is not int or not 1<=q<=99: raise ValueError('Product ID and quantity must be positive integers. Quantity limit: 99')
        result[i]=result.get(i,0)+q
        if result[i]>99: raise ValueError('Quantity limit: 99 per product')
    return [{'product_id':i,'quantity':q} for i,q in sorted(result.items())]
@app.get('/healthz')
def health(): return jsonify(status='ok',service='order-service',host=socket.gethostname())
@app.get('/readyz')
def ready():
    try:
        c=connect();initialize(c);c.close();return jsonify(status='ok',storage='sqlite-demo' if SQLITE else 'postgresql',host=socket.gethostname())
    except (psycopg2.Error,sqlite3.Error,KeyError): return jsonify(status='unavailable',error='Database is not ready'),503
@app.route('/api/orders',methods=['GET','POST'])
def orders():
    c=None
    try:
        if request.method=='POST':
            items=payload_items(request.get_json(silent=True)); key=request.headers.get('Idempotency-Key','')
            if not 8<=len(key)<=128: return jsonify(error='Send an Idempotency-Key of 8 to 128 characters'),400
            fingerprint=hashlib.sha256(json.dumps(items,sort_keys=True).encode()).hexdigest()
        c=connect();initialize(c);cur=c.cursor()
        if request.method=='GET':
            cur.execute('SELECT * FROM orders ORDER BY created_at DESC LIMIT 100');return jsonify([serialize(row) for row in cur.fetchall()])
        cur.execute(sql('SELECT * FROM orders WHERE idempotency_key=%s'),(key,));existing=cur.fetchone()
        if existing:
            if dict(existing)['request_hash']!=fingerprint: return jsonify(error='This request key already belongs to a different cart'),409
            return jsonify(serialize(existing)),200
        response=requests.get(os.getenv('PRODUCT_SERVICE_URL','http://product-service:5001')+'/api/products',timeout=4);response.raise_for_status()
        catalog={p['id']:p for p in response.json()}; lines=[];total=Decimal('0')
        for item in items:
            product=catalog.get(item['product_id'])
            if not product: return jsonify(error='A product is no longer available'),400
            if item['quantity']>product['stock']: return jsonify(error=f"Only {product['stock']} units of {product['name']} are available in the catalog"),400
            subtotal=Decimal(product['price'])*item['quantity'];total+=subtotal
            lines.append({'product_id':product['id'],'name':product['name'],'quantity':item['quantity'],'unit_price':product['price'],'subtotal':str(subtotal.quantize(Decimal('.01')))})
        row=(str(uuid.uuid4()),datetime.now(timezone.utc).isoformat(),str(total.quantize(Decimal('.01'))),json.dumps(lines),key,fingerprint)
        cur.execute(sql('INSERT INTO orders VALUES (%s,%s,%s,%s,%s,%s) ON CONFLICT (idempotency_key) DO NOTHING'),row);c.commit()
        cur.execute(sql('SELECT * FROM orders WHERE idempotency_key=%s'),(key,));saved=cur.fetchone()
        if dict(saved)['request_hash']!=fingerprint: return jsonify(error='This request key already belongs to a different cart'),409
        return jsonify(serialize(saved)),201
    except ValueError as e: return jsonify(error=str(e)),400
    except requests.RequestException: return jsonify(error='Product service is unavailable. Please retry later.'),503
    except (psycopg2.Error,sqlite3.Error,KeyError):
        app.logger.exception('Database operation failed');return jsonify(error='Order storage is unavailable. Please retry later.'),503
    finally:
        if c: c.close()
@app.post('/api/demo/load')
def load():
    if os.getenv('ENABLE_LOAD_DEMO')!='true':return jsonify(error='Load demonstration is disabled'),404
    v=b'cloudmart'
    for _ in range(40000):v=hashlib.sha256(v).digest()
    return jsonify(host=socket.gethostname(),status='ok')
if __name__=='__main__':app.run(host=os.getenv('BIND_ADDRESS','0.0.0.0'),port=int(os.getenv('PORT','5002')))
