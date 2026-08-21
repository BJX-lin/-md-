#!/usr/bin/env python3
"""处理新生成的立绘：白底抠透明 + 内容感知裁切 768x768 + 白边清理。

输入：generate_image 输出的 PNG（纯白背景角色半身像）
输出：可直接使用的 RGBA PNG 立绘（assets/sprites 规格）
用法：python3 tools/process_sprite.py <输入文件> <输出文件.png>
"""
import sys
from collections import deque

from PIL import Image

SIZE = 768
WHITE_TH = 238          # 判定为背景白的阈值
ALPHA_TH = 8            # 抠图后低于此 alpha 视为全透明


def unwhite(img: Image.Image) -> Image.Image:
    """从四边 flood fill 白色背景 -> 透明，并清理边缘白边。"""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    visited = bytearray(w * h)
    queue = deque()
    for x in range(w):
        for y in (0, h - 1):
            queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if visited[i]:
            continue
        r, g, b, a = px[x, y]
        if r > WHITE_TH and g > WHITE_TH and b > WHITE_TH:
            visited[i] = 1
            if x > 0:
                queue.append((x - 1, y))
            if x < w - 1:
                queue.append((x + 1, y))
            if y > 0:
                queue.append((x, y - 1))
            if y < h - 1:
                queue.append((x, y + 1))
    for y in range(h):
        for x in range(w):
            if visited[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    # 白边清理：残留半透明像素去白（人物边缘抗锯齿灰边）
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if 0 < a < 250:
                white = min(r, g, b)
                if white > 200:
                    scale = 255.0 / max(1.0, (255.0 - white))
                    px[x, y] = (
                        min(255, max(0, int((r - white) * scale))),
                        min(255, max(0, int((g - white) * scale))),
                        min(255, max(0, int((b - white) * scale))),
                        a,
                    )
    return img


def crop_square(img: Image.Image) -> Image.Image:
    """内容感知中心裁 768x768：保证头顶留白约 8px、人物占满高度。"""
    img = img.convert("RGBA")
    w, h = img.size
    # 先粗抠（背景在 unwhite 后已透明），找内容边界
    px = img.load()
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(0, h, 3):
        for x in range(0, w, 3):
            if px[x, y][3] > ALPHA_TH:
                minx = min(minx, x); maxx = max(maxx, x)
                miny = min(miny, y); maxy = max(maxy, y)
    if maxy < 0:
        return img.resize((SIZE, SIZE), Image.LANCZOS)
    content_h = maxy - miny
    content_w = maxx - minx
    # 目标：内容高度约占 768 的 96%，顶部留白 ~8px
    scale = SIZE * 0.96 / max(content_h, 1)
    scale = min(scale, SIZE / max(content_w, 1))
    scale = min(scale, 2.0)   # 防止放大过度
    img = img.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
    w, h = img.size
    # 重新找边界（缩放后）
    px = img.load()
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(0, h, 3):
        for x in range(0, w, 3):
            if px[x, y][3] > ALPHA_TH:
                minx = min(minx, x); maxx = max(maxx, x)
                miny = min(miny, y); maxy = max(maxy, y)
    # 顶部对齐：留 8px 空间
    y0 = max(0, miny - 8)
    y0 = min(y0, max(0, h - SIZE))
    x0 = (w - SIZE) // 2
    if w < SIZE:
        x0 = 0
    img = img.crop((x0, y0, x0 + SIZE, y0 + SIZE))
    return img


def process(src: str, dst: str) -> None:
    img = Image.open(src)
    img = unwhite(img)
    img = crop_square(img)
    # 统计有效内容
    px = img.load()
    alpha_count = sum(1 for y in range(0, SIZE, 4) for x in range(0, SIZE, 4)
                      if px[x, y][3] > ALPHA_TH)
    total = (SIZE // 4) * (SIZE // 4)
    ratio = alpha_count / total
    img.save(dst, "PNG", optimize=True)
    print(f"{dst}: 内容占比 {ratio*100:.0f}%")


if __name__ == "__main__":
    process(sys.argv[1], sys.argv[2])
