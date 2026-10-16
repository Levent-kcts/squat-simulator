"""POWER HOUR giriş müziği (client/PowerHourHud başlarken çalar): ~9 sn, hareketli ve heyecanlı bir 'jingle'.
Sahibi 'power hour ilk çıktığı zaman çalacak özel bir şarkı ekle, daha hareketli ve kişiyi heyecanlandıracak bir müzik olsun' dedi (2026-10-16).
Çalıştırma (Blender'ın kendi Python'u numpy ve aud içerir):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/sounds/make_powerhour.py -- <MUTLAK klasör yolu>
Çıktı: powerhour_theme (.wav önizleme, .ogg Roblox'a yüklenecek) + terminalde spektrum raporu.

YAPI (150 BPM, La minör, 4/4):
  * 1. ölçü YÜKSELİŞ: hızlanan trampet dizisi (8'lik > 16'lık > 32'lik), yükselen gürültü süpürmesi ve yükselen synth tonu: 'bir şey geliyor' hissi.
  * 2-5. ölçü PATLAMA: her vuruşta davul (kick), 2 ve 4'te el çırpma, ara vuruşlarda zil (hi-hat), akor dizisi Am - F - C - G (her ölçü bir akor),
    8'lik bas, 16'lık parlak arpej (lead), her ölçü başında ve 2'nin ara vuruşunda 'brass' akor vurgusu. 5. ölçünün sonunda ikinci kısa trampet dizisi.
  * SON: büyük La majör (pikardi) akor vuruşu + zil (crash), ~1.4 sn sönüm.
Telefon hoparlörü ~150 Hz altını çalmaz: bas ve kick 2./3. harmonikleriyle (150-500 Hz) duyulur; 6 kHz üstü kısılır (kulağı tırmalamasın). Sabit tohum: her çalıştırmada aynı.
"""
import os
import sys
import wave

import numpy as np

SR = 44100
BPM = 150
BEAT = 60 / BPM
BAR = BEAT * 4
out_dir = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
os.makedirs(out_dir, exist_ok=True)
rng = np.random.RandomState(11)

INTRO = BAR
DROP_BARS = 4
END_HIT = 1.6
TOTAL = INTRO + DROP_BARS * BAR + END_HIT
N = int(SR * TOTAL)
mix = np.zeros(N)


def midi(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def place(signal, start, gain=1.0):
    i = int(start * SR)
    if i >= N:
        return
    j = min(N, i + len(signal))
    mix[i:j] += signal[: j - i] * gain


def t_axis(duration):
    return np.arange(int(SR * duration)) / SR


def env(t, attack, decay, sustain=0.0, length=None, release=0.03):
    """ADSR: attack, üstel decay ile sustain'e, length'ten sonra release."""
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = sustain + (1 - sustain) * np.exp(-np.maximum(t - attack, 0) / max(decay, 1e-4))
    e = np.where(t < attack, a, d)
    if length is not None:
        e = e * np.clip(1 - (t - length) / release, 0, 1)
    return e


def base_phase(freq, t):
    """Frekans sabit ya da zamanla değişen (vibrato) olabilir: faz, frekansın birikimli toplamıdır."""
    freq = np.broadcast_to(np.asarray(freq, dtype=float), t.shape)
    return 2 * np.pi * np.cumsum(freq) / SR, float(np.max(freq))


def saw(freq, t, harmonics=14):
    """Bant sınırlı testere dişi (toplam harmonik): sert değil, parlak."""
    phase, top = base_phase(freq, t)
    out = np.zeros_like(t)
    for k in range(1, harmonics + 1):
        if top * k > 9000:
            break
        out += ((-1) ** (k + 1)) * np.sin(phase * k) / k
    return out


def square(freq, t, harmonics=9):
    phase, top = base_phase(freq, t)
    out = np.zeros_like(t)
    for k in range(1, harmonics * 2, 2):
        if top * k > 9000:
            break
        out += np.sin(phase * k) / k
    return out


def spectral_filter(audio, low=None, high=None, order=3):
    spectrum = np.fft.rfft(audio)
    freqs = np.fft.rfftfreq(len(audio), 1 / SR)
    if high:
        spectrum *= 1 / (1 + (freqs / high) ** (2 * order))
    if low:
        spectrum *= 1 - 1 / (1 + (freqs / low) ** (2 * order))
    return np.fft.irfft(spectrum, len(audio))


# ---------------- davullar ----------------
def kick():
    t = t_axis(0.32)
    freq = 55 + 140 * np.exp(-t / 0.035)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    body = (np.sin(phase) + 0.45 * np.sin(2 * phase) + 0.2 * np.sin(3 * phase)) * np.exp(-t / 0.11)
    click = spectral_filter(rng.randn(len(t)), low=1500, high=5000) * np.exp(-t / 0.004) * 0.25
    return body + click


def snare():
    t = t_axis(0.22)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.05) * 0.6
    noise = spectral_filter(rng.randn(len(t)), low=900, high=6500) * np.exp(-t / 0.07)
    return tone + noise * 0.9


