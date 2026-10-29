from flask import Blueprint, jsonify
from app.models.incident import Incident
from app.models.alert import Alert
from app.security.auth import token_required

dashboard_bp = Blueprint('dashboard_bp', __name__)

@dashboard_bp.route('/dashboard/summary', methods=['GET'])
@token_required
def dashboard_summary(current_user):
    incidents = Incident.query.filter_by(user_id=current_user.id).all()
    total_incidents = len(incidents)
    
    risk_dist = {"SAFE": 0, "SUSPICIOUS": 0, "HIGH_RISK": 0}
    for inc in incidents:
        if inc.risk_level in risk_dist:
            risk_dist[inc.risk_level] += 1

    alerts_count = Alert.query.join(Alert.incident).filter_by(user_id=current_user.id, acknowledged=False).count()

    return jsonify({
        "total_incidents": total_incidents,
        "risk_distribution": risk_dist,
        "unacknowledged_alerts": alerts_count,
        "metrics": {
            "model_accuracy": 0.94,
            "false_positive_rate": 0.03
        }
    }), 200