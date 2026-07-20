from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "app/src/main/res/drawable-nodpi/savio_icon_background.png"
OUTPUT = ROOT / "play/graphics/SAVIO-Android-AppIcon-1024.png"

background = Image.open(BACKGROUND).convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)

mask = Image.new("L", background.size, 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((414, 132, 610, 328), fill=255)
draw.rounded_rectangle((270, 358, 754, 842), radius=74, fill=255)
draw.polygon(((270, 842), (512, 650), (754, 842)), fill=0)

shadow = Image.new("RGBA", background.size, (0, 0, 0, 0))
shadow_mask = mask.filter(ImageFilter.GaussianBlur(16))
shadow.putalpha(shadow_mask.point(lambda value: int(value * 0.18)))
shadow_layer = Image.new("RGBA", background.size, (5, 20, 80, 255))
shadow_layer.putalpha(shadow.getchannel("A"))
background.alpha_composite(shadow_layer, (0, 12))

mark = Image.new("RGBA", background.size, (255, 255, 255, 0))
mark.putalpha(mask)
background.alpha_composite(mark)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
background.convert("RGB").save(OUTPUT, quality=96, optimize=True)
print(OUTPUT)
