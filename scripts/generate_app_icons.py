#!/usr/bin/env python3
"""Generate launch and app icons for the Flutter app."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
BRANDING = APP / "assets" / "branding"

ICON_BG = (28, 131, 127, 255)
ICON_BG_DARK = (18, 90, 95, 255)
CARD = (250, 253, 250, 255)
CARD_SHADOW = (0, 49, 52, 70)
YELLOW = (244, 191, 75, 255)
CORAL = (231, 92, 86, 255)
INK = (37, 55, 64, 255)
SPLASH_BG = (246, 248, 247, 255)


def draw_base_icon(size: int = 1024) -> Image.Image:
    scale = 4
    canvas_size = size * scale
    image = Image.new("RGBA", (canvas_size, canvas_size), ICON_BG)
    draw = ImageDraw.Draw(image)

    for y in range(canvas_size):
        ratio = y / canvas_size
        color = tuple(
            int(ICON_BG[i] * (1 - ratio) + ICON_BG_DARK[i] * ratio)
            for i in range(3)
        ) + (255,)
        draw.line([(0, y), (canvas_size, y)], fill=color)

    margin = int(canvas_size * 0.13)
    radius = int(canvas_size * 0.18)
    draw.rounded_rectangle(
        [margin, margin, canvas_size - margin, canvas_size - margin],
        radius=radius,
        outline=(255, 255, 255, 56),
        width=int(canvas_size * 0.018),
    )

    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    left_card = [
        int(canvas_size * 0.21),
        int(canvas_size * 0.28),
        int(canvas_size * 0.59),
        int(canvas_size * 0.72),
    ]
    right_card = [
        int(canvas_size * 0.43),
        int(canvas_size * 0.25),
        int(canvas_size * 0.79),
        int(canvas_size * 0.69),
    ]
    for box in (left_card, right_card):
        offset = int(canvas_size * 0.026)
        shadow_draw.rounded_rectangle(
            [box[0] + offset, box[1] + offset, box[2] + offset, box[3] + offset],
            radius=int(canvas_size * 0.05),
            fill=CARD_SHADOW,
        )
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(canvas_size * 0.018))))

    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(left_card, radius=int(canvas_size * 0.05), fill=CARD)
    draw.rounded_rectangle(right_card, radius=int(canvas_size * 0.05), fill=(255, 255, 255, 255))

    line_w = int(canvas_size * 0.025)
    draw.line(
        [
            (int(canvas_size * 0.30), int(canvas_size * 0.40)),
            (int(canvas_size * 0.50), int(canvas_size * 0.40)),
            (int(canvas_size * 0.50), int(canvas_size * 0.50)),
            (int(canvas_size * 0.34), int(canvas_size * 0.50)),
        ],
        fill=INK,
        width=line_w,
        joint="curve",
    )
    draw.line(
        [
            (int(canvas_size * 0.30), int(canvas_size * 0.59)),
            (int(canvas_size * 0.51), int(canvas_size * 0.59)),
        ],
        fill=CORAL,
        width=line_w,
    )
    draw.arc(
        [
            int(canvas_size * 0.53),
            int(canvas_size * 0.36),
            int(canvas_size * 0.71),
            int(canvas_size * 0.56),
        ],
        start=25,
        end=325,
        fill=INK,
        width=line_w,
    )
    draw.line(
        [
            (int(canvas_size * 0.63), int(canvas_size * 0.56)),
            (int(canvas_size * 0.63), int(canvas_size * 0.63)),
            (int(canvas_size * 0.72), int(canvas_size * 0.63)),
        ],
        fill=INK,
        width=line_w,
    )
    draw.ellipse(
        [
            int(canvas_size * 0.68),
            int(canvas_size * 0.35),
            int(canvas_size * 0.76),
            int(canvas_size * 0.43),
        ],
        fill=YELLOW,
    )

    return image.resize((size, size), Image.Resampling.LANCZOS)


def resize_square(source: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    source.resize((size, size), Image.Resampling.LANCZOS).save(path)


def make_launch_image(source: Image.Image, path: Path, size: int) -> None:
    canvas = Image.new("RGBA", (size, size), SPLASH_BG)
    icon_size = int(size * 0.62)
    icon = source.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    offset = ((size - icon_size) // 2, (size - icon_size) // 2)
    canvas.alpha_composite(icon, offset)
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(path)


def make_adaptive_foreground(source: Image.Image, path: Path, size: int = 432) -> None:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_size = int(size * 0.72)
    icon = source.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    offset = ((size - icon_size) // 2, (size - icon_size) // 2)
    canvas.alpha_composite(icon, offset)
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(path)


def main() -> int:
    base = draw_base_icon()
    BRANDING.mkdir(parents=True, exist_ok=True)
    base.save(BRANDING / "app_icon_1024.png")

    android_sizes = {
        "mipmap-mdpi/ic_launcher.png": 48,
        "mipmap-hdpi/ic_launcher.png": 72,
        "mipmap-xhdpi/ic_launcher.png": 96,
        "mipmap-xxhdpi/ic_launcher.png": 144,
        "mipmap-xxxhdpi/ic_launcher.png": 192,
    }
    for relative, size in android_sizes.items():
        resize_square(base, APP / "android/app/src/main/res" / relative, size)
    make_adaptive_foreground(
        base,
        APP / "android/app/src/main/res/drawable/ic_launcher_foreground.png",
    )

    ios_icon_dir = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        resize_square(base, ios_icon_dir / filename, size)

    mac_icon_dir = APP / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        resize_square(base, mac_icon_dir / f"app_icon_{size}.png", size)

    web_icon_dir = APP / "web/icons"
    resize_square(base, APP / "web/favicon.png", 32)
    resize_square(base, web_icon_dir / "Icon-192.png", 192)
    resize_square(base, web_icon_dir / "Icon-512.png", 512)
    resize_square(base, web_icon_dir / "Icon-maskable-192.png", 192)
    resize_square(base, web_icon_dir / "Icon-maskable-512.png", 512)

    windows_icon = APP / "windows/runner/resources/app_icon.ico"
    windows_icon.parent.mkdir(parents=True, exist_ok=True)
    base.save(windows_icon, sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])

    launch_dir = APP / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    make_launch_image(base, launch_dir / "LaunchImage.png", 168)
    make_launch_image(base, launch_dir / "LaunchImage@2x.png", 336)
    make_launch_image(base, launch_dir / "LaunchImage@3x.png", 504)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
