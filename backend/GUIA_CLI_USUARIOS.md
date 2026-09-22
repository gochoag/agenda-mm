# Guía de Comandos CLI para Gestión de Usuarios

Este proyecto **no utiliza siembra automática ni credenciales por defecto en el código**. 
Tú tienes el control total para crear el usuario Administrador y los CoAdmins mediante los comandos CLI de Flask.

---

## 1. Comandos Disponibles

### Modo Rápido con `pnpm` (Entorno Local)

Desde la raíz del proyecto (`agenda-mm/`):

#### Crear Usuario Administrador:
```bash
# Modo interactivo (te solicita usuario y contraseña oculta con confirmación)
pnpm run backend:create-admin

# O pasando los argumentos directamente:
uv run flask --app backend.app create-admin mi_admin mi_contraseña_segura
```

#### Listar Usuarios Registrados:
```bash
pnpm run backend:list-users
```
*Muestra el ID, nombre de usuario, rol (`admin` o `coadmin`) y fecha de registro.*

#### Crear CoAdmin por CLI (Opcional):
```bash
# Modo interactivo
pnpm run backend:create-coadmin

# O pasando argumentos:
uv run flask --app backend.app create-coadmin coadmin1 clave123
```

---

## 2. Creación de Múltiples CoAdmins desde la App Móvil

El Administrador tiene la capacidad de crear y gestionar **múltiples CoAdmins** directamente desde la aplicación Android:

1. Inicia sesión en la App Móvil con las credenciales de tu **Admin**.
2. Ve a la pestaña **Administración** (icono de escudo en la barra inferior).
3. En la sección **"Gestión de Usuarios y Contraseñas"**, presiona el botón azul:
   👉 **"Crear Nuevo CoAdmin"**
4. Ingresa el nombre del nuevo CoAdmin y su contraseña.
5. ¡Listo! El nuevo CoAdmin podrá ingresar a su cuenta inmediatamente.
6. En la lista de usuarios, el Admin puede:
   - Cambiarle la contraseña en cualquier momento (icono de llave 🔑).
   - Eliminar al CoAdmin si ya no requiere acceso (icono de papelera 🗑️).

---

## 3. Ejecución en PythonAnywhere (Consola Bash)

Cuando estés en el servidor de PythonAnywhere:

```bash
# 1. Activar el entorno virtual
workon agenda-env

# 2. Ir a la carpeta del proyecto
cd /home/tu_usuario/agenda-mm

# 3. Crear tu Administrador
flask --app backend.app create-admin

# 4. Verificar
flask --app backend.app list-users
```

---

## 4. Seguridad de Contraseñas
- Todas las contraseñas se almacenan con hash criptográfico unidireccional utilizando **Werkzeug Security** (algoritmo PBKDF2/Scrypt con salt aleatorio).
- Nunca se almacenan contraseñas en texto plano.
