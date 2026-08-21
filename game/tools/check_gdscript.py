#!/usr/bin/env python3
"""GDScript 轻量静态检查（不依赖 Godot 可执行文件）

检查项：
  1. 括号 / 方括号 / 花括号 是否配平（按逻辑行，支持续行）
  2. preload / load 的 res:// 路径是否存在
  3. 缩进是否混用空格与制表符
  4. Callable(self, "name") 引用的方法是否存在
  5. autoload 单例名是否在 project.godot 中注册
  6. signal 连接的信号是否在目标脚本中声明（跨脚本按名字宽松匹配）
  7. 关键字拼写：func/var/const/signal 行的基本形态
  8. 自定义方法是否覆盖 Node/Object 原生方法（Godot 会当成错误）
  9. 是否误用了 GLSL/着色器专有函数（GDScript 中不存在）
 11. 字典字面量里出现重复键（Godot 直接报错）
 12. 访问 autoload 上不存在的常量（运行时才会暴露）
 10. := 无法推断类型：三元两分支类型不一致 / 索引无类型集合 /
     使用返回 Variant 的全局数学函数（abs、max、clamp…应改用 absf、maxf…）
"""
import os
import re
import sys

def _find_root():
    """兼容两种布局：仓库(tools/ 与 game/ 平级) 与 发布包(_tools/ 与 project.godot 平级)"""
    here = os.path.dirname(os.path.abspath(__file__))
    for base in (os.path.dirname(here), here):
        for cand in (os.path.join(base, "game"), base):
            if os.path.isfile(os.path.join(cand, "project.godot")):
                return cand
    return os.path.join(os.path.dirname(here), "game")

# 自定义同名会触发 "overrides a method from native class" 错误
NATIVE_METHODS = {
    "has_node", "get_node", "find_child", "find_children", "add_child", "remove_child",
    "get_parent", "get_children", "get_child", "get_index", "queue_free", "is_inside_tree",
    "get_tree", "set_process", "set_physics_process", "connect", "disconnect",
    "emit_signal", "has_signal", "has_method", "get_class", "is_class", "set_script",
    "get_script", "duplicate", "free", "notification", "to_string", "get", "set", "call",
    "callv", "get_path", "set_name", "get_name", "print_tree", "replace_by", "show",
    "hide", "is_visible", "set_owner", "get_owner", "add_to_group", "is_in_group",
    "remove_from_group", "get_groups", "get_viewport", "get_window", "get_rect",
    "get_size", "set_size", "get_position", "set_position", "grab_focus", "has_focus",
    "get_global_position", "update", "raise",
}

# 这些是着色器(GLSL)函数，GDScript 里不存在，误用会报
# "Function xxx() not found in base self."
GLSL_ONLY = {
    "step": "改用 (1.0 if x >= edge else 0.0)",
    "mix": "改用 lerp() / lerpf()",
    "fract": "改用 fmod(x, 1.0)",
    "clamp01": "改用 clampf(x, 0.0, 1.0)",
    "dFdx": "着色器专用",
    "dFdy": "着色器专用",
    "refract": "着色器专用",
    "faceforward": "着色器专用",
    "inversesqrt": "改用 1.0 / sqrt(x)",
}

GAME = _find_root()
ROOT = GAME


def res_to_path(p):
    return os.path.join(GAME, p.replace("res://", ""))


def logical_lines(src):
    """把续行（括号未闭合 / 反斜杠结尾）合并成逻辑行"""
    out = []
    buf = ""
    depth = 0
    start_ln = 1
    for ln, raw in enumerate(src.split("\n"), 1):
        line = raw.split("#")[0] if not in_string_hash(raw) else strip_comment(raw)
        if not buf:
            start_ln = ln
        buf += line
        depth += count_depth(line)
        if depth <= 0:
            out.append((start_ln, buf, depth))
            buf = ""
            depth = 0
    if buf:
        out.append((start_ln, buf, depth))
    return out


def in_string_hash(line):
    return '"' in line and "#" in line and line.index('"') < line.index("#")


