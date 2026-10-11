"""Three real local services, SQLite fallback. No Docker/Kubernetes claims."""
import os,subprocess,sys,time,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parents[1]
env=os.environ.copy();env.update(PRODUCT_SERVICE_URL='http://127.0.0.1:5001',ORDER_SERVICE_URL='http://127.0.0.1:5002',BIND_ADDRESS='127.0.0.1',DB_MODE='sqlite',SQLITE_PATH=str(root/'cloudmart-demo.db'),DEPLOYMENT_MODE='local-demo (SQLite, no containers)',ENABLE_LOAD_DEMO='false')
processes=[]
try:
    for service in ['product-service','order-service','frontend']:
        processes.append(subprocess.Popen([sys.executable,'app.py'],cwd=root/'services'/service,env=env))
    for _ in range(40):
        if any(p.poll() is not None for p in processes):raise RuntimeError('A service stopped. Check for occupied ports 5000, 5001, 5002.')
        try:
            for port in [5001,5002,5000]:urllib.request.urlopen(f'http://127.0.0.1:{port}/readyz',timeout=1)
            break
        except Exception:time.sleep(.5)
    else:raise RuntimeError('Local services did not become ready')
    print('\nCloudMart: http://localhost:5000\nSQLite demo only. Ctrl+C stops all services.\n',flush=True)
    while all(p.poll() is None for p in processes):time.sleep(1)
except KeyboardInterrupt:pass
finally:
    for p in processes:
        if p.poll() is None:p.terminate()
    for p in processes:
        try:p.wait(timeout=5)
        except subprocess.TimeoutExpired:p.kill()
