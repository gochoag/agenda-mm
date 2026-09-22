from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from backend.models import db, CalendarEvent, User

calendar_bp = Blueprint('calendar', __name__, url_prefix='/api/calendar')

@calendar_bp.route('', methods=['GET'])
@jwt_required()
def get_events():
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    # Query base
    query = CalendarEvent.query

    # Si es CoAdmin, solo ve sus propios eventos
    if role == 'coadmin':
        query = query.filter_by(user_id=user_id)
    else:
        # Es Admin: puede filtrar opcionalmente por usuario si lo desea (?user_id=...)
        target_user_id = request.args.get('user_id', type=int)
        if target_user_id:
            query = query.filter_by(user_id=target_user_id)

    # Ordenar por fecha cronológica ascendente
    events = query.order_by(CalendarEvent.event_date.asc(), CalendarEvent.id.asc()).all()
    return jsonify({'events': [e.to_dict() for e in events]}), 200


@calendar_bp.route('', methods=['POST'])
@jwt_required()
def create_event():
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    detail = (data.get('detail') or '').strip()
    event_date = (data.get('event_date') or '').strip()
    status = data.get('status', 'pendiente')

    if not detail or not event_date:
        return jsonify({'error': 'El detalle y la fecha son requeridos'}), 400

    # Permitir que el admin asigne el evento a otro usuario si lo especifica
    claims = get_jwt()
    role = claims.get('role', 'coadmin')
    assigned_user_id = user_id
    if role == 'admin' and 'user_id' in data and data['user_id']:
        target_user = User.query.get(data['user_id'])
        if target_user:
            assigned_user_id = target_user.id

    event = CalendarEvent(
        user_id=assigned_user_id,
        detail=detail,
        event_date=event_date,
        status=status
    )
    db.session.add(event)
    db.session.commit()

    return jsonify({'message': 'Evento creado exitosamente', 'event': event.to_dict()}), 201


@calendar_bp.route('/<int:event_id>', methods=['PUT'])
@jwt_required()
def update_event(event_id):
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    event = db.session.get(CalendarEvent, event_id)
    if not event:
        return jsonify({'error': 'Evento no encontrado'}), 404

    # CoAdmin solo puede modificar sus propios eventos
    if role == 'coadmin' and event.user_id != user_id:
        return jsonify({'error': 'No tienes permiso para modificar este evento'}), 403

    data = request.get_json(silent=True) or {}
    if 'detail' in data:
        event.detail = (data.get('detail') or '').strip()
    if 'event_date' in data:
        event.event_date = (data.get('event_date') or '').strip()
    if 'status' in data:
        event.status = data.get('status')

    db.session.commit()
    return jsonify({'message': 'Evento actualizado exitosamente', 'event': event.to_dict()}), 200


@calendar_bp.route('/<int:event_id>', methods=['DELETE'])
@jwt_required()
def delete_event(event_id):
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    event = db.session.get(CalendarEvent, event_id)
    if not event:
        return jsonify({'error': 'Evento no encontrado'}), 404

    # CoAdmin solo puede eliminar sus propios eventos
    if role == 'coadmin' and event.user_id != user_id:
        return jsonify({'error': 'No tienes permiso para eliminar este evento'}), 403

    db.session.delete(event)
    db.session.commit()
    return jsonify({'message': 'Evento eliminado exitosamente'}), 200
