from datetime import datetime
from app.models import db

class Incident(db.Model):
    __tablename__ = 'incidents'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    channel = db.Column(db.String(50), nullable=False)  # sms, email, voice, chat, url
    raw_content = db.Column(db.Text, nullable=True)
    metadata_json = db.Column(db.Text, nullable=True)
    risk_score = db.Column(db.Float, default=0.0)
    risk_level = db.Column(db.String(20), default="SAFE")  # SAFE, SUSPICIOUS, HIGH_RISK
    explanation = db.Column(db.Text, nullable=True)
    dna_cluster_id = db.Column(db.String(100), nullable=True)
    status = db.Column(db.String(50), default="NEW")  # NEW, PENDING_REVIEW, RESOLVED, HELP_REQUESTED
    recovery_actions = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    alerts = db.relationship('Alert', backref='incident', lazy=True, cascade='all, delete-orphan')

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "channel": self.channel,
            "raw_content": self.raw_content,
            "metadata_json": self.metadata_json,
            "risk_score": self.risk_score,
            "risk_level": self.risk_level,
            "explanation": self.explanation,
            "dna_cluster_id": self.dna_cluster_id,
            "status": self.status,
            "recovery_actions": self.recovery_actions,
            "created_at": self.created_at.isoformat()
        }