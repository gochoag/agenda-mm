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
    created_at = db.Column(db.DateTime, default=utc_now)
    updated_at = db.Column(db.DateTime, default=utc_now, onupdate=utc_now)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'username': self.user.username if self.user else None,
            'content': self.content,
            'color': self.color,
            'font_family': self.font_family or 'handwriting',
            'is_pinned': self.is_pinned,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
