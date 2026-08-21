#!/usr/bin/env python3
"""重新生成 autoload/integrity_manifest.gd 中的核心文件 SHA256 清单。

用法：
    python3 tools/gen_integrity.py            # 打印各文件摘要
    python3 tools/gen_integrity.py --write    # 写回 manifest（PLACEHOLDER/旧值替换为新值）

规则与 integrity_manifest.gd 保持一致：摘要 = sha256(SALT 字节 + 文件字节)。
"""
import hashlib
import re
import sys
from pathlib import Path

GAME_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = GAME_ROOT / "autoload" / "integrity_manifest.gd"
SALT = "The13thPeriod::integrity::v1".encode("utf-8")

PROTECTED = [
    "autoload/config.gd",
    "autoload/game_state.gd",
    "autoload/save_system.gd",
    "autoload/story_engine.gd",
]


def digest(rel: str) -> str:
    data = (GAME_ROOT / rel).read_bytes()
    return hashlib.sha256(SALT + data).hexdigest()


def main() -> int:
    results = {rel: digest(rel) for rel in PROTECTED}
    for rel, d in results.items():
        print(f"{d}  {rel}")

    if "--write" in sys.argv:
        text = MANIFEST_PATH.read_text(encoding="utf-8")
        for rel, d in results.items():
            # 替换 manifest 字典里对应行（兼容 PLACEHOLDER 与旧摘要）
            text = re.sub(
                rf'(\t"{re.escape(rel)}": ")([0-9a-f]{{64}}|PLACEHOLDER)(",)',
                rf"\g<1>{d}\g<3>",
                text,
            )
        MANIFEST_PATH.write_text(text, encoding="utf-8")
        print("已写入", MANIFEST_PATH)
    return 0


if __name__ == "__main__":
    sys.exit(main())
