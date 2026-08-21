#!/usr/bin/env python3
"""烘焙密码锁的两个音效：sfx_unlock.ogg / sfx_wrong.ogg

规格与 assets/audio/ 现有文件一致：22050Hz / 单声道，OGG Vorbis。
"""
import math
import random
from pathlib import Path

import soundfile as sf

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
random.seed(20240517)


def write_wav(name: str, samples: list[float]) -> None:
    path = OUT / f"{name}.ogg"
    sf.write(str(path), samples, SR, format="OGG", subtype="VORBIS")
    print(f"wrote {path} ({len(samples) / SR:.2f}s)")


def tone(freq: float, dur: float, amp: float, decay: float = 6.0) -> list[float]:
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = amp * math.exp(-decay * t / dur)
        v = math.sin(2 * math.pi * freq * t)
        # 轻微二次谐波，让音色更接近机械"滴"声
        v += 0.35 * math.sin(2 * math.pi * freq * 2 * t)
        out.append(v * env)
    return out


def concat(*parts: list[float], gap: float = 0.0) -> list[float]:
    out: list[float] = []
    for p in parts:
        out.extend(p)
        out.extend([0.0] * int(gap * SR))
    return out


def unlock() -> list[float]:
    # 电子锁弹开：短促"滴" 660Hz → 高"嗒" 990Hz，随后轻微的机械"咔"
    return concat(tone(660, 0.07, 0.55), tone(990, 0.11, 0.6), gap=0.02)


def wrong() -> list[float]:
    # 错误提示：低频短促"嗡" + 噪声尾
    n = int(0.42 * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-7 * t)
        v = 0.7 * math.sin(2 * math.pi * 140 * t) * (1.0 if math.sin(2 * math.pi * 140 * t) > 0 else 0.15)
        v += 0.08 * (random.random() * 2 - 1)
        out.append(v * env)
    return out


if __name__ == "__main__":
    write_wav("sfx_unlock", unlock())
    write_wav("sfx_wrong", wrong())
