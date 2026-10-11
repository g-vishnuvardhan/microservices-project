import os,socket,time
from concurrent.futures import ThreadPoolExecutor
import requests
from flask import Flask,render_template,jsonify,request,Response
app=Flask(__name__);app.config['MAX_CONTENT_LENGTH']=16384
URLS={'product-service':os.getenv('PRODUCT_SERVICE_URL','http://product-service:5001'),'order-service':os.getenv('ORDER_SERVICE_URL','http://order-service:5002')}
@app.after_request
def headers(response):
    response.headers['Cache-Control']='no-store' if request.path.startswith('/api/') else 'no-cache'
    response.headers['X-Content-Type-Options']='nosniff';response.headers['X-Frame-Options']='DENY';return response
@app.get('/')
def index():return render_template('index.html')
@app.get('/healthz')
@app.get('/readyz')
def health():return jsonify(status='ok',service='frontend-service',host=socket.gethostname())
@app.route('/api/products',methods=['GET'])
@app.route('/api/products/<int:product_id>',methods=['GET'])
@app.route('/api/orders',methods=['GET','POST'])
@app.route('/api/demo/load',methods=['POST'])
def proxy(product_id=None):
    target='product-service' if request.path.startswith('/api/products') else 'order-service'
    try:
        r=requests.request(request.method,URLS[target]+request.path,json=request.get_json(silent=True) if request.method=='POST' else None,headers={'Idempotency-Key':request.headers.get('Idempotency-Key','')},timeout=8)
        return Response(r.content,status=r.status_code,content_type='application/json')
    except requests.RequestException:return jsonify(error=f'{target} is unavailable. Check the service and retry.'),503
def probe(service):
    t=time.perf_counter()
    try:
        r=requests.get(URLS[service]+'/readyz',timeout=3);data=r.json()
        return {'service':service,'status':'healthy' if r.ok else 'unavailable','host':data.get('host'),'latency_ms':round((time.perf_counter()-t)*1000,1),'storage':data.get('storage')}
    except (requests.RequestException,ValueError):return {'service':service,'status':'unavailable','host':None,'latency_ms':None}
@app.get('/api/inspector')
def inspector():
    with ThreadPoolExecutor(max_workers=2) as executor: services=list(executor.map(probe,URLS))
    return jsonify(frontend_host=socket.gethostname(),environment=os.getenv('DEPLOYMENT_MODE','local-demo'),services=services)
if __name__=='__main__':app.run(host=os.getenv('BIND_ADDRESS','0.0.0.0'),port=int(os.getenv('PORT','5000')))
