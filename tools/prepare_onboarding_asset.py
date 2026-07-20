from argparse import ArgumentParser
from pathlib import Path

from PIL import Image, ImageOps


parser = ArgumentParser(description="Prepare a generated onboarding image for Android.")
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()

with Image.open(args.source) as source:
    prepared = ImageOps.fit(
        source.convert("RGB"),
        (1400, 800),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    prepared.save(args.output, format="JPEG", quality=86, optimize=True, progressive=True)

print(args.output)
