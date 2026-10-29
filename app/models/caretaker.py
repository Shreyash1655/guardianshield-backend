from datetime import datetime
from app.models import db

class CaretakerRelation(db.Model):
    __tablename__ = 'caretaker_relations'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    caretaker_email = db.Column(db.String(120), nullable=False)
    status = db.Column(db.String(20), default="PENDING")  # PENDING, ACCEPTED, REVOKED
    consent_given = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "caretaker_email": self.caretaker_email,
            "status": self.status,
            "consent_given": self.consent_given,
            "created_at": self.created_at.isoformat()
        }