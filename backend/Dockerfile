# A partir de infra-vps-tecnomovil/plantillas/Dockerfile (guía 02, 2.4: Python).
# Contexto del build: backend/. El código queda en /app/backend porque se importa como paquete "backend".

# --- Etapa 1: instala dependencias ---
FROM python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Etapa 2: solo lo necesario para ejecutar ---
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 FLASK_DEBUG=0
COPY --from=build /install /usr/local
COPY . /app/backend
# FIJO: el VPS ejecuta como 10001 (2.2, regla 4); la app solo escribe en /tmp o en data/
USER 10001:10001
# FIJO: tu app escucha en 0.0.0.0:8000 dentro del contenedor
EXPOSE 8000
# 1 proceso con 4 hilos: rate limit exacto (contadores en memoria) y menos RAM que 2 workers. --timeout corta peticiones colgadas; --max-requests recicla workers ante fugas de memoria;
# --graceful-timeout < 20 s del stop_grace_period para cerrar limpio con SIGTERM; sin socket de control (FS de solo lectura)
CMD ["gunicorn", "--workers", "1", "--worker-class", "gthread", "--threads", "4", "--bind", "0.0.0.0:8000", "--timeout", "30", "--graceful-timeout", "15", "--max-requests", "1000", "--max-requests-jitter", "100", "--access-logfile", "-", "--no-control-socket", "backend.app:app"]
