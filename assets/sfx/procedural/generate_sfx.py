"""
Procedural SFX generator for Bubble Shooter.
Generates all game sound effects as WAV files using pure math — no external dependencies.
"""

import wave
import struct
import math
import os

SAMPLE_RATE = 44100
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))


def write_wav(filename: str, samples: list[float]) -> None:
    path = os.path.join(OUTPUT_DIR, filename)
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        peak = max(abs(s) for s in samples) or 1.0
        for s in samples:
            clamped = max(-1.0, min(1.0, s / peak * 0.85))
            wf.writeframes(struct.pack("<h", int(clamped * 32767)))
    print(f"  wrote {filename}  ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.3f}s)")


def sine(t: float, freq: float) -> float:
    return math.sin(2.0 * math.pi * freq * t)


def noise(rng_state: list) -> float:
    # Simple LCG pseudo-random noise
    rng_state[0] = (rng_state[0] * 1664525 + 1013904223) & 0xFFFFFFFF
    return (rng_state[0] / 0x80000000) - 1.0


def envelope(t: float, duration: float, attack: float = 0.005, release: float = 0.15) -> float:
    if t < attack:
        return t / attack
    decay_start = duration - release
    if t > decay_start:
        return max(0.0, 1.0 - (t - decay_start) / release)
    return 1.0


# ── Bubble Pop ────────────────────────────────────────────────────────────────
# Sine wave with rapidly falling pitch + soft noise layer
def gen_bubble_pop() -> list[float]:
    duration = 0.18
    n = int(SAMPLE_RATE * duration)
    rng = [12345]
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 680.0 * math.exp(-progress * 5.5)   # pitch falls fast
        env = math.exp(-progress * 9.0)             # sharp decay
        s = sine(t, freq) * 0.82 + noise(rng) * 0.12
        samples.append(s * env)
    return samples


# ── Bubble Pop Variant 2 — "Juicy" ───────────────────────────────────────────
# Fat harmonics stack + pitch punch upward then snap down — very satisfying
def gen_bubble_pop_juicy() -> list[float]:
    duration = 0.20
    n = int(SAMPLE_RATE * duration)
    rng = [31337]
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        # pitch punches UP briefly then falls hard — that "pop" snap feel
        pitch_punch = math.exp(-progress * 40.0) * 220.0
        freq = (820.0 + pitch_punch) * math.exp(-progress * 6.5)
        env = math.exp(-progress * 8.5) * (1.0 - math.exp(-progress * 60.0))
        # rich harmonic stack
        s  = sine(t, freq)        * 0.55
        s += sine(t, freq * 2.0)  * 0.25   # octave — brightness
        s += sine(t, freq * 3.0)  * 0.12   # 5th above octave — shimmer
        s += sine(t, freq * 0.5)  * 0.10   # sub — body
        s += noise(rng)            * 0.06   # air
        samples.append(s * env)
    return samples


# ── Bubble Pop Variant 3 — "Chunky" ──────────────────────────────────────────
# Thick low-mid thump + bright pop — feels weighty, very satisfying on mobile
def gen_bubble_pop_chunky() -> list[float]:
    duration = 0.21
    n = int(SAMPLE_RATE * duration)
    rng = [42042]
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq_high = 700.0 * math.exp(-progress * 7.0)    # top pop
        freq_low  = 160.0 * math.exp(-progress * 4.5)    # bottom thump
        env_high = math.exp(-progress * 10.0) * (1.0 - math.exp(-progress * 50.0))
        env_low  = math.exp(-progress * 6.0)  * (1.0 - math.exp(-progress * 30.0))
        pop   = (sine(t, freq_high) * 0.7 + sine(t, freq_high * 1.5) * 0.2) * env_high
        thump = (sine(t, freq_low)  * 0.8 + sine(t, freq_low  * 2.0) * 0.2) * env_low
        click = noise(rng) * math.exp(-progress * 80.0) * 0.18   # transient click
        samples.append(pop * 0.55 + thump * 0.38 + click)
    return samples


# ── Shoot Whoosh ─────────────────────────────────────────────────────────────
# Light airy whoosh with a soft tonal tail
def gen_shoot_whoosh() -> list[float]:
    duration = 0.22
    n = int(SAMPLE_RATE * duration)
    rng = [99991]
    samples = []
    filtered_noise = 0.0
    whoosh_seed = 0.97
    start_frequency = 540.0 * whoosh_seed
    end_frequency = 150.0 * whoosh_seed
    noise_blend = 0.29
    tonal_blend = 0.17
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        env = math.exp(-progress * 4.5) * (1.0 - math.exp(-progress * 30.0))
        frequency = start_frequency + (end_frequency - start_frequency) * pow(progress, 0.68)
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        filtered_noise = filtered_noise + (noise(rng) - filtered_noise) * (0.22 + progress * 0.2)
        noisy_air = filtered_noise * (1.0 - progress * 0.55)
        tonal_tail = math.sin(phase) * (1.0 - progress) * 0.7
        click = 0.0
        if progress < 0.08:
            click = (1.0 - progress / 0.08) * noise(rng) * 0.18
        samples.append((noisy_air * noise_blend + tonal_tail * tonal_blend + click) * env * 0.92)
    return samples


