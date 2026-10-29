"""Load, validate, resample, and segment audio without executing uploads."""

from __future__ import annotations

import io
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

from config import (
    ALLOWED_EXTENSIONS,
    MAX_DURATION_SEC,
    MAX_SEGMENTS,
    MAX_UPLOAD_BYTES,
    MIN_DURATION_SEC,
    SEGMENT_HOP_SEC,
    SEGMENT_SEC,
    TARGET_SR,
    WAV_EXTENSIONS,
)

class AudioValidationError(ValueError):
    def __init__(self, message: str, http_status: int = 400):
        super().__init__(message)
        self.http_status = http_status

@dataclass
class LoadedAudio:
    samples: np.ndarray
    sample_rate: int
    duration_sec: float
    original_sr: int
    channels: int
    format_name: str
    warnings: list[str]

def sniff_extension(filename: str | None) -> str:
    name = Path(filename or "").name
    return Path(name).suffix.lower()

def validate_upload_meta(filename: str | None, size_bytes: int) -> str:
    if size_bytes <= 0:
        raise AudioValidationError("The upload is empty.")
    if size_bytes > MAX_UPLOAD_BYTES:
        raise AudioValidationError(
            f"File is too large. Maximum size is {MAX_UPLOAD_BYTES // (1024 * 1024)} MB.",
            http_status=413,
        )
    ext = sniff_extension(filename)
    if ext not in ALLOWED_EXTENSIONS:
        raise AudioValidationError(
            "Unsupported file type. Use WAV (preferred), FLAC, or MP3/M4A if FFmpeg is installed."
        )
    return ext

def _to_mono(data: np.ndarray) -> np.ndarray:
    if data.ndim == 1:
        return data.astype(np.float32, copy=False)
    return np.mean(data, axis=1).astype(np.float32)

def _resample(samples: np.ndarray, orig_sr: int, target_sr: int) -> np.ndarray:
    if orig_sr == target_sr:
        return samples.astype(np.float32, copy=False)
    from math import gcd
    g = gcd(orig_sr, target_sr)
    up = target_sr // g
    down = orig_sr // g
    resampled = resample_poly(samples, up, down)
    return resampled.astype(np.float32)

def _try_ffmpeg_decode(raw: bytes, orig_name: str) -> tuple[np.ndarray, int]:
    try:
        from pydub import AudioSegment
    except Exception as exc:
        raise AudioValidationError(
            "MP3/M4A support needs the pydub package and a system FFmpeg install. "
            "Please convert the recording to WAV and try again."
        ) from exc

    suffix = sniff_extension(orig_name) or ".mp3"
    try:
        segment = AudioSegment.from_file(io.BytesIO(raw), format=suffix.lstrip("."))
    except Exception as exc:
        raise AudioValidationError(
            "Could not decode this compressed audio file. Convert it to WAV and retry."
        ) from exc
    samples = np.array(segment.get_array_of_samples()).astype(np.float32)
    if segment.channels > 1:
        samples = samples.reshape((-1, segment.channels)).mean(axis=1)
    peak = float(1 << (8 * segment.sample_width - 1))
    if peak > 0:
        samples = samples / peak
    return samples, int(segment.frame_rate)

def load_audio_bytes(raw: bytes, filename: str | None) -> LoadedAudio:
    ext = validate_upload_meta(filename, len(raw))
    warnings: list[str] = []

    if ext in WAV_EXTENSIONS:
        try:
            data, orig_sr = sf.read(io.BytesIO(raw), always_2d=True, dtype="float32")
        except Exception as exc:
            raise AudioValidationError(
                "The audio file could not be read. It may be corrupted or not a valid WAV/FLAC file."
            ) from exc
        channels = int(data.shape[1])
        samples = _to_mono(data)
        format_name = ext.lstrip(".")
    else:
        samples, orig_sr = _try_ffmpeg_decode(raw, filename or "audio.mp3")
        channels = 1
        format_name = ext.lstrip(".")
        warnings.append(
            "Compressed formats can hide or add artifacts. Prefer an uncompressed WAV recording."
        )

    if samples.size == 0:
        raise AudioValidationError("The audio file contains no samples.")

    duration = float(samples.size) / float(orig_sr)
    if duration < MIN_DURATION_SEC:
        raise AudioValidationError(
            f"Recording is too short ({duration:.2f}s). Provide at least {MIN_DURATION_SEC:.0f} second(s)."
        )
    if duration > MAX_DURATION_SEC:
        raise AudioValidationError(
            f"Recording is too long ({duration:.1f}s). Maximum is {MAX_DURATION_SEC:.0f} seconds.",
            http_status=413,
        )

    if orig_sr < 8000:
        warnings.append("Sample rate is very low, which limits what the detector can observe.")

    resampled = _resample(samples, orig_sr, TARGET_SR)
    peak = float(np.max(np.abs(resampled))) if resampled.size else 0.0
    if peak < 1e-4:
        warnings.append("The recording is nearly silent.")
    elif peak < 0.02:
        warnings.append("The recording is very quiet.")

    return LoadedAudio(
        samples=resampled,
        sample_rate=TARGET_SR,
        duration_sec=float(resampled.size) / TARGET_SR,
        original_sr=int(orig_sr),
        channels=channels,
        format_name=format_name,
        warnings=warnings,
    )

def segment_audio(samples: np.ndarray, sample_rate: int) -> list[np.ndarray]:
    win = int(SEGMENT_SEC * sample_rate)
    hop = int(SEGMENT_HOP_SEC * sample_rate)
    if samples.size <= win:
        return [samples]
    starts = list(range(0, max(1, samples.size - win + 1), hop))
    if len(starts) > MAX_SEGMENTS:
        starts = starts[:MAX_SEGMENTS]
    segments = [samples[s : s + win] for s in starts]
    if starts and starts[-1] + win < samples.size and len(segments) < MAX_SEGMENTS:
        segments.append(samples[-win:])
    return segments