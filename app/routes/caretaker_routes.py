from flask import Blueprint, request, jsonify
from app.models import db
from app.models.caretaker import CaretakerRelation
from app.security.auth import token_required
from app.services.caretaker_service import CaretakerService

caretaker_bp = Blueprint('caretaker_bp', __name__)

@caretaker_bp.route('/caretakers/invitations', methods=['POST'])
@token_required
def invite_caretaker(current_user):
    data = request.get_json() or {}
    email = data.get('email')
    if not email:
        return jsonify({"error": "Missing caretaker email"}), 400

    relation = CaretakerService.invite_caretaker(current_user.id, email)
    return jsonify({"message": "Caretaker invitation created", "relation": relation.to_dict()}), 201

@caretaker_bp.route('/caretakers/accept', methods=['POST'])
def accept_caretaker():
    data = request.get_json() or {}
    relation_id = data.get('relation_id')
    consent = data.get('consent', False)

    relation = CaretakerRelation.query.get(relation_id)
    if not relation:
        return jsonify({"error": "Invitation not found"}), 404

    relation.status = "ACCEPTED"
    relation.consent_given = bool(consent)
    db.session.commit()

    return jsonify({"message": "Caretaker relationship accepted", "relation": relation.to_dict()}), 200