# ── Wall Bounce ───────────────────────────────────────────────────────────────
# Short snappy chirp — quick rise then fall in pitch
def gen_wall_bounce() -> list[float]:
    duration = 0.10
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 520.0 + 380.0 * math.exp(-progress * 12.0)
        env = math.exp(-progress * 14.0)
        samples.append(sine(t, freq) * env)
    return samples


# ── Floating Bubbles Fall ─────────────────────────────────────────────────────
# Descending pitch glide — like bubbles drifting down
def gen_floating_fall() -> list[float]:
    duration = 0.30
    n = int(SAMPLE_RATE * duration)
    rng = [55555]
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 420.0 * math.exp(-progress * 2.0)   # gentle descent
        env = envelope(t, duration, attack=0.01, release=0.18)
        s = sine(t, freq) * 0.75 + sine(t, freq * 1.5) * 0.15 + noise(rng) * 0.05
        samples.append(s * env * 0.9)
    return samples


# ── Row Drop (ceiling) ────────────────────────────────────────────────────────
# Low thud — heavy sine at low frequency with rumble layer
def gen_row_drop() -> list[float]:
    duration = 0.28
    n = int(SAMPLE_RATE * duration)
    rng = [77777]
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 90.0 * math.exp(-progress * 3.5)
        env = math.exp(-progress * 7.5) * (1.0 - math.exp(-progress * 40.0))
        thud = sine(t, freq) * 0.8 + sine(t, freq * 2.1) * 0.15
        rumble = noise(rng) * 0.1 * math.exp(-progress * 5.0)
        samples.append((thud + rumble) * env)
    return samples


# ── Board Cleared ─────────────────────────────────────────────────────────────
# Ascending arpeggio — C5 E5 G5 C6, cheerful
def gen_board_cleared() -> list[float]:
    note_duration = 0.12
    gap = 0.04
    notes = [523.25, 659.25, 783.99, 1046.50]   # C5 E5 G5 C6
    total_duration = len(notes) * (note_duration + gap) + 0.15
    n = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * n
    for idx, freq in enumerate(notes):
        start = int(idx * (note_duration + gap) * SAMPLE_RATE)
        note_n = int(note_duration * SAMPLE_RATE)
        for i in range(note_n):
            t = i / SAMPLE_RATE
            progress = t / note_duration
            env = math.exp(-progress * 5.0) * (1.0 - math.exp(-progress * 30.0))
            s = sine(t, freq) * 0.7 + sine(t, freq * 2.0) * 0.2 + sine(t, freq * 3.0) * 0.08
            pos = start + i
            if pos < n:
                samples[pos] += s * env
    return samples


# ── Game Over ─────────────────────────────────────────────────────────────────
# Descending sad tones — G4 E4 C4 A3
def gen_game_over() -> list[float]:
    note_duration = 0.18
    gap = 0.05
    notes = [392.00, 329.63, 261.63, 220.00]   # G4 E4 C4 A3
    total_duration = len(notes) * (note_duration + gap) + 0.25
    n = int(SAMPLE_RATE * total_duration)
    samples = [0.0] * n
    for idx, freq in enumerate(notes):
        start = int(idx * (note_duration + gap) * SAMPLE_RATE)
        note_n = int(note_duration * SAMPLE_RATE)
        for i in range(note_n):
            t = i / SAMPLE_RATE
            progress = t / note_duration
            env = math.exp(-progress * 4.0) * (1.0 - math.exp(-progress * 25.0))
            s = sine(t, freq) * 0.75 + sine(t, freq * 1.5) * 0.18 + sine(t, freq * 0.5) * 0.12
            pos = start + i
            if pos < n:
                samples[pos] += s * env
    return samples


# ── Run ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Generating procedural SFX...\n")
    write_wav("bubble_pop.wav",         gen_bubble_pop())
    write_wav("bubble_pop_juicy.wav",   gen_bubble_pop_juicy())
    write_wav("bubble_pop_chunky.wav",  gen_bubble_pop_chunky())
    write_wav("shoot_whoosh.wav",   gen_shoot_whoosh())
    write_wav("wall_bounce.wav",    gen_wall_bounce())
    write_wav("floating_fall.wav",  gen_floating_fall())
    write_wav("row_drop.wav",       gen_row_drop())
    write_wav("board_cleared.wav",  gen_board_cleared())
    write_wav("game_over.wav",      gen_game_over())
    print("\nDone! All SFX generated in:", OUTPUT_DIR)
