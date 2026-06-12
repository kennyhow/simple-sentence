#!/usr/bin/env python3
"""Generate a chiptune bunny theme WAV — mischievous, charming, hoppy.

Pure Python: wave + struct + math. No external deps.
Output: assets/audio/bunny_theme.wav (~30s loopable chiptune)
"""

import math
import struct
import wave
import os

SAMPLE_RATE = 44100
BPM = 130
BEAT_SEC = 60.0 / BPM

# === Note frequencies (C4 = middle C) ===
NOTES = {
    'C2': 65.41, 'D2': 73.42, 'E2': 82.41, 'F2': 87.31,
    'G2': 98.00, 'A2': 110.00, 'B2': 123.47,
    'C3': 130.81, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61,
    'G3': 196.00, 'A3': 220.00, 'B3': 246.94,
    'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23,
    'G4': 392.00, 'A4': 440.00, 'B4': 493.88,
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46,
    'G5': 783.99, 'A5': 880.00, 'B5': 987.77, 'C6': 1046.50,
    'REST': 0,
}

# === Wave generators ===

def square_wave(t, freq, duty=0.5):
    """NES-style square wave."""
    if freq == 0:
        return 0.0
    phase = (t * freq) % 1.0
    return 1.0 if phase < duty else -1.0

def triangle_wave(t, freq):
    """Softer triangle wave."""
    if freq == 0:
        return 0.0
    phase = (t * freq) % 1.0
    return 4.0 * abs(phase - 0.5) - 1.0

def pulse_wave(t, freq, width=0.125):
    """Very thin pulse — good for percussion-ish clicks."""
    if freq == 0:
        return 0.0
    phase = (t * freq) % 1.0
    return 1.0 if phase < width else -1.0

def noise(t):
    """Simple deterministic noise from time value."""
    return (hash(int(t * SAMPLE_RATE * 1000)) % 2000 / 1000.0) - 1.0

def adsr(t, duration, attack=0.01, decay=0.05, sustain=0.7, release=0.1):
    """Simple ADSR envelope. t is time within the note (0..duration)."""
    if t < attack:
        return t / attack
    elif t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / decay
    elif t < duration - release:
        return sustain
    elif t < duration:
        return sustain * (1.0 - (t - (duration - release)) / release)
    return 0.0

# === Build the track ===

