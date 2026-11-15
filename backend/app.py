import os
import sys

# Asegurar que el directorio raíz esté en sys.path para importaciones
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv

# Cargar variables de entorno si existen
load_dotenv()

from flask_migrate import Migrate
from backend.models import db, User
from backend.limiter import limiter
from backend.routes.auth import auth_bp
from backend.routes.calendar import calendar_bp
from backend.routes.notes import notes_bp
from backend.routes.admin import admin_bp
from backend.routes.covers import covers_bp

migrate = Migrate()

def create_app():
    app = Flask(__name__)

    base_dir = os.path.abspath(os.path.dirname(__file__))
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        app.config['SQLALCHEMY_DATABASE_URI'] = database_url
        # (2 + 2) conexiones x 1 proceso x 2 versiones (azul/verde) = 8, bajo el límite de 20 del usuario en Postgres
        app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
            'pool_size': 2, 'max_overflow': 2, 'pool_timeout': 10, 'pool_pre_ping': True, 'pool_recycle': 1800,
        }
    else:
        # Desarrollo local y pruebas: SQLite
        db_path = os.environ.get('DATABASE_PATH', os.path.join(base_dir, 'agenda.db'))
        app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Sin valor por defecto: el repositorio es público y una clave conocida permitiría falsificar tokens de admin
    jwt_secret = os.environ.get('JWT_SECRET_KEY', '')
    if len(jwt_secret) < 32:
        raise RuntimeError('JWT_SECRET_KEY es obligatoria y debe tener al menos 32 caracteres')
    app.config['JWT_SECRET_KEY'] = jwt_secret

    # Ninguna petición legítima (ni la restauración de respaldo) pasa de esto; evita agotar RAM y disco
    app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024
    app.config['RATELIMIT_ENABLED'] = os.environ.get('RATELIMIT_ENABLED', '1') != '0'
    app.config['RATELIMIT_HEADERS_ENABLED'] = True

    # Sin CORS: la app móvil no lo necesita y no hay cliente web
    db.init_app(app)
    migrate.init_app(app, db, directory=os.path.join(base_dir, 'migrations'))
    JWTManager(app)
    limiter.init_app(app)

    # Registrar blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(calendar_bp)
    app.register_blueprint(notes_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(covers_bp)

    @app.route('/')
    def root():
        return jsonify({'name': 'Agenda MM - API REST', 'status': 'online'})

    @app.route('/api/health')
    @limiter.exempt
    def health():
        # Sin consultar la base: si Postgres cae un momento, Docker no debe reiniciar la app en bucle
        return jsonify({'status': 'ok'}), 200

    @app.errorhandler(413)
    def too_large(_e):
        return jsonify({'error': 'La petición es demasiado grande'}), 413

    @app.errorhandler(429)
    def too_many(_e):
        return jsonify({'error': 'Demasiadas peticiones. Espera un momento e inténtalo de nuevo.'}), 429

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
    # Solo desarrollo local: host='0.0.0.0' para probar desde el celular en la misma red Wi-Fi
    print(f"Iniciando Agenda MM API en http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=True)
