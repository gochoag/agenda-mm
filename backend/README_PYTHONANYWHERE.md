# 🚀 Guía de PythonAnywhere (Agenda MM)

Esta guía contiene:
1. **Flujo Rápido:** Pasos para cuando hagas cambios futuros y quieras actualizar el backend o lanzar una nueva versión de la app móvil (OTA) sin complicaciones.
2. **Despliegue Inicial:** Pasos paso a paso si configuras una cuenta nueva desde cero en PythonAnywhere.

---

## ⚡ Flujo Rápido de Actualizaciones

Elige el escenario correspondiente según lo que hayas modificado:

---

### 📱 Escenario 1: Modificaste la App Móvil (Flutter) y quieres lanzar una Nueva Versión (OTA)

Usa este flujo cuando agregues pantallas, cambies el diseño, o agregues funciones a la app móvil:

#### En tu Computadora Local (Terminal VS Code):
1. **Verifica la URL de producción en la app:**
   Abre `agenda_app/.env` y asegúrate de que apunte a PythonAnywhere:
   ```env
   API_BASE_URL=https://feilmcqueen.pythonanywhere.com
   ```

2. **Incrementa el número de versión:**
   - En `agenda_app/pubspec.yaml`: incrementa la versión (ej. `version: 1.0.2+3`).
   - En `backend/version.json`: actualiza los campos:
     ```json
     {
       "version_code": 3,
       "version_name": "1.0.2",
       "release_notes": "Novedades: mejoras en carátulas y diseño.",
       "download_url": "https://feilmcqueen.pythonanywhere.com/api/app-update/download",
       "force_update": false
     }
     ```

3. **Compilar y copiar el APK en un solo paso:**
   ```powershell
   pnpm run android:release-apk
   ```
   *(Este comando compila el APK release y lo copia automáticamente a `backend/static/apk/agenda-latest.apk`).*

4. **Subir los cambios a GitHub:**
   ```bash
   git add .
   git commit -m "feat(release): lanzar nueva version v1.0.2"
   git push origin main
   ```
   *(Nota: `.gitignore` ya está configurado con `!backend/static/apk/*.apk`, por lo que git incluirá el APK automáticamente).*

#### En PythonAnywhere:
1. Abre tu consola **Bash** en [PythonAnywhere Consoles](https://www.pythonanywhere.com/user/feilmcqueen/consoles/) y corre:
   ```bash
   cd ~/agenda-mm && git pull
   ```
2. Ve a la pestaña **Web** y haz clic en el botón verde **"Reload feilmcqueen.pythonanywhere.com"**.

🎉 **¡Listo!** En cuanto los usuarios abran la app móvil, detectará la nueva versión y les mostrará el aviso para actualizar automáticamente.

---

### ⚙️ Escenario 2: Modificaste solo el Backend (Python / Flask / Base de Datos)

Usa este flujo cuando agregues rutas, corrijas lógica en Python o alteres tablas de la base de datos:

#### En tu Computadora Local (Terminal VS Code):
1. **Si modificaste tablas en `backend/models.py`:**
   Genera la migración y aplícala localmente para verificar que funcione:
   ```powershell
   pnpm run backend:db:migrate -- -m "descripcion_del_cambio"
   pnpm run backend:db:upgrade
   ```

2. **Sube los cambios a GitHub:**
   ```bash
   git add .
   git commit -m "fix(backend): detalle del cambio"
   git push origin main
   ```

#### En PythonAnywhere:
1. Abre tu consola **Bash** en PythonAnywhere y pega este comando único (hace todo de un solo golpe):
   ```bash
   cd ~/agenda-mm && git pull && workon agenda-env && pip install -r backend/requirements.txt && flask --app backend.app db upgrade --directory backend/migrations
   ```

2. Ve a la pestaña **Web** y haz clic en el botón verde **"Reload feilmcqueen.pythonanywhere.com"**.

🎉 **¡Listo!** Tu backend y base de datos estarán sincronizados y corriendo la última versión.

---
---

## 🛠️ Guía de Despliegue Inicial (Desde Cero)

Sigue estos pasos únicamente si estás configurando el servidor por primera vez en una cuenta nueva de PythonAnywhere.

### Paso 1: Abrir Consola Bash
1. Inicia sesión en [PythonAnywhere](https://www.pythonanywhere.com/).
2. Dirígete a la pestaña **Consoles** y abre una consola **Bash**.

### Paso 2: Clonar el Repositorio
```bash
git clone <URL_DE_TU_REPOSITORIO> agenda-mm
cd agenda-mm
```

### Paso 3: Crear Virtualenv e Instalar Dependencias
```bash
mkvirtualenv --python=python3.11 agenda-env
pip install -r backend/requirements.txt
```

### Paso 4: Configurar la App Web en PythonAnywhere
1. Ve a la pestaña **Web** en PythonAnywhere.
2. Haz clic en **Add a new web app**.
3. Selecciona **Manual configuration** y **Python 3.11**.
4. En la sección de rutas configura:
   - **Source code:** `/home/tu_usuario/agenda-mm`
   - **Working directory:** `/home/tu_usuario/agenda-mm`
   - **Virtualenv:** `/home/tu_usuario/.virtualenvs/agenda-env`

### Paso 5: Configurar el archivo WSGI
En la pestaña Web, haz clic en el enlace de **WSGI configuration file** (`/var/www/tu_usuario_pythonanywhere_com_wsgi.py`), borra todo su contenido y pega:

```python
import sys
import os

project_home = '/home/tu_usuario/agenda-mm'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# Ruta permanente de la base de datos persistente
os.environ['DATABASE_PATH'] = '/home/tu_usuario/agenda-mm/backend/agenda.db'
os.environ['JWT_SECRET_KEY'] = 'agenda-mm-super-secret-key-2026-production-grade-security-hash-token-pa'

from backend.app import app as application
```
*(Reemplaza `tu_usuario` por tu nombre exacto de usuario en PythonAnywhere y guarda con **Save**).*

### Paso 6: Ejecutar las Migraciones
En la consola Bash:
```bash
workon agenda-env
cd ~/agenda-mm
flask --app backend.app db upgrade --directory backend/migrations
```

### Paso 7: Crear el Usuario Administrador
```bash
flask --app backend.app create-admin
```
Te pedirá interactivamente el usuario y la contraseña con confirmación.

### Paso 8: Recargar la Web App
En la pestaña **Web**, pulsa el botón verde **Reload tu_usuario.pythonanywhere.com**.
Verifica ingresando a:
`https://tu_usuario.pythonanywhere.com/api/health` (debe responder `{"status":"ok","database":"connected"}`).
