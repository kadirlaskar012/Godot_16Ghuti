import os
import numpy as np
import wave

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(BASE_DIR, "assets", "audio")
os.makedirs(AUDIO_DIR, exist_ok=True)

SAMPLE_RATE = 44100
DURATION = 60.0 # 60 seconds
TOTAL_SAMPLES = int(SAMPLE_RATE * DURATION)
t = np.linspace(0, DURATION, TOTAL_SAMPLES, endpoint=False)

print(f"Synthesizing {DURATION}s seamless organic ambient soundtrack for 16 Guti...")

# Master stereo buffers
left = np.zeros(TOTAL_SAMPLES, dtype=np.float64)
right = np.zeros(TOTAL_SAMPLES, dtype=np.float64)

# ------------------------------------------------------------------------------
# 1. Warm Meditative Drone (Tanpura / Acoustic Harmonium Root Chord: D2, A2, D3, F#3)
# ------------------------------------------------------------------------------
drone_layers = [
    (73.416, 0.28, 0.50, 0.50, 0.10), # D2 root
    (110.00, 0.22, 0.40, 0.60, 0.15), # A2 fifth
    (146.83, 0.18, 0.60, 0.40, 0.12), # D3 octave
    (185.00, 0.12, 0.35, 0.65, 0.14), # F#3 major third
    (220.00, 0.08, 0.65, 0.35, 0.10), # A3
]

for freq, amp, l_pan, r_pan, mod_rate in drone_layers:
    cycles = max(1, round(DURATION * mod_rate))
    real_mod_rate = cycles / DURATION
    swell = 0.75 + 0.25 * np.cos(2 * np.pi * real_mod_rate * t)
    signal = (np.sin(2 * np.pi * freq * t) + 0.30 * np.sin(2 * np.pi * freq * 2.0 * t)) * swell * amp
    left += signal * l_pan
    right += signal * r_pan

# ------------------------------------------------------------------------------
# 2. Gentle Acoustic Plucks (Santoor / Wooden Kalimba)
# Meditative Raag Yaman / Major Pentatonic (D, E, F#, A, B)
# ------------------------------------------------------------------------------
def add_pluck(time_sec, freq, amp, pan, decay=2.8):
    start_sample = int(time_sec * SAMPLE_RATE)
    if start_sample >= TOTAL_SAMPLES:
        return
    dur = min(4.5, DURATION - time_sec)
    n_samples = int(dur * SAMPLE_RATE)
    if n_samples <= 0:
        return
    
    t_pluck = np.linspace(0, dur, n_samples, endpoint=False)
    sig = (
        1.00 * np.sin(2 * np.pi * freq * t_pluck) +
        0.35 * np.sin(2 * np.pi * freq * 2.02 * t_pluck) * np.exp(-t_pluck * 3.0) +
        0.18 * np.sin(2 * np.pi * freq * 3.05 * t_pluck) * np.exp(-t_pluck * 5.0) +
        0.08 * np.sin(2 * np.pi * freq * 4.10 * t_pluck) * np.exp(-t_pluck * 8.0)
    )
    attack = np.minimum(1.0, t_pluck / 0.015)
    env = attack * np.exp(-t_pluck * (1.0 / decay * 2.5))
    pluck_wave = sig * env * amp
    
    end_sample = start_sample + n_samples
    left[start_sample:end_sample] += pluck_wave * (1.0 - pan)
    right[start_sample:end_sample] += pluck_wave * pan

melody = [
    (1.5, 293.66, 0.16, 0.40),
    (4.5, 369.99, 0.15, 0.60),
    (8.0, 440.00, 0.18, 0.45),
    (11.5, 493.88, 0.14, 0.55),
    (15.0, 369.99, 0.15, 0.35),
    (18.5, 293.66, 0.17, 0.65),
    (23.0, 329.63, 0.15, 0.50),
    (26.5, 369.99, 0.16, 0.40),
    (30.0, 440.00, 0.19, 0.60),
    (34.0, 587.33, 0.16, 0.50),
    (37.5, 493.88, 0.15, 0.40),
    (41.0, 440.00, 0.17, 0.60),
    (45.0, 369.99, 0.15, 0.45),
    (49.0, 329.63, 0.14, 0.55),
    (53.0, 293.66, 0.16, 0.50),
]

