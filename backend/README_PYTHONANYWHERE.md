# Guía de Despliegue en PythonAnywhere (Plan Gratuito)

Esta API en Flask y SQLite está 100% optimizada para el plan gratis de PythonAnywhere sin incurrir en ningún costo.

---

### Paso 1: Crear Cuenta y Abrir Consola Bash
1. Inicia sesión en [PythonAnywhere](https://www.pythonanywhere.com/).
2. Dirígete a la pestaña **Consoles** y abre una consola **Bash**.

---

### Paso 2: Subir el Proyecto o Clonar
Puedes clonar tu repositorio o subir la carpeta `backend` directamente:
```bash
git clone <URL_DE_TU_REPOSITORIO> agenda-mm
cd agenda-mm
```

---

### Paso 3: Crear Virtualenv e Instalar Dependencias
En la consola Bash de PythonAnywhere ejecuta:
```bash
mkvirtualenv --python=python3.11 agenda-env
pip install -r backend/requirements.txt
```
*(Nota: la ruta de este entorno virtual será `/home/TU_USUARIO/.virtualenvs/agenda-env`)*

---

### Paso 4: Configurar la App Web en PythonAnywhere
1. Ve a la pestaña **Web** en PythonAnywhere.
2. Haz clic en **Add a new web app**.
3. Elige tu dominio asignado (ejemplo: `tu_usuario.pythonanywhere.com`).
4. Selecciona **Manual configuration** y la versión de Python que elegiste (ejemplo: **Python 3.11**).

---

### Paso 5: Configurar Virtualenv y Directorio de Trabajo
En la misma pestaña **Web**:
- **Source code:** `/home/tu_usuario/agenda-mm`
- **Working directory:** `/home/tu_usuario/agenda-mm`
- **Virtualenv:** `/home/tu_usuario/.virtualenvs/agenda-env`

---

### Paso 6: Configurar el archivo WSGI
En la sección **Code** de la pestaña Web, haz clic en el enlace del archivo **WSGI configuration file** (`/var/www/tu_usuario_pythonanywhere_com_wsgi.py`).

Borra el contenido predeterminado y pega lo siguiente:
```python
import sys
import os

project_home = '/home/tu_usuario/agenda-mm'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# Establecer la ruta permanente de la base de datos SQLite en tu directorio persistente
os.environ['DATABASE_PATH'] = '/home/tu_usuario/agenda-mm/backend/agenda.db'
os.environ['JWT_SECRET_KEY'] = 'tu_clave_secreta_super_segura_de_mas_de_32_caracteres'

from backend.app import app as application
```
*(Reemplaza `tu_usuario` por tu nombre de usuario exacto en PythonAnywhere)*.

Guarda los cambios con **Save**.

---

---

### Paso 7: Ejecutar las Migraciones de Base de Datos
En la consola **Bash** de PythonAnywhere, ejecuta:
```bash
workon agenda-env
cd /home/tu_usuario/agenda-mm
flask --app backend.app db upgrade --directory backend/migrations
```
Esto creará automáticamente el archivo de base de datos `agenda.db` con todas las tablas versionadas (`users`, `calendar_events`, `sticky_notes`).

---

### Paso 8: Crear el Usuario Administrador Inicial
En la misma consola **Bash**, ejecuta:
```bash
flask --app backend.app create-admin
```
Te pedirá interactivamente el **nombre de usuario** y la **contraseña** (con confirmación oculta).

También puedes crearlo directamente en una sola línea si prefieres:
```bash
flask --app backend.app create-admin mi_admin mi_clave_segura
```

Para verificar los usuarios creados:
```bash
flask --app backend.app list-users
```

---

### Paso 9: Recargar la Web App
1. Regresa a la pestaña **Web** de PythonAnywhere.
2. Haz clic en el botón verde **Reload tu_usuario.pythonanywhere.com**.

¡Listo! Tu API estará disponible en vivo en:
`https://tu_usuario.pythonanywhere.com/`

Puedes probarla ingresando desde el navegador a:
`https://tu_usuario.pythonanywhere.com/api/health` (debe responder `{"status":"ok","database":"connected"}`).

---

### Paso 10: Conectar la App Móvil Flutter
En tu computadora local:
1. Abre el archivo `agenda_app/.env` y reemplaza la IP local por tu dominio HTTPS:
   ```env
   API_BASE_URL=https://tu_usuario.pythonanywhere.com
   ```
2. Compila el APK para tu celular:
   ```bash
   cd agenda_app
   flutter build apk --release
   ```
3. Instala el APK en tu celular. ¡Tu app ya estará funcionando conectada a la nube 24/7 sin depender de tu PC!
