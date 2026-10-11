import importlib.util
from pathlib import Path
from unittest.mock import Mock
import pytest
import requests

ROOT=Path(__file__).resolve().parents[1]
def load(name,folder):
    spec=importlib.util.spec_from_file_location(name,ROOT/'services'/folder/'app.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

@pytest.fixture
def order(tmp_path,monkeypatch):
    monkeypatch.setenv('DB_MODE','sqlite');monkeypatch.setenv('SQLITE_PATH',str(tmp_path/'orders.db'))
    m=load('order_test','order-service')
    catalog=load('product_test','product-service').PRODUCTS
    response=Mock();response.json.return_value=catalog;response.raise_for_status.return_value=None
    monkeypatch.setattr(m.requests,'get',lambda *a,**k:response)
    return m,m.app.test_client()

def test_checkout_uses_server_price_and_retries_once(order):
    m,c=order;payload={'items':[{'product_id':1,'quantity':2,'price':'0.01'}]};h={'Idempotency-Key':'test-order-key-1'}
    first=c.post('/api/orders',json=payload,headers=h)
    assert first.status_code==201 and first.json['total']=='4998.00'
    retry=c.post('/api/orders',json=payload,headers=h)
    assert retry.status_code==200 and retry.json['id']==first.json['id']
    assert len(c.get('/api/orders').json)==1
    changed=c.post('/api/orders',json={'items':[{'product_id':1,'quantity':1}]},headers=h)
    assert changed.status_code==409

@pytest.mark.parametrize('payload',[{},[],{'items':[]},{'items':[{'product_id':1,'quantity':True}]},{'items':[{'product_id':1,'quantity':-1}]},{'items':[{'product_id':999,'quantity':1}]},{'items':[{'product_id':1,'quantity':25}]}])
def test_bad_cart_does_not_create_order(order,payload):
    _,c=order
    assert c.post('/api/orders',json=payload,headers={'Idempotency-Key':'invalid-cart-key'}).status_code==400
    assert c.get('/api/orders').json==[]

def test_product_outage_is_visible_and_recoverable(order,monkeypatch):
    m,c=order
    def outage(*a,**k):raise requests.ConnectionError('unreachable')
    monkeypatch.setattr(m.requests,'get',outage)
    assert c.post('/api/orders',json={'items':[{'product_id':1,'quantity':1}]},headers={'Idempotency-Key':'outage-request-key'}).status_code==503
    assert c.get('/api/orders').json==[]

def test_persistence_across_service_reload(order):
    _,c=order
    made=c.post('/api/orders',json={'items':[{'product_id':3,'quantity':1}]},headers={'Idempotency-Key':'persist-request-key'}).json
    restarted=load('order_restarted','order-service').app.test_client()
    assert restarted.get('/api/orders').json[0]['id']==made['id']

def test_missing_idempotency_key(order):
    _,c=order
    assert c.post('/api/orders',json={'items':[{'product_id':1,'quantity':1}]}).status_code==400

def test_gateway_reports_service_failure(monkeypatch):
    m=load('front_test','frontend')
    def outage(*a,**k):raise requests.ConnectionError()
    monkeypatch.setattr(m.requests,'request',outage)
    assert m.app.test_client().get('/api/products').status_code==503
    monkeypatch.setattr(m.requests,'get',outage)
    result=m.app.test_client().get('/api/inspector').json
    assert all(s['status']=='unavailable' and s['latency_ms'] is None for s in result['services'])

def test_duplicate_lines_are_aggregated(order):
    _,c=order
    r=c.post('/api/orders',json={'items':[{'product_id':3,'quantity':1},{'product_id':3,'quantity':2}]},headers={'Idempotency-Key':'duplicate-lines-key'})
    assert r.json['total']=='2097.00' and len(r.json['items'])==1

def test_load_demo_disabled_by_default(order,monkeypatch):
    _,c=order;monkeypatch.delenv('ENABLE_LOAD_DEMO',raising=False)
    assert c.post('/api/demo/load').status_code==404
