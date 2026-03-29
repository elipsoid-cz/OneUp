#!/usr/bin/env python3
"""
Generates the OneUp app icon in all required macOS sizes.
The icon: macOS-style rounded-rect background in blue gradient,
white folder silhouette, white upward arrow overlaid.
"""

import math
import os
from PIL import Image, ImageDraw

SIZES = [16, 32, 64, 128, 256, 512, 1024]

OUTPUT_DIR = os.path.join(
    os.path.dirname(__file__),
    "../OneUp/Assets.xcassets/AppIcon.appiconset"
)


def rounded_rect_mask(size: int, radius_fraction: float = 0.225) -> Image.Image:
    """Creates an RGBA mask with a rounded rectangle (macOS app icon shape)."""
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    r = int(size * radius_fraction)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return img


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient_background(draw: ImageDraw.ImageDraw, size: int):
    """Vertical gradient: top = lighter blue, bottom = darker blue."""
    top_color = (72, 143, 255)      # #488FFF
    bottom_color = (20, 80, 210)    # #1450D2
    for y in range(size):
        t = y / (size - 1)
        color = lerp_color(top_color, bottom_color, t)
        draw.line([(0, y), (size - 1, y)], fill=color)


def draw_folder(draw: ImageDraw.ImageDraw, size: int):
    """Draws a simplified folder silhouette in semi-transparent white."""
    s = size
    pad = s * 0.18
    tab_w = s * 0.30
    tab_h = s * 0.08
    folder_top = s * 0.38
    folder_bottom = s * 0.76
    folder_left = pad
    folder_right = s - pad

    fill = (255, 255, 255, 140)  # semi-transparent white

    # Tab
    tab_points = [
        (folder_left, folder_top),
        (folder_left + tab_w, folder_top),
        (folder_left + tab_w + tab_h, folder_top - tab_h),
        (folder_left, folder_top - tab_h),
    ]
    draw.polygon(tab_points, fill=fill)

    # Body
    r = s * 0.04
    draw.rounded_rectangle(
        [folder_left, folder_top, folder_right, folder_bottom],
        radius=r, fill=fill
    )


def draw_arrow(draw: ImageDraw.ImageDraw, size: int):
    """Draws a bold upward arrow in white."""
    s = size
    cx = s * 0.5
    # Arrow shaft: vertical rectangle
    shaft_w = s * 0.095
    shaft_top = s * 0.36
    shaft_bottom = s * 0.62
    shaft_left = cx - shaft_w / 2
    shaft_right = cx + shaft_w / 2
    draw.rectangle([shaft_left, shaft_top, shaft_right, shaft_bottom], fill=(255, 255, 255))

    # Arrowhead: triangle pointing up
    head_half_w = s * 0.20
    head_top = s * 0.22
    head_bottom = s * 0.40
    draw.polygon(
        [
            (cx, head_top),
            (cx - head_half_w, head_bottom),
            (cx + head_half_w, head_bottom),
        ],
        fill=(255, 255, 255),
    )


def generate_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Draw gradient background on a flat RGB canvas, then composite
    bg = Image.new("RGB", (size, size))
    bg_draw = ImageDraw.Draw(bg)
    draw_gradient_background(bg_draw, size)

    # Apply rounded-rect mask to background
    mask = rounded_rect_mask(size)
    img.paste(bg, mask=mask)

    # Overlay layer for folder + arrow (RGBA for transparency)
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    draw_folder(ov_draw, size)
    draw_arrow(ov_draw, size)
    img = Image.alpha_composite(img, overlay)

    return img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Map from logical size to the filenames we need for the asset catalog.
    # macOS asset catalog uses @1x and @2x variants.
    # xcodegen expects actual PNG files referenced in Contents.json.
    # We generate: icon_<size>.png for each size.
    for size in SIZES:
        icon = generate_icon(size)
        filename = f"icon_{size}x{size}.png"
        out_path = os.path.join(OUTPUT_DIR, filename)
        icon.save(out_path, "PNG")
        print(f"  Generated {filename}")

    print(f"\nAll icons saved to:\n  {OUTPUT_DIR}")
    print("\nNext: update Contents.json to reference the generated files.")


if __name__ == "__main__":
    main()
