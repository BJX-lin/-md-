#!/usr/bin/env python3
"""音频自检：检查 game/assets/audio 下的音频文件能否被引擎正常解码。

检查项：
  1. Ogg 魔数（OggS）与 Vorbis 标识头（\\x01vorbis）
  2. Ogg 页结构完整性（页序号连续、单一位流串号、末页 EOS 结束标志、无尾部垃圾）
  3. 位流串号全目录唯一、非 0
  4. 若安装了 soundfile（pip install soundfile）则做完整解码验证

用法：python3 tools/check_audio.py [audio_dir]
"""
import struct
import sys
from pathlib import Path

AUDIO_DIR = Path(__file__).resolve().parent.parent / "assets" / "audio"


def parse_pages(data: bytes):
    """返回 (页列表, 尾部垃圾字节数)。页 = (offset, serial, seq, eos, payload_len)"""
    pages = []
    pos = 0
    while pos < len(data):
        if data[pos:pos + 4] != b"OggS":
            return pages, len(data) - pos
        htype = data[pos + 5]
        serial = struct.unpack("<I", data[pos + 14:pos + 18])[0]
        seq = struct.unpack("<I", data[pos + 18:pos + 22])[0]
        nseg = data[pos + 26]
        plen = sum(data[pos + 27:pos + 27 + nseg])
        pages.append((pos, serial, seq, bool(htype & 4), plen))
        pos += 27 + nseg + plen
    return pages, 0


def main() -> int:
    audio_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else AUDIO_DIR
    if not audio_dir.is_dir():
        print("找不到目录", audio_dir)
        return 1

    try:
        import soundfile as sf  # noqa: F401
        can_decode = True
    except ImportError:
        can_decode = False
        print("（未安装 soundfile，跳过完整解码验证：pip install soundfile）")

    errors = []
    serials = {}
    files = sorted(p for p in audio_dir.iterdir() if p.suffix == ".ogg")
    for p in files:
        data = p.read_bytes()
        if data[:4] != b"OggS":
            errors.append(f"{p.name}: 缺少 OggS 魔数")
            continue
        if b"\x01vorbis" not in data[:8192]:
            errors.append(f"{p.name}: 缺少 Vorbis 标识头（可能封装了非 Vorbis 编码）")
            continue
        pages, junk = parse_pages(data)
        if junk:
            errors.append(f"{p.name}: 末页之后有 {junk} 字节垃圾数据")
        if not pages or not pages[-1][3]:
            errors.append(f"{p.name}: 缺少 EOS 结束标志（文件可能被截断）")
        seqs = [pg[2] for pg in pages]
        if seqs != list(range(len(seqs))):
            errors.append(f"{p.name}: 页序号不连续 {seqs[:6]}...")
        if len({pg[1] for pg in pages}) > 1:
            errors.append(f"{p.name}: 含多个位流串号（链式流，引擎兼容性差）")
        serials[p.name] = pages[0][1] if pages else 0
        if can_decode:
            try:
                import soundfile as sf
                frames, sr = sf.read(str(p))
                if len(frames) == 0:
                    raise RuntimeError("空音频")
            except Exception as e:  # noqa: BLE001
                errors.append(f"{p.name}: 完整解码失败（{e}）")

    zero = [n for n, s in serials.items() if s == 0]
    if zero:
        errors.append(f"位流串号为 0（部分解码器拒绝）：{', '.join(zero)}")
    seen: dict[int, str] = {}
    for n, s in serials.items():
        if s in seen:
            errors.append(f"{n} 与 {seen[s]} 位流串号重复（0x{s:08X}）")
        seen[s] = n

    print(f"共检查 {len(files)} 个 OGG（目录 {audio_dir}）")
    if errors:
        for e in errors:
            print("  [FAIL]", e)
        print(f"发现 {len(errors)} 个问题")
        return 1
    print("全部通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
