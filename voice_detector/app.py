"""GuardianShield AI Flask API for experimental voice authenticity checks."""

from __future__ import annotations

import logging
import os

from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.exceptions import RequestEntityTooLarge

from audio_io import AudioValidationError, load_audio_bytes
from config import APP_NAME, HOST, MAX_UPLOAD_BYTES, PORT
from detector.engine import get_detector

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("guardianshield")

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_BYTES
CORS(app, resources={r"/api/*": {"origins": "*"}})

def _health_payload() -> dict:
    det = get_detector()
    return {
        "status": "ok" if det.ready else "degraded",
        "app": APP_NAME,
        "model_ready": det.ready,
        "backend": det.backend,
        "model_name": det.model_name,
        "model_version": det.model_version,
        "load_error": det.load_error,
    }

@app.errorhandler(RequestEntityTooLarge)
def too_large(_err):
    return jsonify({"error": "File is too large.", "code": "payload_too_large"}), 413

@app.get("/api/health")
@app.get("/api/voice/health")
def health():
    return jsonify(_health_payload())

@app.get("/api/model/status")
def model_status():
    return jsonify(get_detector().status())

@app.post("/api/alerts/trusted-contact")
def trusted_contact_alert():
    body = request.get_json(silent=True) or {}
    consent = bool(body.get("consent"))
    name = str(body.get("name") or "").strip()
    if not consent or not name:
        return jsonify(
            {
                "delivered": False,
                "status": "rejected",
                "message": "Alert was not sent. Consent and a saved contact name are required.",
            }
        )
    return jsonify(
        {
            "delivered": False,
            "status": "not_configured",
            "channel": "none",
            "message": "Alert processed.",
        }
    )

@app.post("/api/voice/analyze")
def analyze():
    if "audio" not in request.files and "file" not in request.files:
        return jsonify({"error": "Missing multipart field 'audio'.", "code": "missing_file"}), 400

    upload = request.files.get("audio") or request.files.get("file")
    raw = upload.read()
    log.info("analyze request filename=%s bytes=%s", upload.filename, len(raw))

    try:
        if not get_detector().ready:
            return (
                jsonify(
                    {
                        "error": get_detector().load_error or "The detection model is not loaded.",
                        "code": "model_not_ready",
                    }
                ),
                503,
            )
        loaded = load_audio_bytes(raw, upload.filename)
        result = get_detector().analyze(loaded)
        return jsonify(result.to_dict())
    except AudioValidationError as exc:
        return jsonify({"error": str(exc), "code": "invalid_audio"}), exc.http_status
    except Exception:
        log.exception("inference failed")
        return (
            jsonify(
                {
                    "error": "Analysis failed. The detector could not process this recording.",
                    "code": "inference_error",
                }
            ),
            500,
        )
    finally:
        del raw

def create_app() -> Flask:
    get_detector()
    return app

if __name__ == "__main__":
    os.environ.setdefault("GS_DEBUG", "0")
    create_app()
    app.run(host=HOST, port=PORT, debug=False, threaded=True)