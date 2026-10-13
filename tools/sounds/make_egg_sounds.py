"""Yumurta kırılma animasyonu sesleri (client/Reveal): 'dum' (yumurta her büyüdüğünde tok, yumuşak vuruş) ve 'puf' (kırılırken yumuşak hava patlaması).
Sahibi 'yumurta açarken lego sesini kapat, her büyürken dum dum dum dum puf gibi bir ses çıksın' dedi.
Çalıştırma (Blender'ın kendi Python'u numpy ve aud içerir):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/sounds/make_egg_sounds.py -- <MUTLAK klasör yolu>
Çıktı: egg_dum / egg_puf (.wav önizleme, .ogg Roblox'a yüklenecek) + terminalde spektrum raporu.

TASARIM:
  * 'dum': telefon hoparlörleri ~150 Hz altını çalmaz; bu yüzden vuruş 190 Hz'den 85 Hz'e inen kısa bir süpürmedir ve 2./3. harmonikleri (200-500 Hz) taşır:
    kulak temeli bu harmoniklerden duyar, sesin 'dum' gibi tok olması telefonda da korunur. Yumuşak giriş (4 ms), hızlı sönüm, 2-5 kHz'de neredeyse hiç enerji yok
    (4 kez art arda çalındığı için keskin olmamalı). Oyunda her vuruşta perde ve ses yükselir (Reveal: Sfx.play opts), ses dosyası tek ve nötrdür.
  * 'puf': yumuşak, alçak geçirgen hava patlaması (parlak kısım çok kısa, koyu kısım daha uzun) + çok hafif alçak vuruş. Keskin 'çat' yok.
"""
import os
import sys
import wave

import numpy as np

SR = 44100
out_dir = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
os.makedirs(out_dir, exist_ok=True)
rng = np.random.RandomState(7)  # sabit tohum: her çalıştırmada aynı 'puf'


def t_axis(duration):
    return np.arange(int(SR * duration)) / SR


def soft_attack(t, attack):
    rise = np.clip(t / attack, 0, 1)
    return 0.5 - 0.5 * np.cos(np.pi * rise)


def thump(duration, f_start, f_end, sweep_tau, decay_tau, harmonics):
    """Süpürmeli vuruş: frekans f_start'tan f_end'e üstel iner, genlik üstel söner."""
    t = t_axis(duration)
    freq = f_end + (f_start - f_end) * np.exp(-t / sweep_tau)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    signal = np.zeros_like(t)
    for harmonic, amount, speed in harmonics:
        signal += amount * np.sin(phase * harmonic) * np.exp(-t * speed / decay_tau)
    return signal * soft_attack(t, 0.004) * np.exp(-t / decay_tau)


def spectral_filter(audio, low=None, high=None, order=4):
    """FFT ile yumuşak (Butterworth benzeri) üst ve alt kesme."""
    spectrum = np.fft.rfft(audio)
    freqs = np.fft.rfftfreq(len(audio), 1 / SR)
    if high:
        spectrum *= 1 / (1 + (freqs / high) ** (2 * order))
    if low:
        spectrum *= 1 - 1 / (1 + (freqs / low) ** (2 * order))
    return np.fft.irfft(spectrum, len(audio))


def finish(audio, tail=0.03, peak=0.85):
    fade = int(SR * tail)
    audio[-fade:] *= np.linspace(1, 0, fade)
    return audio / np.max(np.abs(audio)) * peak


def build_dum():
    body = thump(0.30, 190.0, 85.0, 0.030, 0.085, ((1, 1.0, 1.0), (2, 0.55, 1.4), (3, 0.28, 2.0), (4, 0.10, 3.0)))
    # Çok hafif, alçak geçirgen 'tok' vuruş tınısı (ilk 25 ms): vuruşun ahşap/deri gibi net başlaması için
    t = t_axis(0.30)
    knock = spectral_filter(rng.randn(len(t)), high=900.0) * np.exp(-t / 0.012) * soft_attack(t, 0.002)
    audio = body + 0.12 * knock / max(np.max(np.abs(knock)), 1e-9) * np.max(np.abs(body))
    audio = spectral_filter(audio, low=70.0, high=2600.0)
    return finish(audio)


def build_puf():
    duration = 0.34
    t = t_axis(duration)
    noise = rng.randn(len(t))
    bright = spectral_filter(noise, low=300.0, high=3200.0) * np.exp(-t / 0.035)  # kısa parlak üfleme
    dark = spectral_filter(noise, low=140.0, high=900.0) * np.exp(-t / 0.095)  # daha uzun yumuşak gövde
    air = (0.55 * bright + 1.0 * dark) * soft_attack(t, 0.006)
    air = air / np.max(np.abs(air))
    low = thump(duration, 150.0, 80.0, 0.04, 0.10, ((1, 1.0, 1.0), (2, 0.35, 1.6)))
    audio = air * 0.8 + low * 0.45
    audio = spectral_filter(audio, low=90.0, high=3400.0)
    return finish(audio, tail=0.06)


def report(name, audio):
    freqs = np.fft.rfftfreq(len(audio), 1 / SR)
    power = np.abs(np.fft.rfft(audio)) ** 2
    total = power.sum()

    def band(low, high):
        return 100 * power[(freqs >= low) & (freqs < high)].sum() / total

    centroid = (freqs * power).sum() / total
    rms = np.sqrt(np.mean(audio**2))
    print(f"[{name}] süre: {len(audio) / SR * 1000:.0f} ms | tepe: {20 * np.log10(np.max(np.abs(audio))):.1f} dBFS | rms: {20 * np.log10(rms):.1f} dBFS")
    print(f"[{name}] enerji: <150 Hz {band(0, 150):.1f}% | 150-600 Hz {band(150, 600):.1f}% | 600-2000 Hz {band(600, 2000):.1f}% | 2-5 kHz {band(2000, 5000):.1f}% | >5 kHz {band(5000, 30000):.2f}% | ağırlık merkezi {centroid:.0f} Hz")


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
        aud.Sound.file(wav_path).write(ogg_path, SR, aud.CHANNELS_MONO, aud.FORMAT_S16, aud.CONTAINER_OGG, aud.CODEC_VORBIS, 128)
        print("yazıldı:", ogg_path, os.path.getsize(ogg_path), "bayt")
    except Exception as error:  # noqa: BLE001
        print("OGG yazılamadı (WAV yeterli, Roblox'a yüklemeden önce bir dönüştürücüyle .ogg/.mp3 yap):", error)


save("egg_dum", build_dum())
save("egg_puf", build_puf())
