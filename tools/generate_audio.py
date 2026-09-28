import os
import wave
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(BASE_DIR, "assets", "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    # Normalize to -1.0 .. 1.0 and convert to 16-bit PCM
    max_val = np.max(np.abs(samples))
    if max_val > 0.001:
        samples = samples / max_val * 0.95
    int_samples = (np.clip(samples, -0.98, 0.98) * 32767).astype(np.int16)
    
    filepath = os.path.join(AUDIO_DIR, filename)
    with wave.open(filepath, "wb") as wf:
        wf.setnchannels(1) # mono
        wf.setsampwidth(2) # 16-bit
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(int_samples.tobytes())
    print(f"Generated {filename}: {len(samples)} samples ({len(samples)/SAMPLE_RATE:.3f}s)")

# ==============================================================================
# 1. PIECE MOVE (Solid Hardwood Piece Placed on Polished Wooden Board)
# Realistic physical wood acoustics: crisp micro-impact + dense wood body + cavity thump
# Zero electronic sine tones, zero ringing. Pure tactile wood *thock*.
# ==============================================================================
def make_move():
    dur = 0.065 # 65ms crisp, dry wood placement
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    # 1. Micro-impact transient (wood grain friction & initial strike)
    noise = np.random.randn(len(t))
    kernel = np.hamming(7)
    kernel /= kernel.sum()
    transient = np.convolve(noise, kernel, mode='same') * np.exp(-t * 320.0) * 0.70
    
    # 2. Table cavity deep hollow thump (105 Hz, decaying in 35ms)
    cavity = np.sin(2 * np.pi * 105 * t) * np.exp(-t * 95.0) * 0.55
    
    # 3. Dense hardwood non-harmonic vibrational eigenmodes (heavily damped)
    modes = [
        (175.0, 140.0, 0.45),
        (295.0, 190.0, 0.40),
        (510.0, 240.0, 0.25),
        (860.0, 310.0, 0.12)
    ]
    wood_body = np.zeros_like(t)
    for freq, decay, amp in modes:
        jitter = 0.04 * np.sin(2 * np.pi * 43 * t)
        wood_body += amp * np.sin(2 * np.pi * freq * t + jitter) * np.exp(-t * decay)
        
    sig = transient + cavity + wood_body
    tail_fade = np.clip((dur - t) / 0.012, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 2. PIECE CAPTURE (Solid Hardwood Piece-on-Piece Strike)
# Punchy, authentic wood collision: piece strikes piece then board reaction
# Solid wood *clack-thump*
# ==============================================================================
def make_capture():
    dur = 0.085 # 85ms
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    # Primary piece collision transient
    noise1 = np.random.randn(len(t))
    kernel = np.hamming(5)
    kernel /= kernel.sum()
    transient1 = np.convolve(noise1, kernel, mode='same') * np.exp(-t * 360.0) * 0.85
    
    # Secondary board contact (delayed by 7ms)
    t_delayed = np.maximum(0.0, t - 0.007)
    noise2 = np.random.randn(len(t))
    transient2 = np.convolve(noise2, kernel, mode='same') * np.exp(-t_delayed * 280.0) * (t >= 0.007) * 0.55
    
    # Piece-on-piece collision eigenmodes (solid, punchy wood clack)
    modes = [
        (240.0, 110.0, 0.55),
        (460.0, 160.0, 0.50),
        (780.0, 220.0, 0.35),
        (1240.0, 300.0, 0.18),
        (1850.0, 380.0, 0.10)
    ]
    wood_clack = np.zeros_like(t)
    for freq, decay, amp in modes:
        jitter = 0.03 * np.sin(2 * np.pi * 51 * t)
        wood_clack += amp * np.sin(2 * np.pi * freq * t + jitter) * np.exp(-t * decay)
        
    # Deep table reaction thump
    board_thump = np.sin(2 * np.pi * 120 * t) * np.exp(-t * 85.0) * 0.50
    
    sig = transient1 + transient2 + wood_clack + board_thump
    tail_fade = np.clip((dur - t) / 0.015, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 3. PIECE SELECT (Gentle Tactile Wood Lift/Touch)
# Subtle, quiet, soft contact
# ==============================================================================
def make_select():
    dur = 0.035 # 35ms
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    noise = np.random.randn(len(t))
    kernel = np.hamming(9)
    kernel /= kernel.sum()
    soft_transient = np.convolve(noise, kernel, mode='same') * np.exp(-t * 260.0) * 0.30
    wood_tone = np.sin(2 * np.pi * 220 * t) * np.exp(-t * 160.0) * 0.35
    
    sig = (soft_transient + wood_tone) * 0.5
    tail_fade = np.clip((dur - t) / 0.008, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 4. BUTTON CLICK (Tactile Wooden Toggle)
# Clean acoustic wood snap, very short
# ==============================================================================
def make_click():
    dur = 0.025 # 25ms
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    noise = np.random.randn(len(t)) * np.exp(-t * 350.0) * 0.40
    snap = np.sin(2 * np.pi * 420 * t) * np.exp(-t * 240.0) * 0.45
    sig = noise + snap
    tail_fade = np.clip((dur - t) / 0.006, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 5. INVALID MOVE (Muted Dull Wood Bump)
# Low frequency muffled thud, no high frequencies
# ==============================================================================
def make_invalid():
    dur = 0.080 # 80ms
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    thud = np.sin(2 * np.pi * 95 * t) * np.exp(-t * 70.0) * 0.60
    sub = np.sin(2 * np.pi * 65 * t) * np.exp(-t * 55.0) * 0.40
    sig = thud + sub
    tail_fade = np.clip((dur - t) / 0.015, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 6. TURN CHANGER (Soft Organic Wood Tap)
# ==============================================================================
def make_turn():
    dur = 0.050 # 50ms
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), False)
    
    tap = np.sin(2 * np.pi * 180 * t) * np.exp(-t * 100.0) * 0.50
    noise = np.random.randn(len(t)) * np.exp(-t * 250.0) * 0.20
    sig = (tap + noise) * 0.40
    tail_fade = np.clip((dur - t) / 0.010, 0.0, 1.0)
    return sig * tail_fade

# ==============================================================================
# 7. AI THINKING TICK (Completely Silent - No Electronic Sine Beep!)
# ==============================================================================
def make_thinking():
    # 0.01s of silence so there's never a "ting tong" on AI turns
    return np.zeros(int(SAMPLE_RATE * 0.01))

# ==============================================================================
# 8. VICTORY FANFARE (Warm Acoustic Marimba Chord: G3 - B3 - D4 - G4)
# Warm, deeply resonant wooden bars
# ==============================================================================
def make_victory():
    dur = 1.3
    total_len = int(SAMPLE_RATE * dur)
    out = np.zeros(total_len)
    notes = [196.0, 246.94, 293.66, 392.0] # G3, B3, D4, G4 (deep warm octave)
    step = 0.12
    for i, freq in enumerate(notes):
        start_idx = int(i * step * SAMPLE_RATE)
        t_note = np.linspace(0, dur - i * step, total_len - start_idx, False)
        wood_bar = (
            0.60 * np.sin(2 * np.pi * freq * t_note) +
            0.20 * np.sin(2 * np.pi * freq * 2.756 * t_note) * np.exp(-t_note * 12.0)
        ) * np.exp(-t_note * 4.5)
        out[start_idx:] += wood_bar * 0.45
    return out

# ==============================================================================
# 9. DEFEAT (Gentle Muted Wood Resonance)
# ==============================================================================
def make_defeat():
    dur = 0.9
    total_len = int(SAMPLE_RATE * dur)
    out = np.zeros(total_len)
    notes = [220.0, 196.0, 164.81] # A3, G3, E3
    step = 0.16
    for i, freq in enumerate(notes):
        start_idx = int(i * step * SAMPLE_RATE)
        t_note = np.linspace(0, dur - i * step, total_len - start_idx, False)
        wood_tone = (
            0.55 * np.sin(2 * np.pi * freq * t_note)
        ) * np.exp(-t_note * 4.0)
        out[start_idx:] += wood_tone * 0.38
    return out

# Generate files
write_wav("sfx_click.wav", make_click())
write_wav("sfx_select.wav", make_select())
write_wav("sfx_move.wav", make_move())
write_wav("sfx_capture.wav", make_capture())
write_wav("sfx_invalid.wav", make_invalid())
write_wav("sfx_turn.wav", make_turn())
write_wav("sfx_thinking.wav", make_thinking())
write_wav("sfx_victory.wav", make_victory())
write_wav("sfx_defeat.wav", make_defeat())

print("Physical wooden audio synthesis complete!")
