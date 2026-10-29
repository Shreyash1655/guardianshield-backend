from flask import Blueprint, request, jsonify
from app.models import db
from app.models.incident import Incident
from app.security.auth import token_required
from app.services.fusion_engine import ThreatFusionEngine
from app.services.url_intelligence import URLIntelligence
from app.services.voice_adapter import VoiceAdapter
from app.services.scam_dna import ScamDNAEngine
from app.services.caretaker_service import CaretakerService
import json

analyze_bp = Blueprint('analyze_bp', __name__)

@analyze_bp.route('/analyze', methods=['POST'])
@token_required
def analyze(current_user):
    data = request.get_json() or {}
    channel = data.get('channel')
    content = data.get('content')
    metadata = data.get('metadata', {})

    if not channel or not content:
        return jsonify({"error": "Missing channel or content"}), 400

    evaluation = ThreatFusionEngine.evaluate(channel, content, metadata)
    dna_cluster = ScamDNAEngine.compute_cluster_id(content)

    incident = Incident(
        user_id=current_user.id,
        channel=channel,
        raw_content=content,
        metadata_json=json.dumps(metadata) if metadata else None,
        risk_score=evaluation["risk_score"],
        risk_level=evaluation["risk_level"],
        explanation=evaluation["explanation"],
        dna_cluster_id=dna_cluster,
        status="NEW"
    )
    db.session.add(incident)
    db.session.commit()

    if evaluation["risk_level"] == "HIGH_RISK":
        CaretakerService.trigger_alert(incident, current_user)

    return jsonify({
        "message": "Analysis completed successfully",
        "incident": incident.to_dict(),
        "evaluation": evaluation
    }), 200

@analyze_bp.route('/analyze/url', methods=['POST'])
@token_required
def analyze_url(current_user):
    data = request.get_json() or {}
    url = data.get('url')
    if not url:
        return jsonify({"error": "Missing url"}), 400
    
    result = URLIntelligence.analyze_url(url)
    return jsonify(result), 200

@analyze_bp.route('/analyze/voice', methods=['POST'])
@token_required
def analyze_voice(current_user):
    audio_file = request.files.get('audio')
    transcript = VoiceAdapter.transcribe(audio_file)

    evaluation = ThreatFusionEngine.evaluate('voice', transcript)
    dna_cluster = ScamDNAEngine.compute_cluster_id(transcript)

    incident = Incident(
        user_id=current_user.id,
        channel='voice',
        raw_content=transcript,
        risk_score=evaluation["risk_score"],
        risk_level=evaluation["risk_level"],
        explanation=evaluation["explanation"],
        dna_cluster_id=dna_cluster,
        status="NEW"
    )
    db.session.add(incident)
    db.session.commit()

    if evaluation["risk_level"] == "HIGH_RISK":
        CaretakerService.trigger_alert(incident, current_user)

    return jsonify({
        "message": "Voice transcription and analysis completed",
        "transcript": transcript,
        "incident": incident.to_dict(),
        "evaluation": evaluation
    }), 200 