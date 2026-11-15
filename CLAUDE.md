# Agenda MM

API Flask (`backend/`) + app Flutter Android (`agenda_app/`). Reglas de estilo y producto en [.agents/rules/project_guidelines.md](.agents/rules/project_guidelines.md).

## Git: nunca lo ejecuta el asistente

- No correr ningún comando `git` ni `gh` que cambie estado (add, commit, switch, push, pull, merge, pr create...).
- Dar los comandos al usuario **uno por bloque**, en orden, diciendo qué hace cada uno y qué debe salir. Usa Git Bash.
- Un "sí" o "listo" a otra pregunta no es permiso para ejecutar git.

## Producción

- API en el VPS del equipo: `https://agendamm.ochylabs.top` (salud: `/api/health`). Ya no se usa PythonAnywhere.
- Infra y guía: repo `JuanRZAR/infra-vps-tecnomovil` (carpeta vecina `../infra-vps-tecnomovil`). El proyecto se llama `agendamm` en su `projects.yml`.
- Merge a `main` despliega la API (`.github/workflows/deploy.yml`) y, si cambia `agenda_app/`, publica el APK como GitHub Release (`.github/workflows/apk.yml`).
- Detalles de variables, límites y carga de datos: [deploy/deploy-produccion/README.md](deploy/deploy-produccion/README.md).

## Pruebas

- `python -m unittest backend.test_api` (con `TEST_DATABASE_URL` apunta a Postgres; sin ella, SQLite).
