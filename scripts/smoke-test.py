"""End-to-end health, product, checkout, retry and history checks."""
import sys,uuid
from decimal import Decimal
import requests
base=(sys.argv[1] if len(sys.argv)>1 else 'http://localhost:5000').rstrip('/')
def call(path,method='GET',**kwargs):
    r=requests.request(method,base+path,timeout=15,**kwargs);r.raise_for_status();return r
health=call('/api/inspector').json()
assert all(s['status']=='healthy' for s in health['services']),health
products=call('/api/products').json();p=products[0]
headers={'Idempotency-Key':str(uuid.uuid4())}
payload={'items':[{'product_id':p['id'],'quantity':2,'price':'0.01'}]}
order=call('/api/orders','POST',json=payload,headers=headers).json()
assert Decimal(order['total'])==Decimal(p['price'])*2
retry=call('/api/orders','POST',json=payload,headers=headers).json()
assert retry['id']==order['id']
assert any(o['id']==order['id'] for o in call('/api/orders').json())
invalid=requests.post(base+'/api/orders',json={'items':[{'product_id':p['id'],'quantity':-1}]},headers={'Idempotency-Key':str(uuid.uuid4())},timeout=15)
assert invalid.status_code==400
print('PASS: live health, catalog, server-calculated price, checkout, safe retry, history and invalid-cart rejection')
print('Deployment:',health['environment'],'Storage:',next(s['storage'] for s in health['services'] if s['service']=='order-service'))
