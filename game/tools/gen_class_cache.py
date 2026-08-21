#!/usr/bin/env python3
"""生成 .godot/global_script_class_cache.cfg（等价于 Godot 编辑器首次打开工程时的产物）。

用于无头验证/CI：在没有编辑器的情况下，模板二进制加载工程需要全局类缓存
才能解析 class_name（UITex / BGLayer 等）。

用法：python3 tools/gen_class_cache.py [工程根目录]
"""
import re
import sys
from pathlib import Path

BASE_BY_EXTENDS = {
    "Control": "Control",
    "Node": "Node",
    "RefCounted": "RefCounted",
    "Node2D": "Node2D",
    "Object": "Object",
}


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    entries = []
    for gd in sorted(root.rglob("*.gd")):
        if ".godot" in gd.parts or "tools" in gd.parts:
            continue
        text = gd.read_text(encoding="utf-8")
        m = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.M)
        if not m:
            continue
        name = m.group(1)
        base = BASE_BY_EXTENDS.get(
            re.search(r"^extends\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.M).group(1),
            "Object",
        ) if re.search(r"^extends\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.M) else "Object"
        rel = str(gd.relative_to(root)).replace("\\", "/")
        entries.append({
            "class": name,
            "language": "GDScript",
            "path": f"res://{rel}",
            "base": base,
            "icon": "",
            "is_abstract": False,
            "is_tool": False,
        })
    entries.sort(key=lambda d: d["class"])

    def sname(s: str) -> str:
        return f'&"{s}"'

    def qstr(s: str) -> str:
        return f'"{s}"'

    lines = ["list=Array[Dictionary](["]
    for i, e in enumerate(entries):
        lines.append("{")
        lines.append(f'{qstr("base")}: {sname(e["base"])},')
        lines.append(f'{qstr("class")}: {sname(e["class"])},')
        lines.append(f'{qstr("icon")}: {qstr(e["icon"])},')
        lines.append(f'{qstr("is_abstract")}: {"true" if e["is_abstract"] else "false"},')
        lines.append(f'{qstr("is_tool")}: {"true" if e["is_tool"] else "false"},')
        lines.append(f'{qstr("language")}: {sname(e["language"])},')
        lines.append(f'{qstr("path")}: {qstr(e["path"])}')
        lines.append("}" + ("," if i < len(entries) - 1 else ""))
    lines.append("])")

    out_dir = root / ".godot"
    out_dir.mkdir(exist_ok=True)
    (out_dir / "global_script_class_cache.cfg").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"生成 {out_dir / 'global_script_class_cache.cfg'}：{len(entries)} 个全局类")
    return 0


if __name__ == "__main__":
    sys.exit(main())
