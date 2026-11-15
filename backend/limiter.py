from flask import request
from flask_limiter import Limiter


def client_ip():
    # nginx solo acepta tráfico de Cloudflare (Authenticated Origin Pulls): CF-Connecting-IP es la IP real del cliente
    return request.headers.get('CF-Connecting-IP') or request.remote_addr or '127.0.0.1'


# shortcut: contadores en memoria del proceso (gunicorn corre 1 proceso con hilos). Durante un despliegue conviven
# 2 versiones y el límite puede llegar a 2x unos segundos; pasar a Redis en servicios.yml si se escala a más procesos
limiter = Limiter(key_func=client_ip, default_limits=['120 per minute'], storage_uri='memory://')
