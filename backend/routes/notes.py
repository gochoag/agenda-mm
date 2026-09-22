from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from backend.models import db, StickyNote, User

notes_bp = Blueprint('notes', __name__, url_prefix='/api/notes')

@notes_bp.route('', methods=['GET'])
@jwt_required()
def get_notes():
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    query = StickyNote.query

    # CoAdmin solo ve sus notas
    if role == 'coadmin':
        query = query.filter_by(user_id=user_id)
    else:
        # Admin puede filtrar por usuario específico (?user_id=...) o ver todas
        target_user_id = request.args.get('user_id', type=int)
        if target_user_id:
            query = query.filter_by(user_id=target_user_id)

    # Filtrar por mes si se especifica (?month=YYYY-MM)
    month = request.args.get('month', type=str)
    if month:
        month = month.strip()
        query = query.filter(
            db.or_(
                StickyNote.month_year == month,
                db.and_(
                    StickyNote.month_year.is_(None),
                    StickyNote.created_at.like(f"{month}%")
                )
            )
        )

    # Ordenar: primero notas fijadas (is_pinned = True), luego por fecha de actualización desc
    notes = query.order_by(StickyNote.is_pinned.desc(), StickyNote.updated_at.desc(), StickyNote.id.desc()).all()
    return jsonify({'notes': [n.to_dict() for n in notes]}), 200


@notes_bp.route('', methods=['POST'])
@jwt_required()
def create_note():
    from datetime import datetime
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    content = (data.get('content') or '').strip()
    color = data.get('color', '#FFF59D')  # Color pastel por defecto
    font_family = data.get('font_family', 'handwriting')
    is_pinned = bool(data.get('is_pinned', False))
    month_year = (data.get('month_year') or datetime.now().strftime('%Y-%m')).strip()

    if not content:
        return jsonify({'error': 'El contenido de la nota no puede estar vacío'}), 400

    claims = get_jwt()
    role = claims.get('role', 'coadmin')
    assigned_user_id = user_id
    if role == 'admin' and 'user_id' in data and data['user_id']:
        target_user = User.query.get(data['user_id'])
        if target_user:
            assigned_user_id = target_user.id

    note = StickyNote(
        user_id=assigned_user_id,
        content=content,
        color=color,
        font_family=font_family,
        is_pinned=is_pinned,
        month_year=month_year
    )
    db.session.add(note)
    db.session.commit()

    return jsonify({'message': 'Nota creada exitosamente', 'note': note.to_dict()}), 201


@notes_bp.route('/<int:note_id>', methods=['PUT'])
@jwt_required()
def update_note(note_id):
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    note = db.session.get(StickyNote, note_id)
    if not note:
        return jsonify({'error': 'Nota no encontrada'}), 404

    # CoAdmin solo modifica sus propias notas
    if role == 'coadmin' and note.user_id != user_id:
        return jsonify({'error': 'No tienes permiso para modificar esta nota'}), 403

    data = request.get_json(silent=True) or {}
    if 'content' in data:
        note.content = (data.get('content') or '').strip()
    if 'color' in data:
        note.color = data.get('color')
    if 'font_family' in data:
        note.font_family = data.get('font_family')
    if 'is_pinned' in data:
        note.is_pinned = bool(data.get('is_pinned'))

    db.session.commit()
    return jsonify({'message': 'Nota actualizada exitosamente', 'note': note.to_dict()}), 200


@notes_bp.route('/<int:note_id>', methods=['DELETE'])
@jwt_required()
def delete_note(note_id):
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    note = db.session.get(StickyNote, note_id)
    if not note:
        return jsonify({'error': 'Nota no encontrada'}), 404

    # CoAdmin solo elimina sus propias notas
    if role == 'coadmin' and note.user_id != user_id:
        return jsonify({'error': 'No tienes permiso para eliminar esta nota'}), 403

    db.session.delete(note)
    db.session.commit()
    return jsonify({'message': 'Nota eliminada exitosamente'}), 200