def clap():
    t = t_axis(0.25)
    noise = spectral_filter(rng.randn(len(t)), low=1000, high=5500)
    bursts = sum(np.exp(-np.maximum(t - d, 0) / 0.008) * (t >= d) for d in (0.0, 0.011, 0.022))
    return noise * (bursts * 0.5 + np.exp(-np.maximum(t - 0.022, 0) / 0.09) * (t >= 0.022))


def hat(open_=False):
    t = t_axis(0.18 if open_ else 0.05)
    noise = spectral_filter(rng.randn(len(t)), low=6500, high=11000)
    return noise * np.exp(-t / (0.06 if open_ else 0.012))


def crash():
    t = t_axis(1.5)
    noise = spectral_filter(rng.randn(len(t)), low=3000, high=10000)
    return noise * np.exp(-t / 0.45)


# ---------------- synthler ----------------
def bass_note(note, length):
    t = t_axis(length + 0.05)
    f = midi(note)
    tone = saw(f, t, 10) * 0.7 + np.sin(2 * np.pi * f * 2 * t) * 0.35
    return spectral_filter(tone, high=1800) * env(t, 0.004, 0.12, 0.55, length, 0.04)


def lead_note(note, length):
    t = t_axis(length + 0.06)
    f = midi(note)
    vibrato = 1 + 0.004 * np.sin(2 * np.pi * 6 * t)
    tone = square(f * vibrato, t, 7) * 0.6 + saw(f * 2.003, t, 6) * 0.25
    return spectral_filter(tone, high=5500) * env(t, 0.003, 0.08, 0.35, length, 0.05)


def brass_chord(notes, length):
    t = t_axis(length + 0.15)
    out = np.zeros_like(t)
    for note in notes:
        f = midi(note)
        for detune in (0.997, 1.0, 1.003):
            out += saw(f * detune, t, 12)
    out = spectral_filter(out, low=180, high=3800) / (len(notes) * 3)
    return out * env(t, 0.012, 0.18, 0.45, length, 0.12)


# Akorlar (La minör): Am - F - C - G ; bas kökleri ve arpej notaları
CHORDS = [
    {"root": 45, "tones": [57, 60, 64]},  # Am
    {"root": 41, "tones": [53, 57, 60]},  # F
    {"root": 48, "tones": [55, 60, 64]},  # C
    {"root": 43, "tones": [55, 59, 62]},  # G
]

# ---------------- 1. ölçü: YÜKSELİŞ ----------------
t_intro = t_axis(INTRO)
riser = spectral_filter(rng.randn(len(t_intro)), low=400, high=7000)
riser *= (t_intro / INTRO) ** 2 * 0.35
sweep_f = 220 * 2 ** (2 * t_intro / INTRO)  # iki oktav yükselir
riser += np.sin(2 * np.pi * np.cumsum(sweep_f) / SR) * (t_intro / INTRO) ** 1.5 * 0.22
place(riser, 0)
# hızlanan trampet: 8'lik (1. yarı), 16'lık (3. çeyrek), 32'lik (son çeyrek), giderek yükselir
hits = [i * BEAT / 2 for i in range(4)] + [2 * BEAT + i * BEAT / 4 for i in range(4)] + [3 * BEAT + i * BEAT / 8 for i in range(8)]
for index, time in enumerate(hits):
    place(snare(), time, 0.25 + 0.55 * index / len(hits))

