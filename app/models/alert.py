from datetime import datetime
from app.models import db

class Alert(db.Model):
    __tablename__ = 'alerts'

    id = db.Column(db.Integer, primary_key=True)
    incident_id = db.Column(db.Integer, db.ForeignKey('incidents.id'), nullable=False)
    recipient_email = db.Column(db.String(120), nullable=False)
    message = db.Column(db.Text, nullable=False)
    acknowledged = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "incident_id": self.incident_id,
            "recipient_email": self.recipient_email,
            "message": self.message,
            "acknowledged": self.acknowledged,
            "created_at": self.created_at.isoformat()
        }