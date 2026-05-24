from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
IMAGE_DIR = ROOT / "assets" / "images"
WIDTHS = (640, 1024, 1536)
QUALITY = 78


def main() -> None:
    generated = 0
    for source in sorted(IMAGE_DIR.glob("*.png")):
        if source.stem.endswith(tuple(f"-{width}" for width in WIDTHS)):
            continue

        with Image.open(source) as image:
            image = image.convert("RGB")
            for width in WIDTHS:
                target = source.with_name(f"{source.stem}-{width}.webp")
                if image.width <= width:
                    resized = image.copy()
                else:
                    height = round(image.height * (width / image.width))
                    resized = image.resize((width, height), Image.Resampling.LANCZOS)

                resized.save(target, "WEBP", quality=QUALITY, method=6)
                generated += 1

    print(f"Generated {generated} optimized WebP images.")


if __name__ == "__main__":
    main()
