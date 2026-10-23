#!/usr/bin/env python3
"""Render the real Flutter widgets with demo data and encode README images."""
import os
from pathlib import Path
import shutil
import subprocess

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'build' / 'readme-captures'
NAMES = {
    'home-expenses': 'home',
    'home': 'home-income',
    'expenses': 'expense',
    'credentials': 'credentials',
    'documents': 'documents',
    'analysis': 'analysis1',
    'analysis-distribution': 'analysis2',
    'goals': 'goals',
    'profile': 'user',
    'dashboard-charts': 'dashboard-charts',
    'customization': 'customization',
}


def main():
    flutter = os.environ.get('FLUTTER_BIN') or shutil.which('flutter')
    if not flutter:
        raise SystemExit('Flutter não encontrado. Adicione-o ao PATH ou defina FLUTTER_BIN.')
    subprocess.run(
        [flutter, 'test', 'test/screenshots/readme_screenshots_test.dart'],
        cwd=ROOT,
        env={**os.environ, 'CAPTURE_README': '1', 'SCREENSHOT_DIR': str(OUTPUT)},
        check=True,
    )
    target = ROOT / 'docs' / 'images'
    for source, name in NAMES.items():
        for mode in ('light', 'dark'):
            with Image.open(OUTPUT / f'{source}-{mode}.png') as image:
                image.convert('RGB').save(
                    target / f'{name}-{mode}.jpg',
                    quality=92, optimize=True, subsampling=0,
                )
    print(f'{len(NAMES) * 2} capturas atualizadas em docs/images.')


if __name__ == '__main__':
    main()
