#!/usr/bin/env python3
"""generate_placeholders.py — placeholder art generator for PixelGuess.

Generates 10 distinct 512x512 PNG images, one per level, written to
``assets/images/levels/level_01.png`` .. ``level_10.png`` (relative to the
project root, i.e. the parent of this script's ``tool/`` directory).

Per SPEC.md ("Placeholder art"), each image is a strong/saturated background
colour with a simple, bold geometric shape on top. The point is that when the
image is pixelated down to something like 5x5 or 10x10 (the runtime
pixelation mechanic downsamples with nearest-neighbor and no smoothing), the
shape's silhouette should still read as *something* rather than collapsing
into a single flat colour. That means: high contrast between background and
shape, the shape filling a large fraction of the frame, and no thin lines or
fine detail that would vanish at low resolution.

Dependencies
------------
This script works with **zero** third-party dependencies: pixel rasterising
is done in pure Python/stdlib, and PNG encoding falls back to a hand-rolled
minimal RGB8 PNG writer (stdlib ``zlib`` + ``struct``) if Pillow is not
installed.

If Pillow *is* installed (``pip install Pillow``), the script uses it purely
as the PNG encoder (``Image.frombytes`` + ``Image.save``) since it's a more
battle-tested encoder than the hand-rolled fallback — but the actual pixel
rasterising logic is identical either way, so output is the same regardless
of whether Pillow is present. This keeps a single source of truth for the
shapes instead of maintaining two parallel drawing implementations.

Usage
-----
    python tool/generate_placeholders.py
    python tool/generate_placeholders.py --out-dir some/other/dir   # for testing

Run standalone any time to regenerate all 10 images.
"""

from __future__ import annotations

import argparse
import math
import struct
import zlib
from pathlib import Path
from typing import Callable, Sequence

try:
    from PIL import Image

    HAS_PIL = True
except ImportError:
    HAS_PIL = False


IMAGE_SIZE = 512
CENTER = IMAGE_SIZE / 2.0

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "assets" / "images" / "levels"


# ---------------------------------------------------------------------------
# Shape test functions.
#
# Each factory returns a predicate `test(dx, dy) -> bool` where dx, dy are
# pixel coordinates relative to the image center. Keeping shapes as simple
# analytic (or polygon) point-membership tests means the same code rasterises
# correctly regardless of whether Pillow is available.
# ---------------------------------------------------------------------------


def circle(radius: float) -> Callable[[float, float], bool]:
    r2 = radius * radius
    return lambda dx, dy: dx * dx + dy * dy <= r2


def square(half: float) -> Callable[[float, float], bool]:
    return lambda dx, dy: abs(dx) <= half and abs(dy) <= half


def diamond(half: float) -> Callable[[float, float], bool]:
    """Rotated square (rhombus)."""
    return lambda dx, dy: abs(dx) + abs(dy) <= half


def cross(arm_half: float, thick_half: float) -> Callable[[float, float], bool]:
    """A bold plus/cross shape."""
    return lambda dx, dy: (abs(dx) <= arm_half and abs(dy) <= thick_half) or (
        abs(dy) <= arm_half and abs(dx) <= thick_half
    )


def triangle(half_base: float, height: float, point_up: bool = True) -> Callable[[float, float], bool]:
    """Isosceles triangle, apex pointing up or down, centered at origin."""
    half_h = height / 2.0

    def test(dx: float, dy: float) -> bool:
        y = dy if point_up else -dy
        # y ranges from -half_h (apex) to +half_h (base).
        if y < -half_h or y > half_h:
            return False
        width_at_y = half_base * (y + half_h) / height
        return abs(dx) <= width_at_y

    return test


def donut(outer_radius: float, inner_radius: float) -> Callable[[float, float], bool]:
    """A ring: inside the outer circle but outside the inner circle."""
    outer2 = outer_radius * outer_radius
    inner2 = inner_radius * inner_radius
    return lambda dx, dy: inner2 <= dx * dx + dy * dy <= outer2


