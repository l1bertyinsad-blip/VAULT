from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "app/src/main/res/drawable-nodpi/savio_icon_background_v2.png"
PLAY_OUTPUT = ROOT / "play/graphics/SAVIO-Android-AppIcon-1024.png"
LAUNCHER_PREVIEW = ROOT / "play/graphics/SAVIO-Android-LauncherPreview-1024.png"


def create_mask(circle, body, notch, radius):
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse(circle, fill=255)
    draw.rounded_rectangle(body, radius=radius, fill=255)
    draw.polygon(notch, fill=0)
    return mask


def compose(mask, with_shadow):
    background = Image.open(BACKGROUND).convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)
    if with_shadow:
        shadow_mask = mask.filter(ImageFilter.GaussianBlur(16))
        shadow_layer = Image.new("RGBA", background.size, (5, 20, 80, 0))
        shadow_layer.putalpha(shadow_mask.point(lambda value: int(value * 0.18)))
        background.alpha_composite(shadow_layer, (0, 12))
    mark = Image.new("RGBA", background.size, (255, 255, 255, 0))
    mark.putalpha(mask)
    background.alpha_composite(mark)
    return background.convert("RGB")


play_mask = create_mask(
    circle=(396, 72, 628, 304),
    body=(270, 360, 754, 844),
    notch=((270, 844), (512, 682), (754, 844)),
    radius=72,
)

safe_launcher_mask = create_mask(
    circle=(418, 199, 606, 387),
    body=(316, 433, 708, 825),
    notch=((316, 825), (512, 694), (708, 825)),
    radius=58,
)

PLAY_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
compose(play_mask, with_shadow=True).save(PLAY_OUTPUT, quality=96, optimize=True)
compose(safe_launcher_mask, with_shadow=False).save(LAUNCHER_PREVIEW, quality=96, optimize=True)
print(PLAY_OUTPUT)
print(LAUNCHER_PREVIEW)
