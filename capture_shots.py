#!/usr/bin/env python3
"""Capture REAL in-app App Store screenshots for Cờ Cá Ngựa via the simulator
and DEBUG CN_CAPTURE/CN_LANG launch args. Adds a felt-green/gold caption band.
Every shot is the actual app UI (App Review 2.3.3). Output:
screenshots/final/{en,vi}/*.png"""
import os, re, subprocess, sys, time
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

APP_DIR = Path(__file__).resolve().parent
PROJECT = APP_DIR / "CoCaNgua.xcodeproj"
SCHEME = "CoCaNgua"
BUNDLE = "com.quyenngo.cocangua"
W, H = 1320, 2868
BAND = 470

SHOTS = {
    "en": [
        ("01-home",       "home",       "Cờ Cá Ngựa —\nVietnamese Horse Race"),
        ("02-midgame",    "midgame",    "Roll, race, and\năn quân to capture"),
        ("03-upgrade",    "upgrade",    "Hard AI —\nplays to avoid capture"),
        ("04-rules",      "rules",      "Full rules,\nbuilt right in"),
    ],
    "vi": [
        ("01-home",       "home",       "Cờ Cá Ngựa —\nĐua Ngựa Việt Nam"),
        ("02-midgame",    "midgame",    "Đổ xúc xắc, đua ngựa,\năn quân đối thủ"),
        ("03-upgrade",    "upgrade",    "AI Khó —\nbiết né bị ăn quân"),
        ("04-rules",      "rules",      "Luật chơi đầy đủ\nngay trong app"),
    ],
}

FONT_PATHS = ["/System/Library/Fonts/SFNSDisplay.ttf", "/System/Library/Fonts/SFNS.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf"]


def sh(*a, **k): return subprocess.run(a, check=True, capture_output=True, text=True, **k)


def find_device():
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "available"],
                         capture_output=True, text=True).stdout
    # Prefer a dedicated capture-only simulator (avoids grabbing a shared/booted
    # "iPhone ... Pro Max" that another app/session in this multi-app Vietnamese-games
    # lineup has open — that caused screenshots of the WRONG app to be captured once).
    for line in out.splitlines():
        m = re.search(r"^\s*(CoCaNgua-Capture)\s+\(([0-9A-F\-]{36})\)", line)
        if m:
            return m.group(2), m.group(1)
    for line in out.splitlines():
        m = re.search(r"^\s*(iPhone .*Pro Max)\s+\(([0-9A-F\-]{36})\)", line)
        if m:
            return m.group(2), m.group(1)
    raise SystemExit("No available 'iPhone ... Pro Max' simulator found")


def build_app():
    sh("xcodebuild", "-project", str(PROJECT), "-scheme", SCHEME, "-configuration", "Debug",
       "-sdk", "iphonesimulator", "-derivedDataPath", str(APP_DIR / "build/sim"), "build",
       cwd=str(APP_DIR))
    app = APP_DIR / "build/sim/Build/Products/Debug-iphonesimulator/CoCaNgua.app"
    if not app.exists():
        raise SystemExit(f"built app not found at {app}")
    return app


def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def font(size, paths=None):
    for c in (paths or FONT_PATHS):
        if Path(c).exists():
            try: return ImageFont.truetype(c, size)
            except Exception: continue
    return ImageFont.load_default()


def compose(raw_png, headline, out_png):
    shot = Image.open(raw_png).convert("RGB").resize((W, H), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(canvas)
    top, bot = (5, 20, 13), (8, 46, 28)  # felt-green gradient
    for y in range(H):
        d.line([(0, y), (W, y)], fill=lerp(top, bot, y / H))
    lines = headline.split("\n")
    size = 100
    max_w = W * 0.9
    f = font(size)
    while size > 56 and max(d.textlength(line, font=f) for line in lines) > max_w:
        size -= 4
        f = font(size)
    lh = int(size * 1.18)
    y = (BAND - lh * len(lines)) // 2 + 8
    for line in lines:
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, y), line, font=f, fill=(255, 205, 90)); y += lh
    avail_h = H - BAND - 70
    sw = int(W * 0.84); sh_ = int(shot.height * sw / shot.width)
    if sh_ > avail_h: sh_ = avail_h; sw = int(shot.width * sh_ / shot.height)
    shot = shot.resize((sw, sh_), Image.LANCZOS)
    mask = Image.new("L", (sw, sh_), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh_], radius=54, fill=255)
    px = (W - sw) // 2; py = BAND + (avail_h - sh_) // 2 + 35
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([px, py + 16, px + sw, py + sh_ + 16], radius=54, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    canvas.paste(shot, (px, py), mask)
    canvas.save(out_png); print(f"  wrote {out_png.name}")


def main():
    DEVICE, name = find_device()
    print(f"==> device {name}")
    APP = build_app()
    subprocess.run(["xcrun", "simctl", "shutdown", DEVICE], capture_output=True)
    subprocess.run(["xcrun", "simctl", "boot", DEVICE], capture_output=True)
    sh("xcrun", "simctl", "bootstatus", DEVICE, "-b")
    subprocess.run(["xcrun", "simctl", "status_bar", DEVICE, "override", "--time", "9:41",
                    "--batteryLevel", "100", "--batteryState", "charged",
                    "--cellularBars", "4", "--wifiBars", "3"], capture_output=True)
    sh("xcrun", "simctl", "install", DEVICE, str(APP))
    # Warm-up launch: a fresh simulator boot fires a one-time system notification
    # banner ("Ready for Apple Intelligence") that can land on top of the first real
    # screenshot. Launch once and let it settle/dismiss before the real capture loop.
    subprocess.run(["xcrun", "simctl", "launch", DEVICE, BUNDLE],
                   env=dict(os.environ, SIMCTL_CHILD_CN_CAPTURE="home", SIMCTL_CHILD_CN_LANG="en"),
                   capture_output=True)
    time.sleep(5)
    subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
    raw = APP_DIR / "screenshots" / "_raw.png"
    for lang, shots in SHOTS.items():
        out = APP_DIR / "screenshots" / "final" / lang
        out.mkdir(parents=True, exist_ok=True)
        for shotname, cap, headline in shots:
            subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
            subprocess.run(["xcrun", "simctl", "launch", DEVICE, BUNDLE],
                           env=dict(os.environ, SIMCTL_CHILD_CN_CAPTURE=cap, SIMCTL_CHILD_CN_LANG=lang),
                           capture_output=True)
            time.sleep(2)
            sh("xcrun", "simctl", "io", DEVICE, "screenshot", str(raw))
            compose(raw, headline, out / f"{shotname}.png")
    raw.unlink(missing_ok=True)
    subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
    print("==> done.", APP_DIR / "screenshots" / "final")


if __name__ == "__main__":
    main()
