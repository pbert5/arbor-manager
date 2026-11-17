"""Record a walkthrough from the packaged TUI using a local pseudo-terminal."""

import argparse
import fcntl
import os
import pty
import select
import struct
import subprocess
import termios
import time
from pathlib import Path

import pyte
from PIL import Image, ImageDraw, ImageFont

COLUMNS, ROWS = 112, 25
CELL_W, CELL_H = 10, 21
PAD = 20
WIDTH = COLUMNS * CELL_W + 2 * PAD
HEIGHT = ROWS * CELL_H + 106
BG, FG, ACCENT = "#101923", "#e1e8ed", "#8bdcc4"
COLORS = dict(
    black="#18232d", red="#ff8f87", green="#93d4a8", yellow="#efc78b",
    blue="#90b6f8", magenta="#d4abe9", cyan="#85d8d7", white=FG,
)
HERE = Path(__file__).resolve().parent


def color(name, default):
    if name.startswith("bright"):
        name = name[6:]
    if len(name) == 6 and all(c in "0123456789abcdef" for c in name.lower()):
        return "#" + name
    return COLORS.get(name, default)


def capture(master, stream, screen, expected):
    """Wait for the requested text and the end of its terminal repaint."""
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if select.select([master], [], [], 0.18)[0]:
            stream.feed(os.read(master, 65536))
        elif expected in "\n".join(screen.display):
            break
    return "\n".join(screen.display)


def render(screen, font, bold, tab, keys, caption):
    frame = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(frame)
    for y in range(ROWS):
        for x in range(COLUMNS):
            cell = screen.buffer[y][x]
            fg, bg = color(cell.fg, FG), color(cell.bg, BG)
            if cell.reverse:
                fg, bg = bg, fg
            left, top = PAD + x * CELL_W, 12 + y * CELL_H
            if bg != BG:
                draw.rectangle((left, top, left + CELL_W - 1, top + CELL_H - 1), fill=bg)
            draw.text((left, top), cell.data, font=bold if cell.bold else font, fill=fg)
    y = 24 + ROWS * CELL_H
    draw.rectangle((0, y, WIDTH, HEIGHT), fill="#1c2c39")
    draw.text((PAD, y + 9), tab.upper() + "   /   " + keys, font=font, fill=ACCENT)
    draw.text((PAD, y + 37), caption, font=font, fill=FG)
    return frame


def record(binary, font, bold, tab, steps, debug):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLUMNS, 0, 0))
    screen = pyte.Screen(COLUMNS, ROWS)
    stream = pyte.ByteStream(screen)
    frames = []
    try:
        with subprocess.Popen([binary, "tui", "--demo", "--tab", tab],
                              stdin=slave, stdout=slave, stderr=slave,
                              env=dict(os.environ, TERM="linux")) as app:
            try:
                for keys, label, caption, expected in steps:
                    if keys:
                        os.write(master, keys.encode())
                    display = capture(master, stream, screen, expected)
                    if debug:
                        print(label, display, sep="\n")
                    if expected not in display:
                        raise ValueError(f"{tab} / {label}: missing {expected!r}\n{display}")
                    frames.append(render(screen, font, bold, tab, label, caption))
                os.write(master, b"q")
                if app.wait(timeout=5) != 0:
                    raise RuntimeError(f"{tab} exited with {app.returncode}")
            finally:
                if app.poll() is None:
                    app.kill()
    finally:
        os.close(slave)
        os.close(master)
    frames[0].save(HERE / f"{tab}.gif", save_all=True, append_images=frames[1:],
                   loop=0, duration=4200, optimize=True)


if __name__ == "__main__":
    from scenes import TOURS

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary")
    parser.add_argument("font_dir", type=Path)
    parser.add_argument("--tab", choices=TOURS)
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()
    font = ImageFont.truetype(args.font_dir / "DejaVuSansMono.ttf", 16)
    bold = ImageFont.truetype(args.font_dir / "DejaVuSansMono-Bold.ttf", 16)
    for tab, steps in TOURS.items():
        if args.tab in (None, tab):
            record(args.binary, font, bold, tab, steps, args.debug)
