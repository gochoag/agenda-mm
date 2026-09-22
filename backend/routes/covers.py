import json
from datetime import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from backend.models import db, MonthlyCover, StickyNote, CalendarEvent, User

covers_bp = Blueprint('covers', __name__, url_prefix='/api/covers')

SPANISH_MONTH_NAMES = {
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre'
}

DEFAULT_MONTH_QUOTES = {
    1: 'Nuevos comienzos y grandes metas',
    2: 'Constancia, amor y gratitud',
    3: 'Florecer con paciencia y alegría',
    4: 'Tiempo de avanzar paso a paso',
    5: 'Energía positiva y enfoque',
    6: 'Mitad de año, el mejor impulso',
    7: 'Renovación y momentos bonitos',
    8: 'Sueños en marcha y perseverancia',
    9: 'Amor, abundancia y creatividad',
    10: 'Cosechar esfuerzos y disfrutar',
    11: 'Agradecer cada bendición y logro',
    12: 'Paz, celebración y esperanza'
}

def _parse_month_year(month_year_str):
    try:
        dt = datetime.strptime(month_year_str, '%Y-%m')
        return dt.year, dt.month
    except Exception:
        now = datetime.now()
        return now.year, now.month

def get_default_cover_dict(user_id, month_year):
    year, month = _parse_month_year(month_year)
    month_name = SPANISH_MONTH_NAMES.get(month, f'Mes {month}')
    quote = DEFAULT_MONTH_QUOTES.get(month, 'Amor y Abundancia')

    # Plantilla por defecto con estilo artesanal (usada cuando el usuario presiona 'Omitir')
    default_elements = [
        {
            'id': 'title',
            'type': 'text',
            'text': month_name,
            'x': 0.50,
            'y': 0.38,
            'fontSize': 48.0,
            'fontFamily': 'Caveat',
            'color': '#E11D48',
            'rotation': -0.05,
            'scale': 1.0
        },
        {
            'id': 'subtitle',
            'type': 'text',
            'text': quote,
            'x': 0.50,
            'y': 0.52,
            'fontSize': 26.0,
            'fontFamily': 'Caveat',
            'color': '#EAB308',
            'rotation': 0.02,
            'scale': 1.0
        },
        {
            'id': 'year',
            'type': 'text',
            'text': str(year),
            'x': 0.50,
            'y': 0.72,
            'fontSize': 34.0,
            'fontFamily': 'Kalam',
            'color': '#F59E0B',
            'rotation': 0.0,
            'scale': 1.0
        },
        {
            'id': 'spiral_1',
            'type': 'doodle_spiral',
            'x': 0.22,
            'y': 0.28,
            'color': '#9333EA',
            'scale': 1.0,
            'rotation': 0.2
        },
        {
            'id': 'spiral_2',
            'type': 'doodle_spiral',
            'x': 0.78,
            'y': 0.32,
            'color': '#9333EA',
            'scale': 1.0,
            'rotation': -0.3
        },
        {
            'id': 'sparkle_1',
            'type': 'doodle_sparkle',
            'x': 0.32,
            'y': 0.22,
            'color': '#EAB308',
            'scale': 1.1,
            'rotation': 0.0
        },
        {
            'id': 'sparkle_2',
            'type': 'doodle_sparkle',
            'x': 0.72,
            'y': 0.44,
            'color': '#EAB308',
            'scale': 0.9,
            'rotation': 0.4
        }
    ]

    return {
        'id': None,
        'user_id': user_id,
        'month_year': month_year,
        'title': month_name,
        'subtitle': quote,
        'year_text': str(year),
        'background_type': 'grid',
        'background_color': '#FFFDF7',
        'design_data': json.dumps(default_elements),
        'is_custom': False,
        'created_at': None,
        'updated_at': None
    }


@covers_bp.route('', methods=['GET'])
@jwt_required()
def get_cover():
    """Obtiene la carátula de un mes específico para el usuario autenticado."""
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    target_user_id = user_id
    if role == 'admin':
        req_user_id = request.args.get('user_id', type=int)
        if req_user_id:
            target_user_id = req_user_id

    now = datetime.now()
    month_year = (request.args.get('month') or now.strftime('%Y-%m')).strip()

    cover = MonthlyCover.query.filter_by(user_id=target_user_id, month_year=month_year).first()
    if cover:
        data = cover.to_dict()
        data['exists'] = True
        return jsonify(data), 200

    # No tiene carátula creada ni omitida aún en la base de datos
    default_data = get_default_cover_dict(target_user_id, month_year)
    default_data['exists'] = False
    return jsonify(default_data), 200


