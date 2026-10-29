from app.models import db
from app.models.caretaker import CaretakerRelation
from app.models.alert import Alert

class CaretakerService:
    @staticmethod
    def invite_caretaker(user_id, caretaker_email):
        existing = CaretakerRelation.query.filter_by(user_id=user_id, caretaker_email=caretaker_email).first()
        if existing:
            return existing
        
        relation = CaretakerRelation(
            user_id=user_id,
            caretaker_email=caretaker_email,
            status="PENDING",
            consent_given=False
        )
        db.session.add(relation)
        db.session.commit()
        return relation

    @staticmethod
    def trigger_alert(incident, user):
        relations = CaretakerRelation.query.filter_by(user_id=user.id, status="ACCEPTED", consent_given=True).all()
        alerts = []
        for rel in relations:
            existing_alert = Alert.query.filter_by(incident_id=incident.id, recipient_email=rel.caretaker_email, acknowledged=False).first()
            if existing_alert:
                continue

            msg = f"URGENT: Protected ward {user.username} encountered a high-risk scam on channel '{incident.channel}'. Risk Score: {incident.risk_score}."
            alert = Alert(
                incident_id=incident.id,
                recipient_email=rel.caretaker_email,
                message=msg,
                acknowledged=False
            )
            db.session.add(alert)
            alerts.append(alert)
        db.session.commit()
        return alerts 