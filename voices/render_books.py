"""Speak every extracted book and note in Spike's 1.3x audiobook pace."""

import html
import json
import re
import wave
from hashlib import md5
from pathlib import Path

import numpy as np
from piper import PiperVoice
from piper.config import SynthesisConfig

VOICES = Path(__file__).resolve().parent
BOOKS = VOICES / "books.json"
MODEL = VOICES / "spike" / "en_GB-semaine-medium.onnx"
WAV_DIR = VOICES.parent / "wwise" / "spokenpages" / "Originals" / "SFX" / "books"
MANIFEST = VOICES / "book-audio.jsonl"
STATUS = VOICES / "render.status"

# The 1.3x reading: divide the slow audiobook gaps by 1.3.
STYLE = dict(length_scale=1.22 / 1.3, noise_scale=0.45, noise_w_scale=0.65)
SENTENCE_GAP = 0.42 / 1.3
PARAGRAPH_GAP = 0.85 / 1.3
SPEAKER = 1

TAG = re.compile(r"<[^>]+>")
BREAK = re.compile(r"(?<=[.!?])\s+")


def clean(text: str) -> list[list[str]]:
    text = text.replace("\r", "")
    text = re.sub(r"(?i)<\s*br\s*/?\s*>", "\n", text)
    text = re.sub(r"(?i)</\s*p\s*>", "\n\n", text)
    text = re.sub(r"(?i)<\s*p[^>]*>", "", text)
    text = re.sub(r"(?i)</\s*li\s*>", "\n", text)
    text = TAG.sub("", text)
    text = html.unescape(text)
    text = text.replace("\u00a0", " ")
    paragraphs = []
    for block in re.split(r"\n\s*\n", text):
        block = re.sub(r"\s+", " ", block).strip()
        if not block:
            continue
        sentences = [part.strip() for part in BREAK.split(block) if part.strip()]
        if sentences:
            paragraphs.append(sentences)
    return paragraphs


def event_id(name: str) -> str:
    return "sp_" + md5(name.encode("utf-8")).hexdigest()[:8]


def write_wav(path: Path, audio: np.ndarray, rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes(audio.tobytes())


def speak(voice: PiperVoice, paragraphs: list[list[str]]) -> tuple[np.ndarray, int]:
    config = SynthesisConfig(speaker_id=SPEAKER, **STYLE)
    rate = voice.config.sample_rate
    sentence_gap = int(rate * SENTENCE_GAP)
    paragraph_gap = int(rate * PARAGRAPH_GAP)
    pieces = []
    for paragraph in paragraphs:
        for sentence in paragraph:
            # Piper is happier with a sentence than a whole page.
            chunk = [
                audio.audio_int16_array
                for audio in voice.synthesize(sentence, syn_config=config)
            ]
            if not chunk:
                continue
            pieces.append(np.concatenate(chunk))
            pieces.append(np.zeros(sentence_gap, dtype=np.int16))
        if pieces:
            pieces.append(np.zeros(max(0, paragraph_gap - sentence_gap), dtype=np.int16))
    if not pieces:
        return np.zeros(1, dtype=np.int16), rate
    return np.concatenate(pieces), rate


def done_names() -> set[str]:
    found = set()
    if not MANIFEST.exists():
        return found
    for line in MANIFEST.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        wav = WAV_DIR / row["file"]
        if wav.exists() and wav.stat().st_size > 1000:
            found.add(row["name"])
    return found


def main() -> None:
    STATUS.write_text("RUNNING", encoding="utf-8")
    books = json.loads(BOOKS.read_text(encoding="utf-8"))
    finished = done_names()
    print(f"books {len(books)} already {len(finished)}", flush=True)
    voice = PiperVoice.load(MODEL)
    written = 0
    with MANIFEST.open("a", encoding="utf-8") as manifest:
        for index, book in enumerate(books, start=1):
            if book["name"] in finished:
                continue
            paragraphs = clean(book["text"])
            if not paragraphs:
                print(f"skip empty {book['name']}", flush=True)
                continue
            try:
                audio, rate = speak(voice, paragraphs)
            except Exception as error:
                print(f"skip failed {book['name']}: {error}", flush=True)
                continue
            seconds = len(audio) / rate
            file_name = event_id(book["name"]) + ".wav"
            write_wav(WAV_DIR / file_name, audio, rate)
            row = {
                "name": book["name"],
                "event": event_id(book["name"]),
                "file": file_name,
                "seconds": round(seconds, 2),
                "category": book["category"],
            }
            manifest.write(json.dumps(row, ensure_ascii=False) + "\n")
            manifest.flush()
            written += 1
            if written == 1 or written % 25 == 0:
                print(f"spoke {written} last {book['name']} {seconds:.1f}s ({index}/{len(books)})", flush=True)
    STATUS.write_text("DONE", encoding="utf-8")
    print("RENDER_DONE", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        STATUS.write_text("FAILED " + str(error), encoding="utf-8")
        raise
