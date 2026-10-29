from faster_whisper import WhisperModel
from .scam_type import scam_type

KEYWORDS = ["otp", "kyc", "blocked", "arrest", "urgent", "lottery", "prize",
            "bank", "account", "verify", "parcel", "refund", "gift card", "transfer"]

class Result:
    def __init__(self, transcript):
        t = transcript.lower()
        hits = [k for k in KEYWORDS if k in t]
        self.transcript = transcript
        self.score = min(1.0, len(hits) / 3)
        self.is_scam = self.score >= 0.34
        self.scam_type = scam_type(transcript)
        self.channel = "call"
        self.keywords = hits

    def to_dict(self):
        return self.__dict__

class Detector:
    def __init__(self):
        self.model_name = "faster-whisper-tiny"
        self.model_version = "1.0"
        self.backend = "faster-whisper"
        self.load_error = None
        self.ready = False
        try:
            self.model = WhisperModel("tiny", compute_type="int8")
            self.ready = True
        except Exception as e:
            self.load_error = str(e)

    def status(self):
        return {"ready": self.ready, "status": "running" if self.ready else "error",
                "error": self.load_error}

    def analyze(self, loaded_audio):
        audio = getattr(loaded_audio, "samples", loaded_audio)
        audio = audio.astype("float32")
        segs, _ = self.model.transcribe(audio, language="en", vad_filter=True)
        return Result(" ".join(s.text for s in segs).strip())

_det = None
def get_detector():
    global _det
    if _det is None:
        _det = Detector()
    return _det