"""Level atlama sesi üretici (yumuşak, tekrar edince rahatsız etmeyen 'bloop-ding'), iki varyant: soft (en yumuşak) ve bright (biraz daha parıltılı).
Çalıştırma (Blender'ın kendi Python'u numpy ve aud içerir):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/sounds/make_levelup.py -- <MUTLAK klasör yolu>
Çıktı: levelup_soft / levelup_bright (.wav önizleme, .ogg Roblox'a yüklenecek) + terminalde spektrum raporu.

TASARIM KURALLARI (araştırma özeti):
  * Kulak 2-5 kHz arasında en duyarlıdır (kulak kanalı rezonansı); bu bantta enerji yoğunsa ses 'delici' ve yorucu olur. Yüksek ses dışında rahatsızlığın en güçlü göstergesi KESKİNLİK (tizlik)
    olduğu için temel ses 500-800 Hz'de tutulur, üst harmonikler hızla söner, 5 kHz üstü yumuşakça kesilir.
  * Kısa: arayüz onay sesleri ~100-300 ms. Burada ~330 ms, yankı/kuyruk YOK. Her tekrarda aynı olmasın diye oyunda +-%4 hız değişimi (Config.Sounds.LevelUp.speed).
  * Yumuşak giriş (8 ms kosinüs): ani tık/patlama yok. Titreşim (vibrato/tremolo) yok: pürüzlülük yaratır.
  * Hoş aralık: yükselen tam beşli (C5 -> G5).
"""
import os
import sys
import wave

import numpy as np

SR = 44100
out_dir = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
os.makedirs(out_dir, exist_ok=True)

# (harmonik, miktar, sönüm hızı çarpanı): üstler temelden daha hızlı söner
HARMONICS = {
    "soft": ((1, 1.0, 1.0), (2, 0.26, 1.7), (3, 0.07, 2.6)),
    "bright": ((1, 1.0, 1.0), (2, 0.34, 1.5), (3, 0.16, 2.2), (4, 0.07, 3.0), (5, 0.03, 3.6)),
}
CUTOFF = {"soft": 4200.0, "bright": 5600.0}  # Hz: bundan sonrası yumuşakça kesilir
C5, G5 = 523.25, 783.99


def note(freq, duration, tau, level, harmonics, attack=0.008):
    """Marimba/çan benzeri yumuşak nota: temel + üst harmonikler, kosinüs girişi, üstel sönüm."""
    t = np.arange(int(SR * duration)) / SR
    rise = np.clip(t / attack, 0, 1)
    rise = 0.5 - 0.5 * np.cos(np.pi * rise)
    signal = np.zeros_like(t)
    for harmonic, amount, speed in harmonics:
        signal += amount * np.sin(2 * np.pi * freq * harmonic * t) * np.exp(-t * speed / tau)
    return level * rise * signal


def mix(parts, total):
    buffer = np.zeros(int(SR * total))
    for start, wave_ in parts:
        index = int(SR * start)
        buffer[index : index + len(wave_)] += wave_[: len(buffer) - index]
    return buffer


def build(variant):
    harmonics = HARMONICS[variant]
    audio = mix([(0.0, note(C5, 0.30, 0.075, 0.85, harmonics)), (0.085, note(G5, 0.30, 0.115, 1.0, harmonics))], 0.33)

    # Üst frekansları yumuşakça kes ve 120 Hz altını al
    spectrum = np.fft.rfft(audio)
    freqs = np.fft.rfftfreq(len(audio), 1 / SR)
    spectrum *= 1 / (1 + (freqs / CUTOFF[variant]) ** 6)
    spectrum *= 1 - 1 / (1 + (freqs / 120.0) ** 4)
    audio = np.fft.irfft(spectrum, len(audio))

    # Son 25 ms'de sönerek biter (tık olmasın), tepe -2 dBFS
    fade = int(SR * 0.025)
    audio[-fade:] *= np.linspace(1, 0, fade)
    audio = audio / np.max(np.abs(audio)) * 0.8

    power = np.abs(np.fft.rfft(audio)) ** 2
    total = power.sum()

    def band(low, high):
        return 100 * power[(freqs >= low) & (freqs < high)].sum() / total

    centroid = (freqs * power).sum() / total
    rms = np.sqrt(np.mean(audio**2))
    print(f"[{variant}] süre: {len(audio) / SR * 1000:.0f} ms | tepe: {20 * np.log10(np.max(np.abs(audio))):.1f} dBFS | rms: {20 * np.log10(rms):.1f} dBFS")
    print(f"[{variant}] enerji: <500 Hz {band(0, 500):.1f}% | 500-2000 Hz {band(500, 2000):.1f}% | 2-5 kHz {band(2000, 5000):.1f}% | >5 kHz {band(5000, 30000):.2f}% | ağırlık merkezi {centroid:.0f} Hz")

    wav_path = os.path.join(out_dir, f"levelup_{variant}.wav")
    with wave.open(wav_path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes((audio * 32767).astype(np.int16).tobytes())
    print("yazıldı:", wav_path)
    try:
        import aud

        ogg_path = os.path.join(out_dir, f"levelup_{variant}.ogg")
        aud.Sound.file(wav_path).write(ogg_path, SR, aud.CHANNELS_MONO, aud.FORMAT_S16, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 128)
        print("yazıldı:", ogg_path, os.path.getsize(ogg_path), "bayt")
    except Exception as error:  # noqa: BLE001
        print("OGG yazılamadı (WAV yeterli, Roblox'a yüklemeden önce bir dönüştürücüyle .ogg/.mp3 yap):", error)


for name in ("soft", "bright"):
    build(name)
