#!/usr/bin/env python3
"""校验 .avg 剧本：节点、跳转目标、@if/@endif 配对、@padlock 参数、未知命令。

规则与 autoload/story_engine.gd 的解析器保持一致。
用法：python3 tools/check_avg.py [story_dir]
"""
import re
import sys
from pathlib import Path

KNOWN_CMDS = {
    "bg", "bgm", "stopbgm", "amb", "stopamb", "sfx", "fx", "show", "hide",
    "clearchars", "set", "flag", "state", "item", "clue", "death", "gallery",
    "title", "roster", "note", "padlock", "time", "timeat", "advtime", "wait",
    "chapter", "settle", "autosave", "goto", "ending", "return",
}
KNOWN_CHARS = {
    "linzhou", "zhouxu", "liangye", "xuqing", "shenhe", "dorm_keeper",
    "classmate_girl", "classmate_boy", "canteen_aunt", "oldqin", "voice",
    "radio", "liheng", "classmate", "crowd", "unknown", "me",
}


def main() -> int:
    story_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("story")
    if not story_dir.is_dir():
        print("找不到剧本目录", story_dir)
        return 1

    errors: list[str] = []
    nodes: dict[str, str] = {}          # node -> file
    used_targets: dict[str, list] = {}  # target -> [(file, line)]
    if_stack: list[int] = []
    last_choice: list[tuple[str, str, int]] = []

    for path in sorted(story_dir.glob("*.avg")):
        cur = ""
        for ln, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            line = raw.rstrip()
            stripped = line.strip()
            where = f"{path.name}:{ln}"
            if not stripped or stripped.startswith("--"):
                continue
            if stripped.startswith("=="):
                cur = stripped[2:].strip()
                if cur in nodes:
                    errors.append(f"{where} 重复节点 {cur}（先见于 {nodes[cur]}）")
                nodes[cur] = where
                if_stack = []
                last_choice = []
                continue
            if not cur:
                continue
            # 选项效果行（缩进 @ 紧跟选项）
            if last_choice and line.startswith(" ") and stripped.startswith("@"):
                continue
            # 选项
            if stripped.startswith("*"):
                body = stripped[1:].strip()
                # 去 [if ...] [lock ...] 标签
                while body.startswith("["):
                    close = body.find("]")
                    if close < 0:
                        errors.append(f"{where} 选项标签缺 ]：{body}")
                        break
                    body = body[close + 1:].strip()
                arrow = body.rfind("->")
                target = body[arrow + 2:].strip() if arrow >= 0 else ""
                last_choice.append((target, where, ln))
                if target:
                    used_targets.setdefault(target, []).append(where)
                continue
            last_choice = []
            if stripped.startswith("@"):
                parts = stripped[1:].split()
                cmd = parts[0].lower()
                if cmd == "if":
                    if_stack.append(ln)
                elif cmd == "endif":
                    if not if_stack:
                        errors.append(f"{where} @endif 缺少 @if")
                    else:
                        if_stack.pop()
                elif cmd == "elif" or cmd == "else":
                    if not if_stack:
                        errors.append(f"{where} @{cmd} 缺少 @if")
                elif cmd == "goto":
                    if len(parts) < 2:
                        errors.append(f"{where} @goto 缺目标")
                    else:
                        used_targets.setdefault(parts[1], []).append(where)
                elif cmd == "padlock":
                    if len(parts) < 3:
                        errors.append(f"{where} @padlock 格式应为：@padlock 密码 成功节点 [失败节点] 提示")
                    else:
                        used_targets.setdefault(parts[2], []).append(where)
                        if len(parts) >= 4:
                            used_targets.setdefault(parts[3], []).append(where)
                elif cmd not in KNOWN_CMDS:
                    errors.append(f"{where} 未知命令 @{cmd}")
                continue
                # 台词：检查说话人
                m = re.match(r"^([A-Za-z_]+)(\([^)]*\))?[：:]", stripped)
                if m and m.group(1) not in KNOWN_CHARS:
                    errors.append(f"{where} 未知说话人 {m.group(1)}")
        if if_stack:
            errors.append(f"{path.name}: 节点 {cur} 的 @if 未闭合（行 {if_stack}）")

    # 目标节点存在性（__ending__ 由引擎运行时解析，跳过）
    for tgt, refs in sorted(used_targets.items()):
        if tgt == "__ending__":
            continue
        if tgt not in nodes:
            errors.append(f"目标节点不存在：{tgt}（引用自 {', '.join(refs[:3])}）")

    # 无条件选项 + 无 next 的节点尾部自动掉落（引擎行为：节点结束即停）
    print(f"共 {len(nodes)} 个节点")
    if errors:
        print("\n".join(f"[ERR] {e}" for e in errors))
        return 1
    print("全部校验通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
