class VoiceAdapter:
    @staticmethod
    def transcribe(audio_file_storage):
        if not audio_file_storage:
            return ""
        filename = getattr(audio_file_storage, 'filename', 'audio.wav').lower()
        if "bank" in filename:
            return "Attention customer your bank account has been locked due to suspicious activity. Press 1 to speak with security support and provide your OTP."
        elif "arrest" in filename:
            return "This is an automated call from law enforcement. A digital arrest warrant has been issued against your name. Transfer funds immediately to avoid jail time."
        return "Hello, this is a simulated voice transcription from GuardianShield audio processing engine."