def crescent(radius: float, cut_radius: float, offset: float) -> Callable[[float, float], bool]:
    """A moon-crescent: big circle minus an offset circle."""
    r2 = radius * radius
    c2 = cut_radius * cut_radius

    def test(dx: float, dy: float) -> bool:
        if dx * dx + dy * dy > r2:
            return False
        odx = dx - offset
        return odx * odx + dy * dy > c2

    return test


def _regular_polygon_points(num_sides: int, radius: float, rotation_deg: float) -> list[tuple[float, float]]:
    pts = []
    for i in range(num_sides):
        angle = math.radians(rotation_deg + i * (360.0 / num_sides))
        pts.append((radius * math.cos(angle), radius * math.sin(angle)))
    return pts


def _star_points(outer_radius: float, inner_radius: float, num_points: int, rotation_deg: float) -> list[tuple[float, float]]:
    pts = []
    step_deg = 360.0 / (num_points * 2)
    for i in range(num_points * 2):
        r = outer_radius if i % 2 == 0 else inner_radius
        angle = math.radians(rotation_deg + i * step_deg)
        pts.append((r * math.cos(angle), r * math.sin(angle)))
    return pts


def _point_in_polygon(x: float, y: float, poly: Sequence[tuple[float, float]]) -> bool:
    """Standard ray-casting point-in-polygon test."""
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y):
            x_intersect = (xj - xi) * (y - yi) / (yj - yi) + xi
            if x < x_intersect:
                inside = not inside
        j = i
    return inside


def polygon_shape(poly: Sequence[tuple[float, float]], bound_radius: float) -> Callable[[float, float], bool]:
    """Wraps a polygon point test with a cheap circular bounding-box pre-filter."""
    bound2 = bound_radius * bound_radius

    def test(dx: float, dy: float) -> bool:
        if dx * dx + dy * dy > bound2:
            return False
        return _point_in_polygon(dx, dy, poly)

    return test


def hexagon(radius: float) -> Callable[[float, float], bool]:
    return polygon_shape(_regular_polygon_points(6, radius, rotation_deg=-90), radius)


def star(outer_radius: float, inner_radius: float, num_points: int = 5) -> Callable[[float, float], bool]:
    return polygon_shape(
        _star_points(outer_radius, inner_radius, num_points, rotation_deg=-90),
        outer_radius,
    )


# ---------------------------------------------------------------------------
# Level definitions: 10 distinct (background colour, shape colour, shape).
# Colours are deliberately saturated/high-contrast; shapes are large and bold.
# ---------------------------------------------------------------------------

LEVELS = [
    {
        "id": 1,
        "description": "Red background, white circle",
        "bg": (230, 57, 70),
        "fg": (255, 255, 255),
        "shape": circle(190),
    },
    {
        "id": 2,
        "description": "Orange background, black square",
        "bg": (247, 127, 0),
        "fg": (20, 20, 20),
        "shape": square(170),
    },
    {
        "id": 3,
        "description": "Yellow background, indigo upward triangle",
        "bg": (255, 209, 102),
        "fg": (63, 0, 153),
        "shape": triangle(half_base=210, height=360, point_up=True),
    },
    {
        "id": 4,
        "description": "Green background, white 5-point star",
        "bg": (6, 150, 104),
        "fg": (255, 255, 255),
        "shape": star(outer_radius=200, inner_radius=88, num_points=5),
    },
    {
        "id": 5,
        "description": "Blue background, gold diamond",
        "bg": (17, 138, 178),
        "fg": (255, 209, 0),
        "shape": diamond(200),
    },
    {
        "id": 6,
        "description": "Purple background, white cross",
        "bg": (114, 9, 183),
        "fg": (255, 255, 255),
        "shape": cross(arm_half=210, thick_half=70),
    },
    {
        "id": 7,
        "description": "Pink/magenta background, black hexagon",
        "bg": (247, 37, 133),
        "fg": (20, 20, 20),
        "shape": hexagon(200),
    },
    {
        "id": 8,
        "description": "Dark teal background, orange ring/donut",
        "bg": (8, 76, 78),
        "fg": (255, 140, 0),
        "shape": donut(outer_radius=205, inner_radius=105),
    },
    {
        "id": 9,
        "description": "Maroon background, cyan crescent moon",
        "bg": (128, 0, 32),
        "fg": (0, 245, 212),
        "shape": crescent(radius=200, cut_radius=190, offset=95),
    },
    {
        "id": 10,
        "description": "Navy background, orange downward triangle",
        "bg": (3, 7, 30),
        "fg": (255, 140, 0),
        "shape": triangle(half_base=210, height=360, point_up=False),
    },
]

