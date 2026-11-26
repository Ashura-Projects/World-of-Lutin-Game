"""Génère toute la bande-son du jeu par synthèse (originale, aucun échantillon externe).

Usage : python3 tools/audio/generate_audio.py <dossier_sortie>   (assets/audio)
Musiques : luth pincé (Karplus-Strong) + bourdon de vielle, modes médiévaux. Ambiances en boucle. Bruitages courts.
Encodage OGG Vorbis via ffmpeg.
"""

import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 22050
rng = np.random.default_rng(1234)
OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/audio")


def save(name: str, x: np.ndarray, stereo: bool = False, q: int = 3) -> None:
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * 0.89
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".wav")
    data = (x * 32767).astype(np.int16)
    with wave.open(str(tmp), "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", str(q), str(path)], check=True)
    tmp.unlink()


def env(n, a=0.005, r=0.3):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-t / max(r, 1e-4))
    return e


def pluck(freq, dur, bright=0.5):
    """Corde pincée (Karplus-Strong)."""
    n = int(dur * SR)
    period = max(2, int(SR / freq))
    raw = rng.uniform(-1, 1, period)
    buf = np.convolve(np.concatenate([raw, raw[:4]]), np.ones(5) / 5, mode="valid")[:period]  # excitation adoucie
    out = np.zeros(n)
    decay = 0.994 + 0.004 * bright
    for i in range(n):
        j = i % period
        out[i] = buf[j]
        buf[j] = decay * 0.5 * (buf[j] + buf[(j + 1) % period])
    return out * env(n, 0.012, dur * 0.6)


def lowpass(x, k=0.1):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def drone(freq, dur, vol=0.12):
    t = np.arange(int(dur * SR)) / SR
    saw = 2 * ((t * freq) % 1.0) - 1
    saw2 = 2 * ((t * freq * 1.5) % 1.0) - 1
    x = lowpass(saw * 0.6 + saw2 * 0.25, 0.05)
    trem = 1 + 0.08 * np.sin(2 * np.pi * 0.25 * t)
    fade = np.minimum(1, t / 2.0) * np.minimum(1, (dur - t) / 2.0)
    return x * vol * trem * fade


def note_freq(semi, base=146.83):  # D3
    return base * 2 ** (semi / 12)


def music(name, mode, tempo, bars, base_semi=0, seed=0):
    """Mélodie modale au luth + bourdon ; boucle propre."""
    r = np.random.default_rng(seed)
    beat = 60.0 / tempo
    dur = bars * 4 * beat
    n = int(dur * SR)
    out = np.zeros(n + SR * 3)
    deg = 0
    t = 0.0
    while t < dur - beat:
        step = r.choice([-2, -1, -1, 0, 1, 1, 2, 3, -3])
        deg = int(np.clip(deg + step, -2, 9))
        semi = mode[deg % len(mode)] + 12 * (deg // len(mode)) + base_semi
        length = r.choice([1, 1, 2, 0.5, 0.5]) * beat
        p = pluck(note_freq(semi + 12), length + 0.6, 0.55)
        i = int(t * SR)
        out[i:i + len(p)] += p * 0.5
        if r.random() < 0.35:  # tierce ou quinte en accompagnement
            p2 = pluck(note_freq(semi + 12 - (3 if r.random() < 0.5 else 5)), length + 0.6, 0.4)
            out[i:i + len(p2)] += p2 * 0.25
        t += length
    out = out[:n]
    out += drone(note_freq(base_semi - 12), dur, 0.18)
    reverb = np.zeros_like(out)
    for d, g in ((0.031, 0.35), (0.053, 0.25), (0.089, 0.18), (0.149, 0.12)):
        k = int(d * SR)
        reverb[k:] += out[:-k] * g
    mix = out + reverb
    st = np.stack([mix, np.roll(mix, int(0.012 * SR))], axis=1).reshape(-1)
    save(f"music/{name}.ogg", st, stereo=True, q=4)


def noise(dur):
    return rng.uniform(-1, 1, int(round(dur * SR)))


def loop_fade(x, f=1.0):
    k = int(f * SR)
    x = x.copy()
    x[:k] = x[:k] * np.linspace(0, 1, k) + x[-k:] * np.linspace(1, 0, k)
    return x[:-k]


def ambiences():
    d = 24.0
    t = np.arange(int(d * SR)) / SR
    wind = lowpass(noise(d), 0.01) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 7.0))
    forest = wind * 1.2
    for _ in range(26):  # chants d'oiseaux
        st = rng.uniform(0, d - 1)
        f0 = rng.uniform(2200, 4200)
        n = int(rng.uniform(0.08, 0.22) * SR)
        tt = np.arange(n) / SR
        chirp = np.sin(2 * np.pi * (f0 * tt + rng.uniform(-3000, 3000) * tt * tt)) * env(n, 0.005, 0.06)
        for rep in range(rng.integers(1, 4)):
            i = int((st + rep * 0.18) * SR)
            if i + n < len(forest):
                forest[i:i + n] += chirp * 0.25
    save("ambience/foret.ogg", loop_fade(forest))
    water = lowpass(noise(d), 0.25) - lowpass(noise(d), 0.02)
    water *= 0.6 + 0.4 * lowpass(np.abs(noise(d)), 0.0005) * 4
    for _ in range(60):  # clapotis
        i = int(rng.uniform(0, d - 0.2) * SR)
        n = int(0.05 * SR)
        f = rng.uniform(600, 1400)
        water[i:i + n] += np.sin(2 * np.pi * f * np.arange(n) / SR) * env(n, 0.002, 0.02) * 0.3
    save("ambience/eau.ogg", loop_fade(water))
    night = wind * 0.4
    cr = np.sin(2 * np.pi * 4300 * t) * (np.sin(2 * np.pi * 28 * t) > 0.6) * (np.sin(2 * np.pi * 0.7 * t) > 0)
    night += cr * 0.08
    for st in (5.0, 15.0):  # chouette
        for k, dt in enumerate((0.0, 0.45, 0.65)):
            n = int(0.35 * SR)
            i = int((st + dt) * SR)
            tt = np.arange(n) / SR
            night[i:i + n] += np.sin(2 * np.pi * (420 - 40 * k) * tt) * env(n, 0.05, 0.15) * 0.4
    save("ambience/nuit.ogg", loop_fade(night))
    save("ambience/vent.ogg", loop_fade(lowpass(noise(d), 0.03) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 5.0) ** 2)))
    fire = lowpass(noise(d), 0.08) * 0.3
    for _ in range(320):
        i = int(rng.uniform(0, d - 0.05) * SR)
        n = int(rng.uniform(0.003, 0.02) * SR)
        fire[i:i + n] += rng.uniform(-1, 1, n) * rng.uniform(0.3, 1.0)
    save("ambience/feu.ogg", loop_fade(fire))


