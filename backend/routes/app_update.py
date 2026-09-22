import os
import json
from flask import Blueprint, jsonify, request, send_from_directory, current_app

app_update_bp = Blueprint('app_update', __name__, url_prefix='/api/app')

def _get_version_config_path():
    # Ruta base de la carpeta backend
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    return os.path.join(base_dir, 'version.json')

def _get_apk_directory():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    apk_dir = os.path.join(base_dir, 'static', 'apk')
    os.makedirs(apk_dir, exist_ok=True)
    return apk_dir

def _read_version_data():
    config_path = _get_version_config_path()
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            current_app.logger.error(f"Error al leer version.json: {e}")

    # Fallback por defecto si no existe o falla la lectura
    return {
        "version_code": 2,
        "version_name": "1.0.1",
        "min_supported_version_code": 1,
        "force_update": False,
        "release_notes": "✨ Carátulas mensuales estilo Bullet Journal con Canva editable artesanal, seccionado por mes para notas y tareas, y pantalla de inicio dinámica.",
        "apk_filename": "agenda-latest.apk"
    }

@app_update_bp.route('/version', methods=['GET'])
def get_version():
    """Devuelve la información de la última versión disponible de la app móvil."""
    data = _read_version_data()

    # Construir la URL de descarga basada en la petición actual
    # Esto asegura que funcione tanto en localhost, 10.0.2.2, red local o PythonAnywhere
    host_url = request.host_url.rstrip('/')
    download_url = f"{host_url}/api/app/download"

    apk_dir = _get_apk_directory()
    apk_filename = data.get('apk_filename', 'agenda-latest.apk')
    apk_exists = os.path.isfile(os.path.join(apk_dir, apk_filename))

    return jsonify({
        "version_code": data.get("version_code", 2),
        "version_name": data.get("version_name", "1.0.1"),
        "min_supported_version_code": data.get("min_supported_version_code", 1),
        "force_update": data.get("force_update", False),
        "release_notes": data.get("release_notes", ""),
        "download_url": download_url,
        "apk_available": apk_exists
    }), 200

@app_update_bp.route('/download', methods=['GET'])
def download_apk():
    """Descarga el archivo APK de la última versión."""
    data = _read_version_data()
    apk_dir = _get_apk_directory()
    apk_filename = data.get('apk_filename', 'agenda-latest.apk')
    apk_path = os.path.join(apk_dir, apk_filename)

    if not os.path.isfile(apk_path):
        return jsonify({
            "error": "El instalador APK de la actualización aún no está disponible en el servidor.",
            "apk_filename": apk_filename
        }), 404

    return send_from_directory(
        directory=apk_dir,
        path=apk_filename,
        as_attachment=True,
        mimetype='application/vnd.android.package-archive',
        download_name=apk_filename
    )