assert len(LEVELS) == 10


# ---------------------------------------------------------------------------
# Rasterising.
# ---------------------------------------------------------------------------


def rasterize(bg: tuple[int, int, int], fg: tuple[int, int, int], shape_test: Callable[[float, float], bool]) -> bytearray:
    """Returns a flat RGB8 pixel buffer (row-major, top-to-bottom) for a
    IMAGE_SIZE x IMAGE_SIZE image: `bg` everywhere, `fg` where `shape_test`
    is true for the pixel's center relative to the image center.
    """
    buf = bytearray(IMAGE_SIZE * IMAGE_SIZE * 3)
    bg_r, bg_g, bg_b = bg
    fg_r, fg_g, fg_b = fg
    idx = 0
    for py in range(IMAGE_SIZE):
        dy = (py + 0.5) - CENTER
        for px in range(IMAGE_SIZE):
            dx = (px + 0.5) - CENTER
            if shape_test(dx, dy):
                buf[idx] = fg_r
                buf[idx + 1] = fg_g
                buf[idx + 2] = fg_b
            else:
                buf[idx] = bg_r
                buf[idx + 1] = bg_g
                buf[idx + 2] = bg_b
            idx += 3
    return buf


# ---------------------------------------------------------------------------
# PNG writing.
# ---------------------------------------------------------------------------


def _png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png_stdlib(path: Path, width: int, height: int, rgb_buf: bytes) -> None:
    """Minimal pure-stdlib PNG encoder: 8-bit truecolor RGB, filter type 0
    (None) per scanline, zlib-compressed IDAT. No third-party dependencies.
    """
    stride = width * 3
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter type: None
        raw.extend(rgb_buf[y * stride : (y + 1) * stride])

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)  # color type 2 = truecolor
    idat = zlib.compress(bytes(raw), 9)

    with open(path, "wb") as f:
        f.write(signature)
        f.write(_png_chunk(b"IHDR", ihdr))
        f.write(_png_chunk(b"IDAT", idat))
        f.write(_png_chunk(b"IEND", b""))


def write_png(path: Path, width: int, height: int, rgb_buf: bytes) -> None:
    if HAS_PIL:
        img = Image.frombytes("RGB", (width, height), bytes(rgb_buf))
        img.save(path, "PNG")
    else:
        write_png_stdlib(path, width, height, rgb_buf)


# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------


def generate_all(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    backend = "Pillow" if HAS_PIL else "pure-stdlib PNG writer (Pillow not found)"
    print(f"Generating 10 placeholder images using {backend} -> {out_dir}")

    for level in LEVELS:
        buf = rasterize(level["bg"], level["fg"], level["shape"])
        filename = f"level_{level['id']:02d}.png"
        out_path = out_dir / filename
        write_png(out_path, IMAGE_SIZE, IMAGE_SIZE, buf)
        print(f"  {filename}: {level['description']}")

    print("Done.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Output directory (default: {DEFAULT_OUTPUT_DIR})",
    )
    args = parser.parse_args()
    generate_all(args.out_dir)


if __name__ == "__main__":
    main()
