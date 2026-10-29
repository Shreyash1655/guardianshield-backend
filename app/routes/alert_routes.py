from flask import Blueprint, request, jsonify
from app.models import db
from app.models.alert import Alert
from app.security.auth import token_required

alert_bp = Blueprint('alert_bp', __name__)

@alert_bp.route('/alerts', methods=['GET'])
@token_required
def get_alerts(current_user):
    alerts = Alert.query.join(Alert.incident).filter_by(user_id=current_user.id).all()
    return jsonify([a.to_dict() for a in alerts]), 200

@alert_bp.route('/alerts/<int:id>/acknowledge', methods=['POST'])
@token_required
def acknowledge_alert(current_user, id):
    alert = Alert.query.get(id)
    if not alert:
        return jsonify({"error": "Alert not found"}), 404

    alert.acknowledged = True
    db.session.commit()
    return jsonify({"message": "Alert acknowledged", "alert": alert.to_dict()}), 200