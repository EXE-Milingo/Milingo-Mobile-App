from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CANVAS_SIZE = (1080, 1920)
SCREENSHOT_PATH = ROOT / "store-assets" / "sources" / "home-screen.png"
SCREENSHOT_CROP_BOTTOM = 830
MASCOT_PATH = ROOT / "assets" / "images" / "limabo_home.png"
LOGO_PATH = ROOT / "store-assets" / "milingo-logo-512.png"
OUTPUT_PATH = ROOT / "store-assets" / "previews" / "home-preview-v2.png"
FONT_PATH = Path(r"C:\Windows\Fonts\arialbd.ttf")

BACKGROUND = (255, 248, 242, 255)
CHARCOAL = (42, 40, 38, 255)
MILINGO_ORANGE = (255, 102, 0, 255)


def require_sources() -> None:
    for path in (SCREENSHOT_PATH, MASCOT_PATH, LOGO_PATH, FONT_PATH):
        if not path.exists():
            raise FileNotFoundError(f"Required source file does not exist: {path}")


def prepare_logo(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    mask = Image.new("L", rgb.size)
    mask.putdata(
        [255 if min(pixel) < 245 else 0 for pixel in rgb.getdata()]
    )
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError(f"Logo has no visible non-white pixels: {LOGO_PATH}")
    logo = rgb.convert("RGBA")
    logo.putalpha(mask)
    return logo.crop(bounds)


def contain(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    result = image.copy()
    result.thumbnail(max_size, Image.Resampling.LANCZOS)
    return result


def main() -> None:
    require_sources()

    canvas = Image.new("RGBA", CANVAS_SIZE, BACKGROUND)
    draw = ImageDraw.Draw(canvas)
    headline_font = ImageFont.truetype(str(FONT_PATH), 92)

    logo = contain(prepare_logo(Image.open(LOGO_PATH)), (160, 120))
    canvas.alpha_composite(logo, (68, 34))

    draw.text((68, 158), "Học mỗi ngày", font=headline_font, fill=CHARCOAL)
    draw.text((68, 267), "cùng Limabo", font=headline_font, fill=MILINGO_ORANGE)

    mascot = contain(Image.open(MASCOT_PATH).convert("RGBA"), (255, 255))
    canvas.alpha_composite(mascot, (775, 158))

    screen_top = 520
    screenshot = Image.open(SCREENSHOT_PATH).convert("RGBA")
    screenshot = screenshot.crop(
        (0, 0, screenshot.width, SCREENSHOT_CROP_BOTTOM)
    )
    screen_height = CANVAS_SIZE[1] - screen_top
    screen_width = round(screen_height * screenshot.width / screenshot.height)
    screenshot = screenshot.resize(
        (screen_width, screen_height),
        Image.Resampling.LANCZOS,
    )
    screen_left = (CANVAS_SIZE[0] - screen_width) // 2

    shadow = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            screen_left - 8,
            screen_top + 10,
            screen_left + screen_width + 8,
            CANVAS_SIZE[1] + 40,
        ),
        radius=42,
        fill=(61, 42, 31, 48),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(20)))
    canvas.alpha_composite(screenshot, (screen_left, screen_top))

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUTPUT_PATH, "PNG", optimize=True)
    print(f"Created {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
