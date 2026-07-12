#!/usr/bin/env python3
"""Turn raw iPhone screenshots into 6.9-inch App Store marketing cards."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


WIDTH = 1320
HEIGHT = 2868

CARDS = [
    ("01-home", "Превратите скроллинг в пользу", "Листайте свои идеи вместо чужой ленты"),
    ("02-import", "Сохраняйте откуда угодно", "Фото, видео, сайты и Reels — через одну кнопку"),
    ("03-folders", "Порядок без лишней рутины", "Умные папки помогают быстро находить нужное"),
    ("04-favorites", "Возвращайтесь к тому, что важно", "VAULT поднимает сохранённое, пока оно не забылось"),
    ("05-profile", "Лично. Локально. Под защитой.", "Ваши материалы остаются на вашем iPhone"),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def centered_text(draw: ImageDraw.ImageDraw, text: str, y: int, text_font, fill) -> None:
    box = draw.textbbox((0, 0), text, font=text_font)
    x = (WIDTH - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=text_font, fill=fill)


def background() -> Image.Image:
    vertical = Image.linear_gradient("L").resize((WIDTH, HEIGHT))
    top = Image.new("RGB", (WIDTH, HEIGHT), "#f8f9ff")
    bottom = Image.new("RGB", (WIDTH, HEIGHT), "#dfe5ff")
    canvas = Image.composite(bottom, top, vertical).convert("RGBA")

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((-280, 500, 720, 1500), fill=(104, 82, 255, 72))
    glow_draw.ellipse((760, -240, 1540, 620), fill=(72, 151, 255, 55))
    glow_draw.ellipse((720, 1920, 1650, 3000), fill=(231, 86, 174, 38))
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    return Image.alpha_composite(canvas, glow)


def rounded_screenshot(source: Image.Image) -> Image.Image:
    max_width = 1090
    max_height = 2260
    ratio = min(max_width / source.width, max_height / source.height)
    size = (round(source.width * ratio), round(source.height * ratio))
    screenshot = source.convert("RGB").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=72, fill=255)
    screenshot.putalpha(mask)
    return screenshot


def collect_named_sources(input_dir: Path) -> dict[str, Path]:
    pngs = sorted(input_dir.rglob("*.png"))
    named: dict[str, Path] = {}

    for path in pngs:
        lowered = path.name.lower()
        for key, _, _ in CARDS:
            if key in lowered:
                named[key] = path

    for metadata_path in input_dir.rglob("*.json"):
        try:
            payload = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue

        def walk(value):
            if isinstance(value, dict):
                human_name = str(value.get("suggestedHumanReadableName", "")).lower()
                exported = value.get("exportedFileName")
                if exported:
                    exported_path = metadata_path.parent / str(exported)
                    for key, _, _ in CARDS:
                        if key in human_name and exported_path.exists():
                            named[key] = exported_path
                for child in value.values():
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)

        walk(payload)

    unused = [path for path in pngs if path not in named.values()]
    for key, _, _ in CARDS:
        if key not in named and unused:
            named[key] = unused.pop(0)
    return named


def render_card(source_path: Path, destination: Path, title: str, subtitle: str) -> None:
    canvas = background()
    draw = ImageDraw.Draw(canvas)

    pill = (WIDTH // 2 - 105, 58, WIDTH // 2 + 105, 118)
    draw.rounded_rectangle(pill, radius=30, fill=(255, 255, 255, 185))
    centered_text(draw, "VAULT", 70, font(28, bold=True), "#4f36d8")
    centered_text(draw, title, 145, font(62, bold=True), "#17172a")
    centered_text(draw, subtitle, 245, font(34), "#656579")

    screenshot = rounded_screenshot(Image.open(source_path))
    x = (WIDTH - screenshot.width) // 2
    y = 430

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_shape = Image.new("RGBA", screenshot.size, (30, 24, 70, 120))
    shadow_mask = screenshot.getchannel("A").filter(ImageFilter.GaussianBlur(36))
    shadow_shape.putalpha(shadow_mask)
    shadow.alpha_composite(shadow_shape, (x, y + 28))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(screenshot, (x, y))

    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(destination, "PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    sources = collect_named_sources(args.input)
    missing = [key for key, _, _ in CARDS if key not in sources]
    if missing:
        raise SystemExit(f"Missing screenshot attachments: {', '.join(missing)}")

    for key, title, subtitle in CARDS:
        render_card(sources[key], args.output / f"{key}.png", title, subtitle)
        print(f"Created {args.output / f'{key}.png'}")


if __name__ == "__main__":
    main()
