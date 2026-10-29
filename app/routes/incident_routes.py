from flask import Blueprint, request, jsonify
from app.models import db
from app.models.incident import Incident
from app.security.auth import token_required
from app.services.scam_dna import ScamDNAEngine
from app.services.caretaker_service import CaretakerService
import json

incident_bp = Blueprint('incident_bp', __name__)

@incident_bp.route('/incidents', methods=['GET'])
@token_required
def get_incidents(current_user):
    incidents = Incident.query.filter_by(user_id=current_user.id).order_by(Incident.created_at.desc()).all()
    return jsonify([inc.to_dict() for inc in incidents]), 200

@incident_bp.route('/incidents/<int:id>', methods=['GET'])
@token_required
def get_incident_detail(current_user, id):
    incident = Incident.query.filter_by(id=id, user_id=current_user.id).first()
    if not incident:
        return jsonify({"error": "Incident not found"}), 404

    correlations = ScamDNAEngine.find_correlations(incident)
    res = incident.to_dict()
    res["correlations"] = correlations
    return jsonify(res), 200

@incident_bp.route('/incidents/<int:id>/request-help', methods=['POST'])
@token_required
def request_help(current_user, id):
    incident = Incident.query.filter_by(id=id, user_id=current_user.id).first()
    if not incident:
        return jsonify({"error": "Incident not found"}), 404

    incident.status = "HELP_REQUESTED"
    CaretakerService.trigger_alert(incident, current_user)
    db.session.commit()
    return jsonify({"message": "Help requested successfully. Caretakers notified.", "incident": incident.to_dict()}), 200

@incident_bp.route('/incidents/<int:id>/recovery-actions', methods=['POST'])
@token_required
def recovery_actions(current_user, id):
    incident = Incident.query.filter_by(id=id, user_id=current_user.id).first()
    if not incident:
        return jsonify({"error": "Incident not found"}), 404

    data = request.get_json() or {}
    actions = data.get('actions', [])
    incident.recovery_actions = json.dumps(actions)
    incident.status = "RESOLVED"
    db.session.commit()

    return jsonify({"message": "Recovery actions recorded", "incident": incident.to_dict()}), 200 