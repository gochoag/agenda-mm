# 📅 Agenda MM

Sistema integral de gestión de agenda, eventos de calendario y notas adhesivas interactivas con sincronización multiusuario y roles jerárquicos (Administrador, CoAdmin y Usuarios).

El proyecto está compuesto por:
1. **Backend:** API REST construida en **Flask**, autenticación **JWT**, base de datos relacional **SQLite** y migraciones de base de datos controladas por **Alembic / Flask-Migrate**.
2. **Frontend Móvil:** Aplicación nativa multiplataforma construida en **Flutter**, optimizada para alto rendimiento AOT en Android con notificaciones locales programadas y soporte offline.

---

## 🚀 Arquitectura del Proyecto

```text
agenda-mm/
├── backend/                  # API REST en Flask
│   ├── migrations/           # Migraciones de base de datos versionadas (Alembic)
│   ├── routes/               # Endpoints modulares (auth, calendar, notes, admin)
│   ├── app.py                # Fábrica de la aplicación Flask y comandos CLI
│   ├── models.py             # Modelos SQLAlchemy (User, CalendarEvent, StickyNote)
│   ├── requirements.txt      # Dependencias Python
│   ├── wsgi.py               # Entrada WSGI para producción
│   └── README_PYTHONANYWHERE.md # Guía paso a paso de despliegue en la nube
├── agenda_app/               # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── models/           # Modelos Dart (User, CalendarEvent, StickyNote)
│   │   ├── screens/          # Pantallas (Login, Calendario, Notas, Admin)
│   │   ├── services/         # Servicios de API y Notificaciones locales
│   │   ├── theme/            # Sistema de diseño y temas visuales
│   │   └── widgets/          # Componentes reusables y modales
│   └── pubspec.yaml          # Dependencias y configuración de assets
├── package.json              # Scripts orquestadores (pnpm) para desarrollo y CLI
└── .gitignore                # Reglas de exclusión para control de versiones
```

---

## 🛠️ Requisitos Previos

- **Python 3.11+**
- **Flutter SDK 3.11+**
- **Node.js y pnpm** (opcional, para usar los scripts de conveniencia del `package.json`)

---

## ⚙️ Configuración y Ejecución Local

### 1. Backend (Flask)

```bash
# Crear entorno virtual e instalar dependencias
python -m venv .venv
# Activar entorno virtual (Windows)
.venv\Scripts\activate
# Instalar paquetes
pip install -r backend/requirements.txt

# Aplicar las migraciones de base de datos
flask --app backend.app db upgrade --directory backend/migrations

# Crear el primer usuario Administrador mediante CLI
flask --app backend.app create-admin

# Iniciar servidor de desarrollo
python -m backend.app
# O con pnpm:
pnpm run backend:dev
```

### 2. Frontend Móvil (Flutter)

1. Revisa o edita `agenda_app/.env` con la IP de tu backend:
   ```env
   # Si pruebas en emulador de Android:
   API_BASE_URL=http://10.0.2.2:5000
   # Si pruebas en tu teléfono físico por Wi-Fi:
   API_BASE_URL=http://192.168.X.X:5000
   ```
2. Ejecuta la aplicación:
   ```bash
   cd agenda_app
   flutter pub get
   flutter run
   ```

---

## 📜 Gestión de Migraciones de Base de Datos

Las modificaciones en las tablas y esquemas se gestionan mediante **Flask-Migrate (Alembic)**:

- **Aplicar migraciones pendientes:**
  ```bash
  pnpm run backend:db:upgrade
  ```
- **Generar una nueva migración automática al modificar `backend/models.py`:**
  ```bash
  pnpm run backend:db:migrate -- -m "descripcion_del_cambio"
  ```

---

## ☁️ Despliegue en Producción (PythonAnywhere)

Para desplegar el backend de forma 100% gratuita en PythonAnywhere:
- Consulta la guía detallada paso a paso en [backend/README_PYTHONANYWHERE.md](backend/README_PYTHONANYWHERE.md).
