from datetime import datetime, timezone
from functools import wraps
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from backend.models import db, User, CalendarEvent, StickyNote

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')

def admin_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({'error': 'Acceso denegado: se requieren privilegios de administrador'}), 403
        return fn(*args, **kwargs)
    return wrapper


@admin_bp.route('/users', methods=['GET'])
@admin_required
def list_users():
    users = User.query.order_by(User.id.asc()).all()
    return jsonify({'users': [u.to_dict() for u in users]}), 200


@admin_bp.route('/users', methods=['POST'])
@admin_required
def create_user():
    data = request.get_json(silent=True) or {}
    username = (data.get('username') or '').strip()
    password = (data.get('password') or '').strip()
    role = (data.get('role') or 'coadmin').lower()

    if not username or not password:
        return jsonify({'error': 'El nombre de usuario y la contraseña son requeridos'}), 400

    if len(password) < 4:
        return jsonify({'error': 'La contraseña debe tener al menos 4 caracteres'}), 400

    if role not in ['admin', 'coadmin']:
        role = 'coadmin'

    if User.query.filter_by(username=username).first():
        return jsonify({'error': f'El usuario "{username}" ya existe'}), 400

    new_user = User(username=username, role=role)
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({
        'message': f'Usuario "{username}" ({role}) creado exitosamente',
        'user': new_user.to_dict()
    }), 201


@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_user(user_id):
    current_admin_id = int(get_jwt_identity())
    if user_id == current_admin_id:
        return jsonify({'error': 'No puedes eliminar tu propia cuenta de administrador'}), 400

    user = db.session.get(User, user_id)
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    username = user.username
    db.session.delete(user)
    db.session.commit()
    return jsonify({'message': f'Usuario "{username}" eliminado exitosamente'}), 200


@admin_bp.route('/users/<int:user_id>/password', methods=['PUT'])
@admin_required
def change_user_password(user_id):
    data = request.get_json(silent=True) or {}
    new_password = (data.get('new_password') or '').strip()

    if not new_password or len(new_password) < 4:
        return jsonify({'error': 'La nueva contraseña debe tener al menos 4 caracteres'}), 400

    user = db.session.get(User, user_id)
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    user.set_password(new_password)
    db.session.commit()

    return jsonify({
        'message': f'Contraseña de "{user.username}" actualizada correctamente',
        'user': user.to_dict()
    }), 200


@admin_bp.route('/backup', methods=['GET'])
@admin_required
def export_backup():
    users = User.query.order_by(User.id.asc()).all()
    events = CalendarEvent.query.order_by(CalendarEvent.id.asc()).all()
    notes = StickyNote.query.order_by(StickyNote.id.asc()).all()

    backup_data = {
        'version': '1.0',
        'export_date': datetime.now(timezone.utc).isoformat(),
        'users': [
            {
                'id': u.id,
                'username': u.username,
                'password_hash': u.password_hash,
                'role': u.role,
                'created_at': u.created_at.isoformat() if u.created_at else None
            }
            for u in users
        ],
        'calendar_events': [
            {
                'id': e.id,
                'user_id': e.user_id,
                'username': e.user.username if e.user else None,
                'detail': e.detail,
                'event_date': e.event_date,
                'status': e.status,
                'created_at': e.created_at.isoformat() if e.created_at else None
            }
            for e in events
        ],
        'sticky_notes': [
            {
                'id': n.id,
                'user_id': n.user_id,
                'username': n.user.username if n.user else None,
                'content': n.content,
                'color': n.color,
                'font_family': n.font_family or 'handwriting',
                'is_pinned': n.is_pinned,
                'created_at': n.created_at.isoformat() if n.created_at else None,
                'updated_at': n.updated_at.isoformat() if n.updated_at else None
            }
            for n in notes
        ]
    }

    return jsonify(backup_data), 200


@admin_bp.route('/restore', methods=['POST'])
@admin_required
def restore_backup():
    # Soporta tanto JSON directo en el body como archivo subido (multipart/form-data)
    data = None
    if 'file' in request.files:
        import json
        file = request.files['file']
        try:
            data = json.load(file)
        except Exception as e:
            return jsonify({'error': f'El archivo subido no es un JSON válido: {str(e)}'}), 400
    else:
        data = request.get_json(silent=True)

    if not data or not isinstance(data, dict):
        return jsonify({'error': 'Datos de respaldo inválidos o no proporcionados'}), 400

    backup_users = data.get('users', [])
    backup_events = data.get('calendar_events', [])
    backup_notes = data.get('sticky_notes', [])

    if not backup_users:
        return jsonify({'error': 'El respaldo debe contener al menos la lista de usuarios'}), 400

    try:
        # Transacción de Restauración Limpia
        # 1. Limpiar tablas secundarias
        CalendarEvent.query.delete()
        StickyNote.query.delete()

        # 2. Reconciliar / restaurar usuarios
        # Mapeamos usuarios por username para asociar correctamente
        user_id_map = {}  # backup_user_id -> new/current user_id
        for u_data in backup_users:
            uname = u_data.get('username')
            if not uname:
                continue
            existing_user = User.query.filter_by(username=uname).first()
            if existing_user:
                existing_user.password_hash = u_data.get('password_hash', existing_user.password_hash)
                existing_user.role = u_data.get('role', existing_user.role)
                user_id_map[u_data.get('id')] = existing_user.id
            else:
                new_user = User(
                    username=uname,
                    password_hash=u_data.get('password_hash'),
                    role=u_data.get('role', 'coadmin')
                )
                db.session.add(new_user)
                db.session.flush()  # Para obtener el id generado
                user_id_map[u_data.get('id')] = new_user.id

        # 3. Restaurar eventos de calendario
        for ev_data in backup_events:
            target_user_id = user_id_map.get(ev_data.get('user_id'))
            # Fallback: si no coincide por id, buscar por username
            if not target_user_id and ev_data.get('username'):
                u = User.query.filter_by(username=ev_data['username']).first()
                if u:
                    target_user_id = u.id

            if target_user_id:
                ev = CalendarEvent(
                    user_id=target_user_id,
                    detail=ev_data.get('detail', ''),
                    event_date=ev_data.get('event_date', ''),
                    status=ev_data.get('status', 'pendiente')
                )
                db.session.add(ev)

        # 4. Restaurar notas adhesivas
        for n_data in backup_notes:
            target_user_id = user_id_map.get(n_data.get('user_id'))
            if not target_user_id and n_data.get('username'):
                u = User.query.filter_by(username=n_data['username']).first()
                if u:
                    target_user_id = u.id

            if target_user_id:
                note = StickyNote(
                    user_id=target_user_id,
                    content=n_data.get('content', ''),
                    color=n_data.get('color', '#FFF59D'),
                    font_family=n_data.get('font_family', 'handwriting'),
                    is_pinned=bool(n_data.get('is_pinned', False))
                )
                db.session.add(note)

        db.session.commit()

        return jsonify({
            'message': 'Restauración completada con éxito',
            'restored': {
                'users_count': len(backup_users),
                'events_count': len(backup_events),
                'notes_count': len(backup_notes)
            }
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Error al restaurar la base de datos: {str(e)}'}), 500
