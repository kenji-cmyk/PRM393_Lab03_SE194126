"""Render the VetaLife VL mark for Android and web (requires Pillow)."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
BACKGROUND = "#E1F1E6"
FOREGROUND = "#183D2D"


def render(size: int, *, maskable: bool = False) -> Image.Image:
    image = Image.new("RGB", (SIZE, SIZE), BACKGROUND)
    draw = ImageDraw.Draw(image)
    # Keep all lettering inside the central safe zone for maskable icons.
    font = ImageFont.truetype(
        str(ROOT / "assets/fonts/Roboto-Bold.ttf"), 420 if maskable else 500
    )
    bounds = draw.textbbox((0, 0), "VL", font=font)
    x = (SIZE - (bounds[2] - bounds[0])) / 2 - bounds[0]
    y = (SIZE - (bounds[3] - bounds[1])) / 2 - bounds[1]
    draw.text((x, y), "VL", font=font, fill=FOREGROUND)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in densities.items():
        render(size).save(
            ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        )
    render(32).save(ROOT / "web/favicon.png")
    for size in (192, 512):
        render(size).save(ROOT / f"web/icons/Icon-{size}.png")
        render(size, maskable=True).save(ROOT / f"web/icons/Icon-maskable-{size}.png")


if __name__ == "__main__":
    main()