def build_track():
    """Compose the bunny theme and return a list of float samples."""

    # Musical structure (each tuple: note_name, duration_in_beats)
    # 8-bar loop, 4/4 time = 32 beats total

    # --- Lead melody (square wave) ---
    # Bar 1-2: hoppy ascending motif
    lead_melody = [
        # Bar 1
        ('C4', 0.5), ('E4', 0.5), ('G4', 0.5), ('C5', 0.5),
        ('E5', 0.5), ('D5', 0.5), ('C5', 0.5), ('G4', 0.5),
        # Bar 2 — bouncy repeat with variation
        ('C4', 0.5), ('E4', 0.5), ('G4', 0.5), ('E5', 0.5),
        ('D5', 0.5), ('C5', 0.5), ('A4', 0.5), ('REST', 0.5),
        # Bar 3 — slightly mischievous (hint of minor)
        ('A4', 0.5), ('C5', 0.5), ('E5', 0.5), ('G5', 0.5),
        ('F5', 0.5), ('E5', 0.5), ('D5', 0.5), ('C5', 0.5),
        # Bar 4 — playful chromatic run
        ('F4', 0.5), ('A4', 0.5), ('C5', 0.5), ('F5', 0.5),
        ('E5', 0.25), ('D5', 0.25), ('C5', 0.25), ('B4', 0.25),
        ('C5', 1.0),
        # Bar 5 — bouncy staccato hops
        ('E5', 0.25), ('REST', 0.25), ('D5', 0.25), ('REST', 0.25),
        ('C5', 0.25), ('REST', 0.25), ('G4', 0.25), ('REST', 0.25),
        ('E5', 0.25), ('REST', 0.25), ('D5', 0.25), ('REST', 0.25),
        ('C5', 0.25), ('REST', 0.25), ('E4', 0.25), ('REST', 0.25),
        # Bar 6 — arpeggio run up
        ('C5', 0.25), ('E5', 0.25), ('G5', 0.25), ('C6', 0.25),
        ('B5', 0.25), ('A5', 0.25), ('G5', 0.25), ('F5', 0.25),
        ('E5', 0.5), ('D5', 0.5), ('C5', 0.5), ('REST', 0.5),
        # Bar 7 — triumphant but cute
        ('G4', 0.5), ('C5', 0.5), ('E5', 0.5), ('G5', 0.5),
        ('C6', 1.0), ('REST', 0.5), ('G5', 0.5),
        # Bar 8 — resolution + pickup to loop
        ('E5', 0.5), ('C5', 0.5), ('G4', 0.5), ('E4', 0.5),
        ('C4', 1.0), ('REST', 1.0),
    ]

    # --- Harmony / pad (triangle wave, softer) ---
    harmony = [
        # Bar 1-2: C major pad
        ('C4', 4.0), ('REST', 0),  # dummy, handled differently
    ]
    # Harmony as chord roots held longer
    harmony_chords = [
        ('C3', 4.0),   # C major, bars 1-2
        ('A3', 2.0), ('F3', 2.0),  # Am, F, bars 3-4
        ('C3', 2.0), ('G3', 2.0),  # C, G, bars 5-6
        ('C3', 2.0), ('G3', 2.0),  # C, G, bars 7-8
    ]

    # --- Bass line (triangle wave, lower octave) ---
    bass_line = [
        # Bar 1-2: root-fifth bounce
        ('C3', 1.0), ('G3', 1.0), ('C3', 1.0), ('G3', 1.0),
        # Bar 3-4
        ('A2', 1.0), ('E3', 1.0), ('F2', 1.0), ('C3', 1.0),
        # Bar 5-6
        ('C3', 1.0), ('G2', 1.0), ('C3', 1.0), ('G2', 1.0),
        # Bar 7-8
        ('C3', 1.0), ('G2', 1.0), ('C3', 1.5), ('REST', 0.5),
    ]

    # --- Percussion (noise + pulse) ---
    # Simple 8th-note hi-hat pattern with kick on 1 and 3
    total_beats = 32
    total_samples = int(total_beats * BEAT_SEC * SAMPLE_RATE)

    samples = [0.0] * total_samples

    def note_to_samples(note_name, duration_beats):
        """Convert a note + duration to sample count."""
        return int(duration_beats * BEAT_SEC * SAMPLE_RATE)

    def add_to_samples(source_samples, note_list, wave_fn, volume, duty=None):
        """Render a sequence of notes into the mix."""
        sample_idx = 0
        for note_name, beats in note_list:
            freq = NOTES[note_name]
            note_samples = note_to_samples(note_name, beats)
            for i in range(note_samples):
                if sample_idx + i >= total_samples:
                    break
                t = (sample_idx + i) / SAMPLE_RATE
                note_t = i / SAMPLE_RATE
                env = adsr(note_t, note_samples / SAMPLE_RATE)
                if duty is not None:
                    val = wave_fn(t, freq, duty) * env * volume
                else:
                    val = wave_fn(t, freq) * env * volume
                source_samples[sample_idx + i] += val
            sample_idx += note_samples

    # Render lead (square wave, bright)
    add_to_samples(samples, lead_melody, square_wave, 0.22, duty=0.4)

    # Render harmony chords (triangle wave, soft pad)
    chord_idx = 0
    for note_name, beats in harmony_chords:
        freq = NOTES[note_name]
        note_samples = int(beats * BEAT_SEC * SAMPLE_RATE)
        for i in range(note_samples):
            if chord_idx + i >= total_samples:
                break
            t = (chord_idx + i) / SAMPLE_RATE
            note_t = i / SAMPLE_RATE
            env = adsr(note_t, note_samples / SAMPLE_RATE, attack=0.05, decay=0.1, sustain=0.5, release=0.3)
            # Add fifth above for richness
            fifth_freq = freq * 1.5  # perfect fifth
            val = (triangle_wave(t, freq) * 0.7 + triangle_wave(t, fifth_freq) * 0.3)
            val *= env * 0.12
            samples[chord_idx + i] += val
        chord_idx += note_samples

    # Render bass (triangle wave)
    add_to_samples(samples, bass_line, triangle_wave, 0.18)

    # Render percussion
    sample_idx = 0
    for beat in range(total_beats * 2):  # 8th notes
        beat_samples = int(0.5 * BEAT_SEC * SAMPLE_RATE)
        for i in range(beat_samples):
            if sample_idx + i >= total_samples:
                break
            t = (sample_idx + i) / SAMPLE_RATE
            note_t = i / SAMPLE_RATE
            env = adsr(note_t, beat_samples / SAMPLE_RATE, attack=0.001, decay=0.02, sustain=0.0, release=0.01)

            # Kick on beats 1 and 3 (every 4th 8th note)
            if beat % 4 == 0:
                # Short low-frequency pulse = kick
                val = pulse_wave(t, 80, 0.3) * env * 0.15
                samples[sample_idx + i] += val
            else:
                # Hi-hat: noise burst
                val = noise(t) * env * 0.06
                samples[sample_idx + i] += val
        sample_idx += beat_samples

    # Normalize
    max_val = max(abs(s) for s in samples)
    if max_val > 0:
        samples = [s / max_val * 0.85 for s in samples]

    return samples


def write_wav(samples, filepath):
    """Write float samples to a 16-bit PCM WAV file."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(SAMPLE_RATE)

        # Convert float [-1, 1] to int16
        int_samples = []
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            int_val = int(clamped * 32767)
            int_samples.append(struct.pack('<h', int_val))

        wf.writeframes(b''.join(int_samples))

    duration = len(samples) / SAMPLE_RATE
    print(f"Wrote {filepath} ({duration:.1f}s, {len(samples)} samples, {SAMPLE_RATE}Hz mono 16-bit)")


def main():
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'assets', 'audio', 'bunny_theme.wav'
    )

    print(f"Generating bunny theme... BPM={BPM}, key=C major")
    samples = build_track()
    write_wav(samples, output_path)
    print("Done! 🐰🎵")


if __name__ == '__main__':
    main()
