#!/usr/bin/env python3
"""Build PassFin SVG masters, PNG exports and Android resources deterministically.

Run from any directory with the dependencies in requirements.txt installed.
The old assets/icon logos are intentionally preserved.
"""
from pathlib import Path
import json
import cairosvg
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/brand'
RES = ROOT / 'android/app/src/main/res'
BLUE, PALE, INK = '#0058D9', '#82B7FF', '#102B50'
# Canonical 512-unit drawing. Shared paths feed SVG and Android VectorDrawable.
# The white key is a true cutout (even-odd fill), including its circular hole.
BACK = 'M60 196 Q60 163 94 158 L418 158 Q452 158 452 193 L452 220 L60 220 Z'
NOTE = 'M112 116 Q110 105 122 102 L383 51 Q397 48 400 63 L424 181 L132 217 Z'
PAPER = 'M143 122 L367 78 Q371 98 387 99 L400 161 L154 199 Z'
MEDALLION = 'M252 149 A26 32 0 1 0 304 149 A26 32 0 1 0 252 149 Z'
BODY = ('M58 188 Q167 220 301 192 Q383 176 421 177 Q458 177 458 216 '
        'L458 388 Q458 430 416 430 L96 430 Q54 430 54 388 L54 221 Q54 201 58 188 Z')
KEY = ('M230 285 A66 66 0 1 0 230 329 L330 329 L330 360 '
       'L366 360 L366 329 L402 329 L402 285 Z '
       'M192 307 A25 25 0 1 0 142 307 A25 25 0 1 0 192 307 Z')
font = TTFont(ROOT / 'assets/fonts/Inter-Bold.ttf')
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
units = font['head'].unitsPerEm


def parts(mode='light'):
    main = '#FFFFFF' if mode == 'inverse' else (INK if mode == 'mono' else BLUE)
    note = main if mode in ('mono', 'inverse') else PALE
    paper = main if mode in ('mono', 'inverse') else '#EAF4FF'
    # Mono banknote outline and medallion use actual transparent negative space.
    if mode in ('mono', 'inverse'):
        return [(main, BACK), (note, NOTE + ' ' + PAPER), (note, MEDALLION),
                (main, BODY + ' ' + KEY)]
    return [(INK if mode == 'light' else BLUE, BACK), (note, NOTE),
            (paper, PAPER), (note, MEDALLION), (main, BODY + ' ' + KEY),
            ('#FFFFFF', KEY)]


def drawing(mode='light'):
    return ''.join(f'<path fill="{fill}" fill-rule="evenodd" d="{d}"/>' for fill, d in parts(mode))


