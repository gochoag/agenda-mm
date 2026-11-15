# Despliegue de producción de agendamm

- **Qué se despliega**: la API REST (Flask + gunicorn) que consume la app Android. No hay web.
- **Dominio**: `https://agendamm.ochylabs.top`
- **Imagen**: construida desde `backend/Dockerfile` (contexto `backend/`) por GitHub Actions.
- **Salud**: `GET /api/health` (sin base de datos ni autenticación).
- **Base de datos**: Postgres compartido.
- **Migraciones**: `flask --app backend.app db upgrade` (servicio `migrate`). Compatibles con la versión anterior (2.8).
- **Archivos**: ninguno; no usa `data/`.

## Variables (`.env` en el VPS)

| Variable | Para qué | Quién la genera |
|---|---|---|
| `DATABASE_URL` | Conexión a Postgres. Debe empezar por `postgresql://` | admin (`vps-new-db`) |
| `JWT_SECRET_KEY` | Firma de los tokens de sesión (mínimo 32 caracteres; sin ella la app no arranca) | admin (`openssl rand -base64 48`) |

## Protección del VPS

- gunicorn con 2 workers, `--timeout 30` y reciclado de workers cada ~1000 peticiones.
- Pool de Postgres: (2 + 2) conexiones × 2 workers × 2 versiones = 16, bajo el límite de 20.
- Rate limit por IP real (`CF-Connecting-IP`): 120 peticiones/min en general y 5/min (30/hora) en el login. Los contadores están en memoria de cada worker, así que el límite real puede llegar a 4× ese valor.
- Peticiones de más de 2 MB se rechazan con 413.

## Carga inicial de datos (una vez)

Tras el primer despliegue (las tablas ya existen) y con el túnel de la guía 03, 3.7:

```powershell
python deploy/migrar_sqlite_a_postgres.py C:\ruta\agenda.db   # pide la URL de Postgres oculta (127.0.0.1:15432)
```

Copia todo en una transacción, ajusta las secuencias de los ID, compara conteos y se niega si las tablas ya tienen datos.

## Operación

- Comandos dentro del contenedor activo (el color lo muestra `vps-status`):
  - `docker exec -it agendamm-<color>-app-1 flask --app backend.app create-admin`
  - `docker exec -it agendamm-<color>-app-1 flask --app backend.app list-users`