@covers_bp.route('/default', methods=['POST'])
@jwt_required()
def create_default_cover():
    """Guarda la plantilla por defecto en la base de datos cuando el usuario elige 'Omitir'."""
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    now = datetime.now()
    month_year = (data.get('month_year') or now.strftime('%Y-%m')).strip()

    default_data = get_default_cover_dict(user_id, month_year)

    cover = MonthlyCover.query.filter_by(user_id=user_id, month_year=month_year).first()
    if not cover:
        cover = MonthlyCover(
            user_id=user_id,
            month_year=month_year,
            title=default_data['title'],
            subtitle=default_data['subtitle'],
            year_text=default_data['year_text'],
            background_type=default_data['background_type'],
            background_color=default_data['background_color'],
            design_data=default_data['design_data'],
            is_custom=False
        )
        db.session.add(cover)
    else:
        cover.title = default_data['title']
        cover.subtitle = default_data['subtitle']
        cover.year_text = default_data['year_text']
        cover.background_type = default_data['background_type']
        cover.background_color = default_data['background_color']
        cover.design_data = default_data['design_data']
        cover.is_custom = False

    db.session.commit()
    res = cover.to_dict()
    res['exists'] = True
    return jsonify(res), 200


@covers_bp.route('', methods=['POST'])
@jwt_required()
def save_cover():
    """Crea o actualiza la carátula de un mes."""
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    month_year = (data.get('month_year') or datetime.now().strftime('%Y-%m')).strip()
    title = (data.get('title') or '').strip()
    subtitle = (data.get('subtitle') or '').strip()
    year_text = (data.get('year_text') or '').strip()
    background_type = data.get('background_type', 'grid')
    background_color = data.get('background_color', '#FFFDF7')
    design_data = data.get('design_data', '[]')
    is_custom = bool(data.get('is_custom', True))

    if isinstance(design_data, (list, dict)):
        design_data = json.dumps(design_data)

    cover = MonthlyCover.query.filter_by(user_id=user_id, month_year=month_year).first()
    if not cover:
        cover = MonthlyCover(
            user_id=user_id,
            month_year=month_year,
            title=title,
            subtitle=subtitle,
            year_text=year_text,
            background_type=background_type,
            background_color=background_color,
            design_data=design_data,
            is_custom=is_custom
        )
        db.session.add(cover)
    else:
        cover.title = title
        cover.subtitle = subtitle
        cover.year_text = year_text
        cover.background_type = background_type
        cover.background_color = background_color
        cover.design_data = design_data
        cover.is_custom = is_custom

    db.session.commit()
    return jsonify(cover.to_dict()), 200


@covers_bp.route('/history', methods=['GET'])
@jwt_required()
def get_history_months():
    """Devuelve la lista de meses únicos disponibles en notas, calendario o carátulas."""
    user_id = int(get_jwt_identity())
    claims = get_jwt()
    role = claims.get('role', 'coadmin')

    months_set = set()

    # Agregar mes actual siempre
    current_month = datetime.now().strftime('%Y-%m')
    months_set.add(current_month)

    # Buscar meses de carátulas
    query_c = MonthlyCover.query
    if role == 'coadmin':
        query_c = query_c.filter_by(user_id=user_id)
    for c in query_c.with_entities(MonthlyCover.month_year).all():
        if c[0]:
            months_set.add(c[0])

    # Buscar meses de notas
    query_n = StickyNote.query
    if role == 'coadmin':
        query_n = query_n.filter_by(user_id=user_id)
    for n in query_n.with_entities(StickyNote.month_year, StickyNote.created_at).all():
        if n[0]:
            months_set.add(n[0])
        elif n[1]:
            months_set.add(n[1].strftime('%Y-%m'))

    # Buscar meses de eventos
    query_e = CalendarEvent.query
    if role == 'coadmin':
        query_e = query_e.filter_by(user_id=user_id)
    for e in query_e.with_entities(CalendarEvent.event_date).all():
        if e[0] and len(e[0]) >= 7:
            month_candidate = e[0][:7]
            if '-' in month_candidate:
                months_set.add(month_candidate)

    sorted_months = sorted(list(months_set), reverse=True)

    result = []
    for ym in sorted_months:
        y, m = _parse_month_year(ym)
        result.append({
            'month_year': ym,
            'name': SPANISH_MONTH_NAMES.get(m, f'Mes {m}'),
            'year': y,
            'label': f"{SPANISH_MONTH_NAMES.get(m, f'Mes {m}')} {y}",
            'is_current': ym == current_month
        })

    return jsonify({'months': result}), 200
