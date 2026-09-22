from datetime import datetime, timezone
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

def utc_now():
    return datetime.now(timezone.utc)

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False, default='coadmin')  # 'admin' o 'coadmin'
    created_at = db.Column(db.DateTime, default=utc_now)

    # Relaciones
    events = db.relationship('CalendarEvent', backref='user', cascade='all, delete-orphan', lazy=True)
    notes = db.relationship('StickyNote', backref='user', cascade='all, delete-orphan', lazy=True)
    covers = db.relationship('MonthlyCover', backref='user', cascade='all, delete-orphan', lazy=True)

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'role': self.role,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class CalendarEvent(db.Model):
    __tablename__ = 'calendar_events'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    detail = db.Column(db.Text, nullable=False)
    event_date = db.Column(db.String(30), nullable=False)  # ISO string o YYYY-MM-DD HH:MM
    status = db.Column(db.String(20), nullable=False, default='pendiente')  # 'pendiente', 'completado'
    created_at = db.Column(db.DateTime, default=utc_now)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'username': self.user.username if self.user else None,
            'detail': self.detail,
            'event_date': self.event_date,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class StickyNote(db.Model):
    __tablename__ = 'sticky_notes'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    content = db.Column(db.Text, nullable=False)  # Texto libre (cifras, saldos, listas, notas rápidas)
    color = db.Column(db.String(20), nullable=False, default='#FFF59D')  # Amarillo clásico post-it
    font_family = db.Column(db.String(30), nullable=False, server_default='handwriting', default='handwriting')  # handwriting, casual, clean, mono
    is_pinned = db.Column(db.Boolean, default=False)
    month_year = db.Column(db.String(7), nullable=True, index=True)  # YYYY-MM para seccionar por mes
    created_at = db.Column(db.DateTime, default=utc_now)
    updated_at = db.Column(db.DateTime, default=utc_now, onupdate=utc_now)

    def to_dict(self):
        computed_month = self.month_year or (self.created_at.strftime('%Y-%m') if self.created_at else None)
        return {
            'id': self.id,
            'user_id': self.user_id,
            'username': self.user.username if self.user else None,
            'content': self.content,
            'color': self.color,
            'font_family': self.font_family or 'handwriting',
            'is_pinned': self.is_pinned,
            'month_year': computed_month,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


class MonthlyCover(db.Model):
    __tablename__ = 'monthly_covers'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    month_year = db.Column(db.String(7), nullable=False, index=True)  # YYYY-MM
    title = db.Column(db.String(100), nullable=False, default='')  # ej. "Septiembre"
    subtitle = db.Column(db.String(200), nullable=False, default='')  # ej. "Amor y Abundancia"
    year_text = db.Column(db.String(10), nullable=False, default='')  # ej. "2026"
    background_type = db.Column(db.String(50), nullable=False, default='grid')  # 'grid', 'dots', 'ruled', 'clean'
    background_color = db.Column(db.String(30), nullable=False, default='#FFFFFF')
    design_data = db.Column(db.Text, nullable=False, default='[]')  # JSON con elementos de diseño
    is_custom = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=utc_now)
    updated_at = db.Column(db.DateTime, default=utc_now, onupdate=utc_now)

    __table_args__ = (
        db.UniqueConstraint('user_id', 'month_year', name='uq_user_month_cover'),
    )

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'month_year': self.month_year,
            'title': self.title,
            'subtitle': self.subtitle,
            'year_text': self.year_text,
            'background_type': self.background_type,
            'background_color': self.background_color,
            'design_data': self.design_data,
            'is_custom': self.is_custom,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