def strip_comment(line):
    out = ""
    in_str = False
    q = ""
    i = 0
    while i < len(line):
        c = line[i]
        if in_str:
            if c == "\\":
                out += line[i:i + 2]
                i += 2
                continue
            if c == q:
                in_str = False
            out += c
        else:
            if c in "\"'":
                in_str = True
                q = c
                out += c
            elif c == "#":
                break
            else:
                out += c
        i += 1
    return out


def count_depth(line):
    d = 0
    in_str = False
    q = ""
    i = 0
    while i < len(line):
        c = line[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == q:
                in_str = False
        else:
            if c in "\"'":
                in_str = True
                q = c
            elif c in "([{":
                d += 1
            elif c in ")]}":
                d -= 1
        i += 1
    return d


def main():
    errors, warnings = [], []
    gd_files = []
    for base, _, files in os.walk(GAME):
        for f in files:
            if f.endswith(".gd"):
                gd_files.append(os.path.join(base, f))
    gd_files.sort()

    autoloads = set()
    proj = open(os.path.join(GAME, "project.godot"), encoding="utf-8").read()
    in_auto = False
    for line in proj.split("\n"):
        if line.strip() == "[autoload]":
            in_auto = True
            continue
        if line.startswith("[") and in_auto:
            in_auto = False
        if in_auto and "=" in line:
            autoloads.add(line.split("=")[0].strip())
            path = line.split("=")[1].strip().strip('"').lstrip("*")
            if path.startswith("res://") and not os.path.exists(res_to_path(path)):
                errors.append(f"project.godot autoload 指向不存在的文件: {path}")

    all_signals = set()
    all_funcs = {}
    for path in gd_files:
        src = open(path, encoding="utf-8").read()
        all_signals |= set(re.findall(r"^signal\s+([a-zA-Z_0-9]+)", src, re.M))
        all_funcs[path] = set(re.findall(r"^\s*(?:static\s+)?func\s+([a-zA-Z_0-9]+)", src, re.M))

    # 收集各 autoload 脚本里定义的常量与顶层变量，
    # 用于检测「访问不存在的成员」这类只能在运行时才暴露的错误。
    AUTOLOAD_MEMBERS = {}
    _auto_files = {
        "Cfg": "autoload/config.gd",
        "GameState": "autoload/game_state.gd",
        "StoryEngine": "autoload/story_engine.gd",
        "AudioDirector": "autoload/audio_director.gd",
        "SaveSystem": "autoload/save_system.gd",
        "ArtCache": "autoload/art_cache.gd",
    }
    for _name, _rel in _auto_files.items():
        _p = os.path.join(GAME, _rel)
        if not os.path.isfile(_p):
            continue
        _src = open(_p, encoding="utf-8").read()
        AUTOLOAD_MEMBERS[_name] = set(
            re.findall(r"^const\s+([A-Z][A-Z_0-9]*)", _src, re.M))

    total_lines = 0
    for path in gd_files:
        rel = os.path.relpath(path, ROOT)
        src = open(path, encoding="utf-8").read()
        total_lines += src.count("\n")

        # 1. 括号配平
        depth = 0
        for ln, line, _d in logical_lines(src):
            depth += count_depth(line)
            if depth < 0:
                errors.append(f"{rel}:{ln} 括号多余闭合")
                depth = 0
        if depth != 0:
            errors.append(f"{rel} 文件末尾括号未闭合 (深度 {depth})")

        # 2. preload 路径
        for m in re.finditer(r'(?:preload|load)\(\s*"(res://[^"]+)"', src):
            p = m.group(1)
            if not os.path.exists(res_to_path(p)):
                if "assets/fonts" in p:
                    continue  # 可选字体，运行时用 ResourceLoader.exists 判断
                errors.append(f"{rel} preload 路径不存在: {p}")

        # 3. 缩进混用
        for ln, raw in enumerate(src.split("\n"), 1):
            indent = re.match(r"^[ \t]*", raw).group(0)
            if " " in indent and "\t" in indent:
                errors.append(f"{rel}:{ln} 缩进混用空格与制表符")

        # 4. Callable(self, "x")
        for m in re.finditer(r'Callable\(\s*self\s*,\s*"([a-zA-Z_0-9]+)"', src):
            if m.group(1) not in all_funcs[path]:
                errors.append(f"{rel} Callable 引用了不存在的方法: {m.group(1)}")

        # 5. 单例引用
        for name in re.findall(r"\b(Cfg|GameState|StoryEngine|AudioDirector|SaveSystem)\b", src):
            if name not in autoloads:
                errors.append(f"{rel} 引用了未注册的单例: {name}")
                break

        # 6. signal 连接
        for m in re.finditer(r"\.([a-z_0-9]+)\.connect\(", src):
            sig = m.group(1)
            builtin = {
                "pressed", "toggled", "value_changed", "tree_exited", "tree_entered",
                "text_changed", "item_selected", "timeout", "finished", "gui_input",
                "resized", "visibility_changed", "mouse_entered", "mouse_exited", "ready",
            }
            if sig not in all_signals and sig not in builtin:
                warnings.append(f"{rel} 连接了未声明的信号: {sig}")

        # 8. 覆盖原生方法
        for m in re.finditer(r"^\s*(?:static\s+)?func\s+([a-zA-Z_0-9]+)", src, re.M):
            if m.group(1) in NATIVE_METHODS:
                ln = src[:m.start()].count("\n") + 1
                errors.append(
                    f"{rel}:{ln} 方法 {m.group(1)}() 覆盖了原生方法，"
                    f"Godot 会报错，请改名（如 {m.group(1)}_x）")

        # 9. GLSL 专有函数误用
        own_funcs = all_funcs.get(path, set())
        for name, hint in GLSL_ONLY.items():
            for m in re.finditer(r"(?<![\w.])" + name + r"\s*\(", src):
                # 自己定义了同名函数(如 _step)或作为方法调用则跳过
                if name in own_funcs:
                    continue
                ln = src[:m.start()].count("\n") + 1
                line_txt = src.split("\n")[ln - 1]
                if line_txt.strip().startswith(("#", "//")):
                    continue
                errors.append(
                    f"{rel}:{ln} 误用着色器函数 {name}()，GDScript 中不存在。{hint}")

        # 10. := 无法推断类型：三元表达式两分支类型不一致，
        #     或分支里索引了未标注元素类型的集合（返回 Variant）。
        #     Godot 报 "Cannot infer the type of "x" variable because
        #     the value doesn't have a set type."
        untyped_colls = set(
            re.findall(r"^\s*(?:const|var)\s+([A-Za-z_0-9]+)\s*:=\s*[\[{]", src, re.M))
        for ln, raw in enumerate(src.split("\n"), 1):
            st = raw.strip()
            if st.startswith(("#", "//")):
                continue
            m = re.match(r"var\s+([A-Za-z_0-9]+)\s*:=\s*(.+)$", st)
            if not m:
                continue
            name, expr = m.group(1), m.group(2)
            if " if " not in expr or " else " not in expr:
                continue
            then_part = expr.split(" if ")[0].strip()
            else_part = expr.split(" else ", 1)[1].strip()

            def _variant_src(part):
                # 索引未标注元素类型的集合
                for coll in untyped_colls:
                    if re.search(r"(?<![\w.])" + re.escape(coll) + r"\s*\[", part):
                        return f"{coll}[...] 返回 Variant"
                # Dictionary.get() / Array.pop 等返回 Variant
                if re.search(r"\.get\s*\(", part) and not re.search(
                        r"\b(?:float|int|str|bool)\s*\(\s*[^)]*\.get\s*\(", part):
                    return ".get() 返回 Variant"
                return None

            reason = _variant_src(then_part) or _variant_src(else_part)
            if reason:
                errors.append(
                    f"{rel}:{ln} var {name} := 三元表达式无法推断类型（{reason}）。"
                    f"请改为显式标注，如 var {name}: String = ...，"
                    f"或给集合加元素类型（Array[String]）")

        # 10b. := 使用了返回 Variant 的全局数学函数（Godot 4 应改用 f/i 变体）
        #      abs/max/min/clamp/sign/round/floor/ceil/snapped/wrap 的无后缀版本
        #      返回 Variant，参与 := 推断时会报
        #      Cannot infer the type of "x" variable...
        VARIANT_MATH = ("abs", "max", "min", "clamp", "sign",
                        "round", "floor", "ceil", "snapped", "wrap")
        for ln, raw in enumerate(src.split("\n"), 1):
            st = raw.strip()
            if st.startswith(("#", "//")):
                continue
            m = re.match(r"var\s+([A-Za-z_0-9]+)\s*:=\s*(.+)$", st)
            if not m:
                continue
            name, expr = m.group(1), m.group(2)
            for fn_name in VARIANT_MATH:
                if re.search(r"(?<![A-Za-z_.])" + fn_name + r"\s*\(", expr):
                    col = raw.index("var ") + 5
                    errors.append(
                        f"{rel}:{ln}:{col} var {name} := 使用了返回 Variant 的 "
                        f"{fn_name}()，无法推断类型。Godot 4 请改用 "
                        f"{fn_name}f() / {fn_name}i()，或显式标注 "
                        f"var {name}: <类型> = ...")
                    break

        # 11. 字典字面量里出现重复键
        #     Godot 报 Key "x" was already used in this dictionary
        #     嵌套字典按缩进层级分组统计，避免跨层误报。
        depth_keys = {}
        brace = 0
        for ln, raw in enumerate(src.split("\n"), 1):
            st = raw.strip()
            if st.startswith(("#", "//")):
                continue
            opens = st.count("{")
            closes = st.count("}")
            m = re.match(r'^"([^"]+)"\s*:', st)
            if m and brace > 0:
                bucket = depth_keys.setdefault(brace, {})
                k = m.group(1)
                if k in bucket:
                    errors.append(
                        f"{rel}:{ln} 字典中重复的键 \"{k}\"，"
                        f"首次出现在第 {bucket[k]} 行（Godot 会直接报错）")
                else:
                    bucket[k] = ln
            # 进入更深层或退出当前层时，清掉更深层的记录
            if opens > closes:
                brace += opens - closes
            elif closes > opens:
                for d in list(depth_keys):
                    if d >= brace:
                        depth_keys.pop(d, None)
                brace = max(0, brace - (closes - opens))

        # 12. 访问 autoload 上不存在的常量 / 属性
        #     Godot 报 Invalid access to property or key 'X'
        #     on a base object of type 'Node (xxx.gd)'
        for ln, raw in enumerate(src.split("\n"), 1):
            st = raw.strip()
            if st.startswith(("#", "//")):
                continue
            for m in re.finditer(r"(?<![\w.])(" + "|".join(AUTOLOAD_MEMBERS.keys())
                                 + r")\.([A-Z][A-Z_0-9]{2,})(?![\w(])", st):
                singleton, member = m.group(1), m.group(2)
                known = AUTOLOAD_MEMBERS.get(singleton, set())
                if known and member not in known:
                    near = [k for k in known if k.startswith(member[:3])]
                    hint = f"，是否想写 {near[0]}？" if near else ""
                    errors.append(
                        f"{rel}:{ln} {singleton} 上不存在常量 {member}{hint}")

        # 7. func 行基本形态
        for ln, raw in enumerate(src.split("\n"), 1):
            st = raw.strip()
            if st.startswith("func ") and not st.rstrip().endswith(":") and "->" not in st:
                if not st.rstrip().endswith(":"):
                    errors.append(f"{rel}:{ln} func 定义缺少冒号: {st[:50]}")

    print("=" * 62)
    print("GDScript 静态检查")
    print("=" * 62)
    print(f"脚本文件 : {len(gd_files)}")
    print(f"代码行数 : {total_lines}")
    print(f"自动加载 : {', '.join(sorted(autoloads))}")
    print("-" * 62)
    for w in warnings:
        print("  [warn ]", w)
    for e in errors:
        print("  [ERROR]", e)
    print("-" * 62)
    print(f"错误 {len(errors)} 个，警告 {len(warnings)} 个")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
