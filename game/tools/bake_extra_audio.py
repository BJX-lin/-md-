#!/usr/bin/env python3
"""烘焙新增氛围音效（v1.1.2）：
sfx_clock_tick / sfx_nail_scrape / sfx_desk_drag / sfx_phone_buzz / sfx_water_drip

规格与 assets/audio/ 现有文件一致：22050Hz / 单声道，OGG Vorbis。
用法：python3 tools/bake_extra_audio.py
"""
import math
import random
from pathlib import Path

import soundfile as sf

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
random.seed(20240518)


def write(name: str, samples: list[float]) -> None:
    path = OUT / f"{name}.ogg"
    sf.write(str(path), samples, SR, format="OGG", subtype="VORBIS")
    print(f"wrote {path} ({len(samples) / SR:.2f}s)")


def silence(sec: float) -> list[float]:
    return [0.0] * int(sec * SR)


def clock_tick() -> list[float]:
    # 老式挂钟"嗒"：短促高频敲击 + 微弱余响
    n = int(0.09 * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-55 * t)
        v = 0.9 * math.sin(2 * math.pi * 2100 * t) * env
        v += 0.3 * math.sin(2 * math.pi * 3800 * t) * env
        out.append(v)
    return out


def nail_scrape() -> list[float]:
    # 指甲刮金属网/纸：滤波噪声 + 800Hz 金属共振，音高微降
    n = int(0.85 * SR)
    out = []
    last = 0.0
    for i in range(n):
        t = i / n
        v = random.random() * 2 - 1
        last += 0.06 * (v - last)          # 低通：纸/网面摩擦质感
        ring = math.sin(2 * math.pi * (820 - 120 * t) * i / SR) * 0.45
        env = math.sin(math.pi * t) ** 0.6  # 中间强两头弱
        out.append((last * 0.5 + ring) * env * 0.85)
    return out


def desk_drag() -> list[float]:
    # 课桌拖动：低频轰隆 + 周期性刮擦脉冲 + 尾声"咔"
    n = int(1.35 * SR)
    out = []
    for i in range(n):
        t = i / n
        rumble = 0.55 * math.sin(2 * math.pi * 68 * t) * math.sin(math.pi * t / 1.35) ** 2
        pulse = math.sin(2 * math.pi * 130 * t) if (t % 0.28) < 0.05 else 0.0
        out.append(rumble + pulse * 0.5 * math.exp(-6 * (t % 0.28)))
    # 结尾一下"咚"
    n2 = int(0.18 * SR)
    for i in range(n2):
        t = i / SR
        out.append(0.9 * math.sin(2 * math.pi * 90 * t) * math.exp(-25 * t))
    return out


def phone_buzz() -> list[float]:
    # 手机震动："嗡——嗡——"两段 180Hz 方波化振动
    def burst(dur: float) -> list[float]:
        n = int(dur * SR)
        b = []
        for i in range(n):
            t = i / SR
            phase = math.sin(2 * math.pi * 185 * t)
            square = 1.0 if phase > 0 else -1.0
            b.append(square * 0.5 * math.exp(-2 * t))
        return b
    return burst(0.75) + silence(0.22) + burst(0.55)


def water_drip() -> list[float]:
    # 水珠：下落"啪嗒" + 水面对敲的短促叮声
    n = int(0.38 * SR)
    out = []
    for i in range(n):
        t = i / SR
        splash = (random.random() * 2 - 1) * math.exp(-70 * t) * 0.55
        ping = math.sin(2 * math.pi * 1500 * t) * math.exp(-40 * t) * 0.5
        out.append(splash + ping)
    return out


if __name__ == "__main__":
    write("sfx_clock_tick", clock_tick())
    write("sfx_nail_scrape", nail_scrape())
    write("sfx_desk_drag", desk_drag())
    write("sfx_phone_buzz", phone_buzz())
    write("sfx_water_drip", water_drip())