def letters(text, x, baseline, size, fill):
    scale = size / units
    result = []
    for char in text:
        name = cmap[ord(char)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        result.append(f'<path fill="{fill}" transform="translate({x:.4f} {baseline}) scale({scale:.6f} {-scale:.6f})" d="{pen.getCommands()}"/>')
        x += (font['hmtx'][name][0] - units * .025) * scale
    return ''.join(result), x


def wordmark(x, baseline, size, dark=False):
    a, x = letters('Pass', x, baseline, size, '#F5F7FA' if dark else INK)
    b, _ = letters('Fin', x, baseline, size, PALE if dark else BLUE)
    return a + b


def svg(w, h, content):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-label="PassFin"><title>PassFin</title>{content}</svg>\n'


def save(name, w, h, content, png_width=None):
    path = OUT / f'{name}.svg'
    path.parent.mkdir(parents=True, exist_ok=True)
    source = svg(w, h, content)
    path.write_text(source)
    if png_width:
        cairosvg.svg2png(bytestring=source.encode(), write_to=str(path.with_suffix('.png')), output_width=png_width)
    return source


def raster(source, path, width):
    path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(bytestring=source.encode(), write_to=str(path), output_width=width)


for mode in ('light', 'dark', 'mono', 'inverse'):
    mark = save(f'passfin-mark-{mode}', 512, 512, drawing(mode), 1024)
    # Native Flutter density variants, without a new runtime SVG dependency.
    for folder, width in [('', 128), ('2.0x/', 256), ('3.0x/', 384)]:
        raster(mark, OUT / f'{folder}passfin-symbol-{mode}.png', width)
for dark in (False, True):
    mode = 'dark' if dark else 'light'
    horizontal = save(f'passfin-lockup-{mode}', 1000, 256,
        f'<g transform="scale(.5)">{drawing(mode)}</g>' + wordmark(280, 173, 155, dark), 2000)
    save(f'passfin-stacked-{mode}', 640, 650,
        f'<g transform="translate(64 0)">{drawing(mode)}</g>' + wordmark(89, 586, 120, dark), 1280)
    for folder, width in [('', 250), ('2.0x/', 500), ('3.0x/', 750)]:
        raster(horizontal, OUT / f'{folder}passfin-signature-{mode}.png', width)
# Full-bleed square icon: launcher applies its own mask. No baked rounded corners.
launcher = save('passfin-app-icon', 512, 512,
    '<path fill="#FFFFFF" d="M0 0H512V512H0Z"/>' +
    f'<g transform="translate(36 36) scale(.86)">{drawing()}</g>', 1024)
save('passfin-app-icon-dark', 512, 512,
    '<path fill="#000000" d="M0 0H512V512H0Z"/>' +
    f'<g transform="translate(36 36) scale(.86)">{drawing("dark")}</g>', 1024)
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    raster(launcher, RES / f'mipmap-{density}/ic_launcher.png', size)
# Adaptive and Android 12 splash: same vector, all geometry inside safe zone.
for name, mode in [('passfin_foreground','light'), ('passfin_monochrome','mono')]:
    content = '\n'.join(f'    <path android:fillColor="{fill}" android:fillType="evenOdd" android:pathData="{d}"/>' for fill,d in parts(mode))
    path = RES / f'drawable/{name}.xml'
    path.write_text('<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n  <group android:scaleX="0.12" android:scaleY="0.12" android:translateX="23.28" android:translateY="23.28">\n'+content+'\n  </group>\n</vector>\n')
for version in ('26','33'):
    path = RES / f'mipmap-anydpi-v{version}/ic_launcher.xml'
    path.parent.mkdir(parents=True, exist_ok=True)
    mono = '\n  <monochrome android:drawable="@drawable/passfin_monochrome"/>' if version == '33' else ''
    path.write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n  <background android:drawable="@color/passfin_launcher_background"/>\n  <foreground android:drawable="@drawable/passfin_foreground"/>'+mono+'\n</adaptive-icon>\n')
# Export an iOS catalog for future integration; no iOS Runner exists in this repo.
catalog = ROOT / 'docs/branding/ios/AppIcon.appiconset'
images = []
for idiom, sizes, scales in [('iphone',[20,29,40,60],[2,3]),('ipad',[20,29,40,76],[1,2])]:
    for size in sizes:
        for scale in scales:
            filename = f'icon-{size}@{scale}x.png'
            raster(launcher, catalog / filename, size * scale)
            images.append(dict(size=f'{size}x{size}',idiom=idiom,filename=filename,scale=f'{scale}x'))
raster(launcher, catalog/'icon-83.5@2x.png',167)
images.append(dict(size='83.5x83.5',idiom='ipad',filename='icon-83.5@2x.png',scale='2x'))
raster(launcher,catalog/'icon-1024.png',1024)
images.append(dict(size='1024x1024',idiom='ios-marketing',filename='icon-1024.png',scale='1x'))
(catalog/'Contents.json').write_text(json.dumps(dict(images=images,info=dict(version=1,author='PassFin')),indent=2)+'\n')
# Review sheet is kept outside the runtime asset bundle.
review = svg(1200,800, '<path fill="#FFFFFF" d="M0 0H600V800H0Z"/><path fill="#000000" d="M600 0H1200V800H600Z"/>'+f'<g transform="translate(110 20) scale(.75)">{drawing()}</g>'+wordmark(130,465,88)+f'<g transform="translate(710 20) scale(.75)">{drawing("dark")}</g>'+wordmark(730,465,88,True)+f'<g transform="translate(172 510) scale(.5)">{drawing("mono")}</g>'+f'<g transform="translate(772 510) scale(.5)">{drawing("inverse")}</g>')
(ROOT/'docs/branding/passfin-preview.svg').write_text(review)
raster(review,ROOT/'docs/branding/passfin-preview.png',1600)
print('Generated PassFin SVG/PNG assets, Android icons and portable iOS catalog.')
