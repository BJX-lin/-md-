#!/usr/bin/env python3
"""去除 GDScript 代码中的中文注释，只保留极简英文标签注释。

规则：
- 识别每行中第一个不在引号内的 '#' 作为注释起点
- 注释含中文时：按关键词映射替换为简短英文标签（如 音频→Audio、存档→Save/Load），
  没有匹配关键词则整段注释删除
- 代码部分（含中文字符串字面量）完全不动
- 纯 ASCII 注释保留原样
用法：python3 tools/strip_comments.py [文件或目录...]
"""
import re
import sys
from pathlib import Path

CJK = re.compile(r"[\u4e00-\u9fff]")

# 中文关键词 -> 简短英文标签（仅保留这类注释）
LABELS = [
    (r"音频|音效|BGM|背景音乐", "Audio"),
    (r"存档|读档|读取|保存|序列化", "Save/Load"),
    (r"立绘", "Sprite"),
    (r"背景|场景图", "Background"),
    (r"文本|台词|旁白", "Text"),
    (r"选项", "Choices"),
    (r"引擎", "Engine"),
    (r"结局", "Endings"),
    (r"章节", "Chapters"),
    (r"条件|判定", "Conditions"),
    (r"状态", "State"),
    (r"道具", "Items"),
    (r"线索", "Clues"),
    (r"性能", "Perf"),
    (r"界面|UI", "UI"),
    (r"时间", "Time"),
    (r"密码", "Password lock"),
    (r"命名|名字", "Name"),
    (r"完整性", "Integrity"),
    (r"主题", "Theme"),
    (r"特效|演出", "FX"),
    (r"开场|闪屏", "Splash"),
    (r"标题", "Title"),
    (r"数值", "Stats"),
    (r"剧情|剧本", "Story"),
    (r"缓存", "Cache"),
    (r"音量|总线", "Volume"),
    (r"初始化|重置", "Init"),
    (r"绘制|渲染|重绘", "Draw"),
    (r"呼吸|浮动", "Breathe"),
    (r"流血|血腥", "Gore"),
    (r"信任", "Trust"),
    (r"理智", "Sanity"),
    (r"真相", "Truth"),
]


def find_comment(line: str) -> int:
    """返回第一个不在字符串内的 '#' 下标；无则 -1。"""
    in_s = False        # "..." 双引号字符串
    in_s2 = False       # '...' 单引号字符串
    i = 0
    while i < len(line):
        c = line[i]
        if in_s:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_s = False
        elif in_s2:
            if c == "\\":
                i += 2
                continue
            if c == "'":
                in_s2 = False
        else:
            if c == '"':
                in_s = True
            elif c == "'":
                in_s2 = True
            elif c == "#":
                return i
        i += 1
    return -1


def label_for(comment: str) -> str:
    for pat, label in LABELS:
        if re.search(pat, comment):
            return label
    return ""


def strip_line(line: str) -> str:
    idx = find_comment(line)
    if idx < 0:
        return line
    code = line[:idx]
    comment = line[idx:]
    if not CJK.search(comment):
        return line  # 英文注释保留
    # 中文注释 → 简短标签或删除
    label = label_for(comment)
    if not label:
        if code.strip():
            return code.rstrip()
        return ""  # 整行都是注释且无标签 → 删除该行
    marker = "# " + label
    if code.strip():
        return code.rstrip() + "  " + marker
    # 整行注释：保持原有缩进
    indent = line[: len(line) - len(line.lstrip())]
    return indent + marker


def strip_file(path: Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines()
    out = []
    changed = False
    for line in lines:
        new = strip_line(line)
        if new != line:
            changed = True
        out.append(new)
    if changed:
        path.write_text("\n".join(out) + ("\n" if out and out[-1] == "" else ""), encoding="utf-8")
    return changed


def main() -> int:
    targets = sys.argv[1:] or ["autoload", "src", "tools"]
    n = 0
    for t in targets:
        p = Path(t)
        if p.is_dir():
            for f in sorted(p.rglob("*.gd")):
                if strip_file(f):
                    n += 1
        elif p.is_file():
            if strip_file(p):
                n += 1
    print(f"已处理 {n} 个文件")
    return 0


if __name__ == "__main__":
    sys.exit(main())