# ---------------- 2-5. ölçü: PATLAMA ----------------
for bar in range(DROP_BARS):
    start = INTRO + bar * BAR
    chord = CHORDS[bar % 4]
    if bar == 0:
        place(crash(), start, 0.5)
    for beat in range(4):
        bt = start + beat * BEAT
        place(kick(), bt, 1.0)
        if beat in (1, 3):
            place(clap(), bt, 0.55)
        place(hat(open_=True), bt + BEAT / 2, 0.22)
        place(hat(), bt + BEAT / 4, 0.12)
        place(hat(), bt + 3 * BEAT / 4, 0.12)
        # 8'lik bas: kök, 2. 8'likte bir oktav üst (zıplayan bas)
        place(bass_note(chord["root"], BEAT / 2 * 0.85), bt, 0.55)
        place(bass_note(chord["root"] + 12, BEAT / 2 * 0.85), bt + BEAT / 2, 0.42)
    # 16'lık arpej: akor notaları yukarı-aşağı, bir oktav yukarıda
    pattern = [0, 1, 2, 1, 0, 1, 2, 3]
    tones = chord["tones"] + [chord["tones"][0] + 12]
    for step in range(16):
        note = tones[pattern[step % 8]] + 12
        place(lead_note(note, BEAT / 4 * 0.8), start + step * BEAT / 4, 0.22)
    # brass vurguları: ölçü başı ve 2. vuruşun ara vuruşu
    place(brass_chord(chord["tones"], BEAT * 0.9), start, 0.62)
    place(brass_chord(chord["tones"], BEAT * 0.45), start + 1.5 * BEAT, 0.38)
    # son ölçünün son vuruşunda kısa trampet dizisi (bitişe hazırlık)
    if bar == DROP_BARS - 1:
        for i in range(4):
            place(snare(), start + 3 * BEAT + i * BEAT / 4, 0.4 + 0.12 * i)

# ---------------- SON: büyük akor ----------------
end = INTRO + DROP_BARS * BAR
place(kick(), end, 1.1)
place(crash(), end, 0.7)
place(brass_chord([57, 61, 64, 69], END_HIT - 0.2), end, 0.75)  # La majör (umut dolu bitiş)
place(bass_note(45, END_HIT - 0.3), end, 0.6)
place(lead_note(81, 0.9), end, 0.18)


def finish(audio, peak=0.9):
    audio = spectral_filter(audio, low=90, high=8000, order=2)  # 90 Hz altı telefonda duyulmaz, sadece yer kaplar
    audio = audio / np.max(np.abs(audio))
    audio = np.tanh(audio * 1.6) / np.tanh(1.6)  # yumuşak sınırlayıcı: daha dolgun, tepe kırpılmaz
    fade = int(SR * 0.25)
    audio[-fade:] *= np.linspace(1, 0, fade)
    return audio / np.max(np.abs(audio)) * peak


def report(name, audio):
    freqs = np.fft.rfftfreq(len(audio), 1 / SR)
    power = np.abs(np.fft.rfft(audio)) ** 2
    total = power.sum()

    def band(low, high):
        return 100 * power[(freqs >= low) & (freqs < high)].sum() / total

    rms = np.sqrt(np.mean(audio**2))
    print(f"[{name}] süre: {len(audio) / SR:.2f} sn | tepe: {20 * np.log10(np.max(np.abs(audio))):.1f} dBFS | rms: {20 * np.log10(rms):.1f} dBFS")
    print(f"[{name}] enerji: <150 Hz {band(0, 150):.1f}% | 150-600 Hz {band(150, 600):.1f}% | 600-2000 Hz {band(600, 2000):.1f}% | 2-6 kHz {band(2000, 6000):.1f}% | >6 kHz {band(6000, 30000):.2f}%")


def save(name, audio):
    report(name, audio)
    wav_path = os.path.join(out_dir, f"{name}.wav")
    with wave.open(wav_path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes((audio * 32767).astype(np.int16).tobytes())
    print("yazıldı:", wav_path)
    try:
        import aud

        ogg_path = os.path.join(out_dir, f"{name}.ogg")
        aud.Sound.file(wav_path).write(ogg_path, SR, aud.CHANNELS_MONO, aud.FORMAT_S16, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 160)
        print("yazıldı:", ogg_path, os.path.getsize(ogg_path), "bayt")
    except Exception as error:  # noqa: BLE001
        print("OGG yazılamadı (WAV yeterli, Roblox'a yüklemeden önce bir dönüştürücüyle .ogg/.mp3 yap):", error)


save("powerhour_theme", finish(mix))
