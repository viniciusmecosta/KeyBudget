#!/usr/bin/env python3
"""Check exported brand geometry, density, alpha masks and Android safe zones.
Run with the same environment as generate.py.
"""
from io import BytesIO
from pathlib import Path
import math
import xml.etree.ElementTree as ET
import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/brand'
RES = ROOT / 'android/app/src/main/res'
ANDROID = '{http://schemas.android.com/apk/res/android}'


def svg(width, height, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{body}</svg>'


for path in ASSETS.glob('*.svg'):
    root = ET.parse(path).getroot()
    assert not root.findall('.//{http://www.w3.org/2000/svg}image'), path
    assert not root.findall('.//{http://www.w3.org/2000/svg}text'), path
for mode in ('light', 'dark', 'mono', 'inverse'):
    for folder, size in [('', 128), ('2.0x', 256), ('3.0x', 384), ('4.0x', 512)]:
        path = ASSETS / folder / f'passfin-symbol-{mode}.png'
        with Image.open(path) as im:
            assert im.size == (size, size), path
            alpha = im.convert('RGBA').getchannel('A')
            box = alpha.getbbox()
            assert box and min(box[:2]) > 0 and max(box[2:]) < size, path
for mode in ('light', 'dark'):
    for folder, size in [('', 250), ('2.0x', 500), ('3.0x', 750), ('4.0x', 1000)]:
        path = ASSETS / folder / f'passfin-signature-{mode}.png'
        with Image.open(path) as im:
            assert im.size == (size, int(size * 256 / 1000)), path
            box = im.convert('RGBA').getchannel('A').getbbox()
            assert box and box[0] > 0 and box[2] < size, path
for density, size in [('mdpi',24),('hdpi',36),('xhdpi',48),('xxhdpi',72),('xxxhdpi',96)]:
    with Image.open(RES / f'drawable-{density}/ic_stat_passfin.png') as im:
        assert im.size == (size, size)
        pixels = list(im.convert('RGBA').get_flattened_data())
        assert any(a == 0 for r,g,b,a in pixels)
        assert all((r,g,b) == (255,255,255) for r,g,b,a in pixels if a > 0)
# Parse the actual native resource, not a separate drawing of the icon.
vector = ET.parse(RES / 'drawable/passfin_foreground.xml').getroot()
group = vector.find('group')
paths = ''.join(f'<path fill="{p.attrib[ANDROID+"fillColor"]}" fill-rule="evenodd" d="{p.attrib[ANDROID+"pathData"]}"/>' for p in group.findall('path'))
transform = f'translate({group.attrib[ANDROID+"translateX"]} {group.attrib[ANDROID+"translateY"]}) scale({group.attrib[ANDROID+"scaleX"]} {group.attrib[ANDROID+"scaleY"]})'
foreground = f'<g transform="{transform}">{paths}</g>'
rgba = Image.open(BytesIO(cairosvg.svg2png(bytestring=svg(108,108,foreground).encode(),output_width=432))).convert('RGBA')
# Android's 66dp safe circle in the 108dp adaptive viewport.
for y in range(432):
    for x in range(432):
        if rgba.getpixel((x,y))[3] > 32:
            assert math.hypot((x+.5)/4-54, (y+.5)/4-54) <= 33, (x,y)

print('Verified: vector masters, 1x–4x PNGs, white/transparent notification masks, and Android safe circle.')