for note in melody:
    add_pluck(note[0], note[1], note[2], note[3])

# ------------------------------------------------------------------------------
# 3. Soft Temple Singing Bowl & Chime
# ------------------------------------------------------------------------------
def add_temple_bowl(time_sec, freq, amp, pan):
    start_sample = int(time_sec * SAMPLE_RATE)
    if start_sample >= TOTAL_SAMPLES:
        return
    dur = min(8.0, DURATION - time_sec)
    n_samples = int(dur * SAMPLE_RATE)
    t_bowl = np.linspace(0, dur, n_samples, endpoint=False)
    bowl = (
        np.sin(2 * np.pi * freq * t_bowl) * 0.70 +
        np.sin(2 * np.pi * (freq * 2.76) * t_bowl) * 0.20 * np.exp(-t_bowl * 0.8) +
        np.sin(2 * np.pi * (freq + 1.2) * t_bowl) * 0.30
    ) * np.exp(-t_bowl * 0.45)
    attack = np.minimum(1.0, t_bowl / 0.08)
    sig = bowl * attack * amp
    end_sample = start_sample + n_samples
    left[start_sample:end_sample] += sig * (1.0 - pan)
    right[start_sample:end_sample] += sig * pan

add_temple_bowl(6.0, 523.25, 0.12, 0.35)
add_temple_bowl(20.0, 440.00, 0.11, 0.65)
add_temple_bowl(36.0, 587.33, 0.12, 0.40)
add_temple_bowl(50.0, 440.00, 0.11, 0.60)

# ------------------------------------------------------------------------------
# 4. Flawless Seamless Looping Crossfade (Equal-Power 4-Second Crossfade)
# ------------------------------------------------------------------------------
CROSSFADE_SEC = 4.0
xfade_len = int(CROSSFADE_SEC * SAMPLE_RATE)

phi = np.linspace(0, np.pi / 2.0, xfade_len)
fade_out = np.cos(phi)
fade_in = np.sin(phi)

tail_l = left[-xfade_len:].copy()
tail_r = right[-xfade_len:].copy()
head_l = left[:xfade_len].copy()
head_r = right[:xfade_len].copy()

left[:xfade_len] = head_l * fade_in + tail_l * fade_out
right[:xfade_len] = head_r * fade_in + tail_r * fade_out

loop_samples = TOTAL_SAMPLES - xfade_len
loop_l = left[:loop_samples]
loop_r = right[:loop_samples]

stereo_data = np.stack([loop_l, loop_r], axis=1)
max_peak = np.max(np.abs(stereo_data))
if max_peak > 0:
    stereo_data = (stereo_data / max_peak) * 0.42 # Soft, pleasant background level

final_duration = len(stereo_data) / SAMPLE_RATE
print(f"Final loop duration: {final_duration:.2f} seconds ({len(stereo_data)} samples)")

# Smoothly force exact boundary continuity (last sample matches first sample exactly)
diff_l = stereo_data[0, 0] - stereo_data[-1, 0]
diff_r = stereo_data[0, 1] - stereo_data[-1, 1]
taper = np.linspace(0, 1, 100)
stereo_data[-100:, 0] += diff_l * taper
stereo_data[-100:, 1] += diff_r * taper

boundary_diff_l = abs(stereo_data[0, 0] - stereo_data[-1, 0])
boundary_diff_r = abs(stereo_data[0, 1] - stereo_data[-1, 1])
print(f"Exact boundary jump Left: {boundary_diff_l:.10f}, Right: {boundary_diff_r:.10f} (Absolute Zero!)")

# Export as 16-bit uncompressed PCM stereo WAV
wav_path = os.path.join(AUDIO_DIR, "bgm_ambient.wav")
int16_data = (np.clip(stereo_data, -0.99, 0.99) * 32767).astype(np.int16)
with wave.open(wav_path, 'wb') as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(int16_data.tobytes())

print(f"Saved uncompressed 16-bit PCM: {wav_path} ({os.path.getsize(wav_path)} bytes)")
print("Seamless BGM synthesis completed successfully!")
