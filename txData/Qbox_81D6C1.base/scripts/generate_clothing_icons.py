"""Generate clothing item PNG icons for ox_inventory (Pillow, transparent)."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "resources" / "[ox]" / "ox_inventory" / "web" / "images"
SIZE = 256


def new_canvas():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # soft ground shadow
    draw.ellipse([58, 220, 198, 244], fill=(0, 0, 0, 55))
    return img, draw


def shade(base, factor):
    return tuple(max(0, min(255, int(c * factor))) for c in base[:3]) + (base[3] if len(base) == 4 else 255,)


VIOLET = (124, 58, 237, 255)
VIOLET_L = (167, 139, 250, 255)
VIOLET_D = (91, 33, 182, 255)
TEAL = (13, 148, 136, 255)
TEAL_L = (94, 234, 212, 255)
GOLD = (217, 119, 6, 255)
GOLD_L = (253, 230, 138, 255)
METAL = (196, 201, 212, 255)
METAL_D = (107, 114, 128, 255)
LEATHER = (68, 64, 60, 255)
LEATHER_L = (120, 113, 108, 255)


def draw_shirt(draw):
    body = [(72, 96), (96, 72), (112, 88), (128, 80), (144, 88), (160, 72), (184, 96), (184, 210), (128, 224), (72, 210)]
    draw.polygon(body, fill=VIOLET)
    collar = [(96, 72), (112, 88), (128, 80), (144, 88), (160, 72), (152, 96), (128, 104), (104, 96)]
    draw.polygon(collar, fill=VIOLET_L)
    draw.ellipse([122, 132, 134, 144], fill=VIOLET_L)


def draw_torso(draw):
    body = [(68, 98), (92, 68), (108, 84), (128, 76), (148, 84), (164, 68), (188, 98), (188, 218), (128, 232), (68, 218)]
    draw.polygon(body, fill=VIOLET)
    lapel_l = [(92, 68), (108, 84), (116, 108), (92, 118)]
    lapel_r = [(164, 68), (148, 84), (140, 108), (164, 118)]
    draw.polygon(lapel_l, fill=VIOLET_D)
    draw.polygon(lapel_r, fill=VIOLET_D)
    draw.rectangle([118, 130, 138, 158], fill=VIOLET_L, outline=VIOLET_D)


def draw_pants(draw):
    pants = [(78, 72), (178, 72), (188, 120), (168, 224), (138, 224), (128, 140), (118, 224), (88, 224), (68, 120)]
    draw.polygon(pants, fill=VIOLET)
    draw.rectangle([98, 88, 158, 96], fill=VIOLET_L)


def draw_shoes(draw):
    draw.rounded_rectangle([52, 132, 204, 216], radius=28, fill=VIOLET)
    draw.ellipse([76, 114, 180, 150], fill=VIOLET_L)
    draw.rectangle([52, 168, 204, 180], fill=TEAL_L)
    draw.ellipse([90, 172, 102, 184], fill=(255, 255, 255, 90))
    draw.ellipse([154, 172, 166, 184], fill=(255, 255, 255, 90))


def draw_mask(draw):
    draw.ellipse([64, 100, 192, 180], fill=TEAL)
    draw.arc([88, 118, 168, 148], 10, 170, fill=TEAL_L, width=4)
    draw.ellipse([86, 128, 106, 148], fill=(15, 118, 110, 180))
    draw.ellipse([150, 128, 170, 148], fill=(15, 118, 110, 180))
    draw.line([(64, 108), (52, 92)], fill=METAL, width=6)
    draw.line([(192, 108), (204, 92)], fill=METAL, width=6)


def draw_hat(draw):
    draw.ellipse([40, 150, 216, 186], fill=VIOLET)
    draw.ellipse([88, 72, 168, 168], fill=VIOLET_L)
    draw.rectangle([108, 96, 148, 104], fill=VIOLET_D)


def draw_glasses(draw):
    draw.rounded_rectangle([48, 108, 116, 156], radius=12, outline=METAL, width=8)
    draw.rounded_rectangle([140, 108, 208, 156], radius=12, outline=METAL, width=8)
    draw.rounded_rectangle([56, 116, 108, 148], radius=8, fill=(13, 148, 136, 90))
    draw.rounded_rectangle([148, 116, 200, 148], radius=8, fill=(13, 148, 136, 90))
    draw.line([(116, 132), (140, 132)], fill=METAL, width=8)
    draw.line([(48, 132), (34, 122)], fill=METAL, width=7)
    draw.line([(208, 132), (222, 122)], fill=METAL, width=7)


def draw_ear(draw):
    draw.arc([72, 56, 184, 200], 200, 340, fill=METAL, width=10)
    draw.ellipse([106, 106, 150, 150], fill=GOLD)
    draw.ellipse([116, 116, 140, 140], fill=GOLD_L)
    draw.ellipse([150, 110, 186, 146], fill=TEAL)
    draw.ellipse([160, 120, 176, 136], fill=TEAL_L)


def draw_bag(draw):
    draw.rounded_rectangle([68, 88, 188, 220], radius=18, fill=VIOLET)
    draw.arc([96, 32, 160, 96], 200, 340, fill=METAL, width=10)
    draw.rounded_rectangle([92, 128, 164, 176], radius=10, fill=VIOLET_D)
    draw.rounded_rectangle([110, 142, 146, 166], radius=6, fill=TEAL_L)


def draw_vest(draw):
    body = [(76, 88), (100, 68), (128, 80), (156, 68), (180, 88), (180, 216), (128, 228), (76, 216)]
    draw.polygon(body, fill=LEATHER)
    for box in [(92, 108, 128, 148), (128, 108, 164, 148), (110, 158, 146, 198)]:
        draw.rounded_rectangle(box, radius=4, fill=(41, 37, 36, 255), outline=LEATHER_L, width=2)
    draw.ellipse([120, 112, 136, 128], fill=TEAL_L)


def draw_accessory(draw):
    tie = [(128, 48), (148, 88), (168, 168), (128, 208), (88, 168), (108, 88)]
    draw.polygon(tie, fill=VIOLET)
    knot = [(100, 80), (156, 80), (148, 100), (128, 108), (108, 100)]
    draw.polygon(knot, fill=TEAL)


def draw_decals(draw):
    draw.ellipse([56, 56, 200, 200], fill=VIOLET, outline=GOLD, width=8)
    star = [(128, 88), (140, 116), (168, 116), (146, 134), (154, 162), (128, 146), (102, 162), (110, 134), (88, 116), (116, 116)]
    draw.polygon(star, fill=GOLD_L)


def draw_watch(draw):
    draw.rounded_rectangle([108, 48, 148, 72], radius=6, fill=METAL)
    draw.rounded_rectangle([108, 184, 148, 208], radius=6, fill=METAL)
    draw.ellipse([72, 72, 184, 184], fill=METAL, outline=METAL_D, width=3)
    draw.ellipse([84, 84, 172, 172], fill=(31, 41, 55, 255))
    draw.ellipse([92, 92, 164, 164], outline=TEAL_L, width=4)
    draw.line([(128, 128), (128, 104)], fill=(249, 250, 251, 255), width=4)
    draw.line([(128, 128), (150, 128)], fill=TEAL_L, width=3)
    draw.ellipse([124, 124, 132, 132], fill=TEAL_L)


def draw_bracelet(draw):
    draw.arc([56, 72, 200, 200], 200, 340, fill=GOLD, width=16)
    draw.ellipse([114, 146, 142, 174], fill=TEAL)
    draw.ellipse([122, 154, 134, 166], fill=TEAL_L)
    draw.ellipse([80, 112, 96, 128], fill=GOLD_L)
    draw.ellipse([160, 112, 176, 128], fill=GOLD_L)


ICONS = {
    "clothing_shirt": draw_shirt,
    "clothing_torso": draw_torso,
    "clothing_pants": draw_pants,
    "clothing_shoes": draw_shoes,
    "clothing_mask": draw_mask,
    "clothing_hat": draw_hat,
    "clothing_glasses": draw_glasses,
    "clothing_ear": draw_ear,
    "clothing_bag": draw_bag,
    "clothing_vest": draw_vest,
    "clothing_accessory": draw_accessory,
    "clothing_decals": draw_decals,
    "clothing_watch": draw_watch,
    "clothing_bracelet": draw_bracelet,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, painter in ICONS.items():
        img, draw = new_canvas()
        painter(draw)
        path = OUT / f"{name}.png"
        img.save(path, "PNG")
        print(f"OK {name}.png ({path.stat().st_size} bytes)")
    print("Done.")


if __name__ == "__main__":
    main()
