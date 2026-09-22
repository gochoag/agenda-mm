import os
import sys

# Asegurar que el directorio raíz esté en sys.path para importaciones
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv

# Cargar variables de entorno si existen
load_dotenv()

from flask_migrate import Migrate
from backend.models import db, User
from backend.routes.auth import auth_bp
from backend.routes.calendar import calendar_bp
from backend.routes.notes import notes_bp
from backend.routes.admin import admin_bp

migrate = Migrate()

def create_app():
    app = Flask(__name__)

    # Configuración de base de datos SQLite
    # Permite especificar ruta absoluta mediante variable de entorno (ideal para PythonAnywhere)
    base_dir = os.path.abspath(os.path.dirname(__file__))
    default_db_path = os.path.join(base_dir, 'agenda.db')
    db_path = os.environ.get('DATABASE_PATH', default_db_path)

    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Configuración de JWT (clave segura de más de 32 bytes)
    app.config['JWT_SECRET_KEY'] = os.environ.get(
        'JWT_SECRET_KEY',
        'agenda-mm-super-secret-key-2026-production-grade-security-hash-token-pa'
    )

    # Inicializar extensiones
    CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)
    db.init_app(app)
    migrate.init_app(app, db, directory=os.path.join(base_dir, 'migrations'))
    JWTManager(app)

    # Registrar blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(calendar_bp)
    app.register_blueprint(notes_bp)
    app.register_blueprint(admin_bp)

    @app.route('/')
    def root():
        return jsonify({
            'name': 'Agenda MM - API REST',
            'status': 'online',
            'endpoints': {
                'auth': '/api/auth/login',
                'calendar': '/api/calendar',
                'notes': '/api/notes',
                'admin': '/api/admin'
            }
        })

    @app.route('/api/health')
    def health():
        return jsonify({'status': 'ok', 'database': 'connected'}), 200


    # Comandos CLI de Flask
    _register_cli_commands(app)

    return app


def _register_cli_commands(app):
    import click

    @app.cli.command('create-admin')
    @click.argument('username', required=False)
    @click.argument('password', required=False)
    def create_admin(username, password):
        """Crea un usuario Administrador con contraseña encriptada"""
        if not username:
            username = click.prompt('Nombre de usuario para el Administrador', type=str).strip()
        if not password:
            password = click.prompt('Contraseña para el Administrador', hide_input=True, confirmation_prompt=True)

        if not username or not password:
            click.echo("Error: Usuario y contraseña no pueden estar vacíos.", err=True)
            return

        with app.app_context():
            if User.query.filter_by(username=username).first():
                click.echo(f"Error: El usuario '{username}' ya existe.", err=True)
                return

            admin_user = User(username=username, role='admin')
            admin_user.set_password(password)
            db.session.add(admin_user)
            db.session.commit()
            click.echo(f"¡Administrador '{username}' creado exitosamente!")

    @app.cli.command('create-coadmin')
    @click.argument('username', required=False)
    @click.argument('password', required=False)
    def create_coadmin(username, password):
        """Crea un usuario CoAdmin con contraseña encriptada"""
        if not username:
            username = click.prompt('Nombre de usuario para el CoAdmin', type=str).strip()
        if not password:
            password = click.prompt('Contraseña para el CoAdmin', hide_input=True, confirmation_prompt=True)

        if not username or not password:
            click.echo("Error: Usuario y contraseña no pueden estar vacíos.", err=True)
            return

        with app.app_context():
            if User.query.filter_by(username=username).first():
                click.echo(f"Error: El usuario '{username}' ya existe.", err=True)
                return

            coadmin_user = User(username=username, role='coadmin')
            coadmin_user.set_password(password)
            db.session.add(coadmin_user)
            db.session.commit()
            click.echo(f"¡CoAdmin '{username}' creado exitosamente!")

    @app.cli.command('list-users')
    def list_users():
        """Lista los usuarios registrados en la base de datos"""
        with app.app_context():
            users = User.query.order_by(User.id.asc()).all()
            if not users:
                click.echo("No hay usuarios registrados en la base de datos.")
                return

            click.echo("\n--- Usuarios Registrados ---")
            for u in users:
                click.echo(f"ID: {u.id} | Usuario: {u.username} | Rol: {u.role} | Creado: {u.created_at}")
            click.echo("-----------------------------\n")


app = create_app()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    # host='0.0.0.0' para permitir pruebas desde el celular en la misma red local Wi-Fi
    print(f"Iniciando Agenda MM API en http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=True)
