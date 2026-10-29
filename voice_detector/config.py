"""Runtime configuration via environment variables."""

from __future__ import annotations

import os
from pathlib import Path


def _float(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    return float(raw)


def _int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    return int(raw)


APP_NAME = "GuardianShield AI"
MODEL_NAME = os.environ.get("GS_MODEL_NAME", "aasist-onnx")
MODEL_VERSION = os.environ.get("GS_MODEL_VERSION", "asvspoof2019-la")
SCORE_TYPE = "uncalibrated experimental score"
AASIST_URL = os.environ.get(
    "GS_AASIST_URL",
    "https://huggingface.co/SpeechAntiSpoofingBenchmarks/AASIST/resolve/main/aasist.onnx",
)
AASIST_ONNX_PATH = os.environ.get("GS_AASIST_ONNX", "")

# Upload / DoS limits
MAX_UPLOAD_BYTES = _int("GS_MAX_UPLOAD_BYTES", 10 * 1024 * 1024)
MAX_DURATION_SEC = _float("GS_MAX_DURATION_SEC", 60.0)
MIN_DURATION_SEC = _float("GS_MIN_DURATION_SEC", 1.0)
TARGET_SR = _int("GS_TARGET_SR", 16000)
SEGMENT_SEC = _float("GS_SEGMENT_SEC", 2.0)
SEGMENT_HOP_SEC = _float("GS_SEGMENT_HOP_SEC", 1.0)
MAX_SEGMENTS = _int("GS_MAX_SEGMENTS", 30)

LOW_SCORE_MAX = _float("GS_LOW_SCORE_MAX", 0.35)
HIGH_SCORE_MIN = _float("GS_HIGH_SCORE_MIN", 0.65)
MIN_SPEECH_SEGMENTS = _int("GS_MIN_SPEECH_SEGMENTS", 1)
INCONCLUSIVE_MARGIN = _float("GS_INCONCLUSIVE_MARGIN", 0.12)

ALLOWED_EXTENSIONS = {".wav", ".wave", ".mp3", ".m4a", ".flac"}
WAV_EXTENSIONS = {".wav", ".wave", ".flac"}

HOST = os.environ.get("GS_HOST", "0.0.0.0")
PORT = _int("GS_PORT", 5000)
DEBUG = os.environ.get("GS_DEBUG", "0") == "1"

BACKEND_ROOT = Path(__file__).resolve().parent
SAMPLE_DIR = BACKEND_ROOT.parent / "samples"