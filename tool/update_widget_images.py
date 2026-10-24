"""Capture actual Android RemoteViews with fictional fixtures for the README.

Run against a disposable emulator: uv run --with pillow python
  tool/update_widget_images.py --serial emulator-5554
"""

import argparse
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "com.vinicius.key_budget"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--serial", required=True, help="Disposable Android emulator serial"
    )
    args = parser.parse_args()
    sdk = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Android/Sdk")))
    adb = shutil.which("adb") or str(sdk / "platform-tools/adb")
    device = [adb, "-s", args.serial]
    qemu = subprocess.check_output(
        device + ["shell", "getprop", "ro.kernel.qemu"], text=True
    ).strip()
    if qemu != "1":
        parser.error(
            "Use a disposable emulator; this command installs the debug application."
        )
    subprocess.run(
        [
            "./gradlew",
            ":app:assembleDebug",
            ":app:assembleDebugAndroidTest",
            "--max-workers=1",
        ],
        cwd=ROOT / "android",
        check=True,
    )
    for apk in ["debug/app-debug.apk", "androidTest/debug/app-debug-androidTest.apk"]:
        subprocess.run(
            device + ["install", "-r", str(ROOT / "build/app/outputs/apk" / apk)],
            check=True,
        )
    result = subprocess.check_output(
        device
        + [
            "shell",
            "am",
            "instrument",
            "-w",
            "-e",
            "class",
            f"{PACKAGE}.WidgetRenderingTest",
            "-e",
            "captureWidgets",
            "true",
            f"{PACKAGE}.test/androidx.test.runner.AndroidJUnitRunner",
        ],
        text=True,
    )
    print(result)
    if (
        "OK (" not in result
        or "FAILURES" in result
        or "INSTRUMENTATION_FAILED" in result
    ):
        raise RuntimeError(
            "Native widget rendering tests failed; no README images were replaced."
        )
    output = ROOT / "build/widget-captures"
    output.mkdir(parents=True, exist_ok=True)
    for mode in ["light", "dark"]:
        source = output / f"widgets-{mode}.png"
        source.write_bytes(
            subprocess.check_output(
                device
                + [
                    "exec-out",
                    "run-as",
                    PACKAGE,
                    "cat",
                    f"files/widget-captures/widgets-{mode}.png",
                ]
            )
        )
        with Image.open(source) as capture:
            capture.convert("RGB").save(
                ROOT / f"docs/images/widgets-{mode}.jpg",
                quality=92,
                optimize=True,
                subsampling=0,
            )


if __name__ == "__main__":
    main()
