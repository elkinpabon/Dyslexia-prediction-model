"""
Modelos de base de datos para el sistema de predicción de dislexia
"""
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class User(db.Model):
    """Modelo de Usuario"""
    __tablename__ = 'users'
    
    id = db.Column(db.String(50), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.String(10), nullable=False)  # 'M' o 'F'
    native_lang = db.Column(db.Boolean, default=True)
    other_lang = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relaciones
    children = db.relationship('Child', backref='parent', lazy=True, cascade='all, delete-orphan')
    test_results = db.relationship('TestResult', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'age': self.age,
            'gender': self.gender,
            'native_lang': self.native_lang,
            'other_lang': self.other_lang,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


class Child(db.Model):
    """Modelo de Niño/Hijo"""
    __tablename__ = 'children'
    
    id = db.Column(db.String(50), primary_key=True)
    user_id = db.Column(db.String(50), db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    birth_date = db.Column(db.Date, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relaciones
    test_results = db.relationship('TestResult', backref='child', lazy=True, cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'age': self.age,
            'gender': self.gender,
            'birth_date': self.birth_date.isoformat() if self.birth_date else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


class TestResult(db.Model):
    """Modelo de Resultado de Prueba"""
    __tablename__ = 'test_results'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.String(50), db.ForeignKey('users.id'), nullable=False)
    child_id = db.Column(db.String(50), db.ForeignKey('children.id'), nullable=True)
    
    # Información de la prueba
    activity_id = db.Column(db.String(50), nullable=False)
    activity_name = db.Column(db.String(100), nullable=False)
    
    # Resultados del modelo
    result = db.Column(db.String(10), nullable=False)  # 'SÍ' o 'NO'
    probability = db.Column(db.Float, nullable=False)  # 0-100
    confidence = db.Column(db.Float, nullable=False)   # 0-100
    risk_level = db.Column(db.String(20), nullable=False)  # 'Bajo', 'Medio', 'Alto'
    
    # Detalles de la ejecución
    duration_seconds = db.Column(db.Integer, nullable=True)
    total_clicks = db.Column(db.Integer, nullable=True)
    total_hits = db.Column(db.Integer, nullable=True)
    total_misses = db.Column(db.Integer, nullable=True)
    
    # Datos completos en JSON
    details = db.Column(db.JSON, nullable=True)
    
    # Timestamps
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'child_id': self.child_id,
            'activity_id': self.activity_id,
            'activity_name': self.activity_name,
            'result': self.result,
            'probability': self.probability,
            'confidence': self.confidence,
            'risk_level': self.risk_level,
            'duration_seconds': self.duration_seconds,
            'total_clicks': self.total_clicks,
            'total_hits': self.total_hits,
            'total_misses': self.total_misses,
            'details': self.details,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class ActivityRound(db.Model):
    """Modelo de Ronda de Actividad"""
    __tablename__ = 'activity_rounds'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    test_result_id = db.Column(db.Integer, db.ForeignKey('test_results.id'), nullable=False)
    
    round_number = db.Column(db.Integer, nullable=False)
    clicks = db.Column(db.Integer, default=0)
    hits = db.Column(db.Integer, default=0)
    misses = db.Column(db.Integer, default=0)
    score = db.Column(db.Float, default=0.0)
    attempts = db.Column(db.Integer, default=0)
    time_seconds = db.Column(db.Float, default=0.0)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    # Relación
    test_result = db.relationship('TestResult', backref=db.backref('rounds', lazy=True))
    
    def to_dict(self):
        return {
            'id': self.id,
            'test_result_id': self.test_result_id,
            'round_number': self.round_number,
            'clicks': self.clicks,
            'hits': self.hits,
            'misses': self.misses,
            'score': self.score,
            'attempts': self.attempts,
            'time_seconds': self.time_seconds,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
