#!/usr/bin/env python3
"""Compose the social preview image from the hero photograph.

The layout follows the landing page: a red panel carrying the headline, and the
photograph pinned beside it as a taped print.

    python3 tools/build-og-image.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
PHOTO = ROOT / "public/assets/images/home-server.jpg"
TARGET = ROOT / "public/assets/images/og-image.jpg"

W, H = 1200, 630
PANEL = 548
INK = "#17120E"
PAPER = "#E7DAC2"
RED = "#FF5437"
WHITE = "#FBF6EA"

DISPLAY = "/System/Library/Fonts/Helvetica.ttc"
MONO = "/System/Library/Fonts/Menlo.ttc"


def font(path, size, index=0):
    return ImageFont.truetype(path, size, index=index)


def tracked(draw, xy, text, fnt, fill, spacing=0.0):
    """Draw text with extra letter spacing, which Pillow does not support."""
    x, y = xy
    for char in text:
        draw.text((x, y), char, font=fnt, fill=fill)
        x += draw.textlength(char, font=fnt) + spacing
    return x


def photo_card():
    photo = Image.open(PHOTO).convert("RGB")
    inner_w, inner_h = 520, 390
    scale = max(inner_w / photo.width, inner_h / photo.height)
    resized = photo.resize((round(photo.width * scale), round(photo.height * scale)), Image.LANCZOS)
    left = (resized.width - inner_w) // 2
    top = (resized.height - inner_h) // 2
    inner = resized.crop((left, top, left + inner_w, top + inner_h))

    border, footer = 16, 54
    card = Image.new("RGB", (inner_w + border * 2, inner_h + border + footer), WHITE)
    card.paste(inner, (border, border))

    draw = ImageDraw.Draw(card)
    tracked(draw, (border + 2, inner_h + border + 16), "INBOOK X1 / ACTIVE NODE",
            font(MONO, 15), INK, spacing=1.4)
    return card


def main():
    canvas = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, PANEL, H), fill=RED)

    tracked(draw, (56, 84), "HOME-SERVER EXPERIMENT", font(MONO, 16), INK, spacing=2.4)
    bold = font(DISPLAY, 82, index=1)
    draw.text((52, 214), "Old laptop.", font=bold, fill=INK)
    draw.text((52, 300), "New job.", font=bold, fill=INK)
    draw.text((56, 424), "A repurposed laptop, running real services.",
              font=font(DISPLAY, 24), fill=INK)
    tracked(draw, (56, 508), "SYSTEMS.IKHWANULHAKIM.COM", font(MONO, 16), INK, spacing=2.0)

    card = photo_card().rotate(-2.6, resample=Image.BICUBIC, expand=True, fillcolor=PAPER)
    pos = (PANEL + (W - PANEL - card.width) // 2, (H - card.height) // 2)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rectangle(
        (pos[0] + 16, pos[1] + 18, pos[0] + card.width + 12, pos[1] + card.height + 14),
        fill=(51, 35, 20, 90))
    canvas = Image.alpha_composite(canvas.convert("RGBA"),
                                   shadow.filter(ImageFilter.GaussianBlur(9))).convert("RGB")
    canvas.paste(card, pos)

    # Tape holding the print, angled the other way so it reads as placed by hand.
    tape = Image.new("RGBA", (150, 46), (245, 216, 79, 214))
    tape = tape.rotate(-9, resample=Image.BICUBIC, expand=True)
    canvas.paste(tape, (pos[0] + 190, pos[1] - 18), tape)

    canvas.save(TARGET, "JPEG", quality=88, optimize=True, progressive=True)
    print(f"wrote {TARGET.relative_to(ROOT)} {canvas.size}")


if __name__ == "__main__":
    main()