def sfx():
    def thud(f, dur, nz=0.5):
        n = int(dur * SR)
        tt = np.arange(n) / SR
        return (np.sin(2 * np.pi * f * tt * (1 - 0.3 * tt / dur)) * (1 - nz) + rng.uniform(-1, 1, n) * nz) * env(n, 0.001, dur / 4)
    save("sfx/hache.ogg", thud(140, 0.35, 0.55))
    pick = thud(900, 0.3, 0.35)
    pick[: int(0.15 * SR)] += 0.5 * thud(2400, 0.15, 0.2)
    save("sfx/pioche.ogg", pick)
    save("sfx/pelle.ogg", lowpass(rng.uniform(-1, 1, int(0.4 * SR)), 0.2) * env(int(0.4 * SR), 0.02, 0.12))
    save("sfx/marteau.ogg", thud(320, 0.25, 0.3))
    saw = rng.uniform(-1, 1, int(0.6 * SR)) * (np.sin(2 * np.pi * 7 * np.arange(int(0.6 * SR)) / SR) > 0)
    save("sfx/scie.ogg", lowpass(saw, 0.4) * env(int(0.6 * SR), 0.01, 0.5))
    shot = rng.uniform(-1, 1, int(0.9 * SR)) * env(int(0.9 * SR), 0.001, 0.12) + thud(60, 0.9, 0.0) * 0.8
    save("sfx/fusil.ogg", shot)
    n = int(2.2 * SR)
    tt = np.arange(n) / SR
    howl = np.sin(2 * np.pi * (380 + 160 * np.sin(np.pi * tt / 2.2)) * tt) * np.sin(np.pi * tt / 2.2) ** 2
    save("sfx/loup.ogg", howl + 0.05 * rng.uniform(-1, 1, n))
    n = int(1.0 * SR)
    growl = lowpass(rng.uniform(-1, 1, n), 0.05) * (0.5 + 0.5 * np.sin(2 * np.pi * 30 * np.arange(n) / SR)) * env(n, 0.1, 0.6)
    save("sfx/ours.ogg", growl)
    bell = sum(np.sin(2 * np.pi * f * np.arange(int(3 * SR)) / SR) * a for f, a in ((520, 1), (1310, 0.5), (2080, 0.3), (780, 0.4)))
    save("sfx/cloche.ogg", bell * env(int(3 * SR), 0.002, 0.9))
    save("sfx/clic.ogg", thud(1800, 0.06, 0.2))
    save("sfx/pose.ogg", thud(220, 0.18, 0.4))
    fan = np.concatenate([pluck(note_freq(s + 12), 0.35, 0.6) for s in (0, 4, 7, 12)])
    save("sfx/fanfare.ogg", fan)
    save("sfx/naissance.ogg", np.concatenate([pluck(note_freq(s + 24), 0.3, 0.7) for s in (7, 4, 12)]))


if __name__ == "__main__":
    dorian = [0, 2, 3, 5, 7, 9, 10]
    mixolydian = [0, 2, 4, 5, 7, 9, 10]
    aeolian = [0, 2, 3, 5, 7, 8, 10]
    music("matin_au_village", mixolydian, 84, 24, 0, seed=1)
    music("chemin_des_lutins", dorian, 96, 28, 2, seed=2)
    music("veillee", aeolian, 66, 20, -2, seed=3)
    ambiences()
    sfx()
    print("audio OK")
