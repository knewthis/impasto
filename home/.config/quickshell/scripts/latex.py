#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   L A T E X                                                              │
# │   render a LaTeX expression to a PNG · preview and copy                  │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""Render LaTeX to an image for the launcher's `~` mode.

    latex.py check
    latex.py render --out FILE [--fg R,G,B] [--dpi N] SOURCE
    latex.py copy SOURCE

`render` prints one JSON line: `{"ok": true}` or `{"ok": false, "error": …}`,
the error being TeX's own first complaint. The PNG is transparent and tightly
cropped, drawn in `--fg` so that it reads on the shell's panel. `copy` renders
black on white, with a margin, and puts the image on the clipboard: that is
what reads on any page it is pasted into.

SOURCE is math by default, set as one display-style formula, like the bots on
Discord and Overleaf's equation preview. With a `$`, `\\(`, `\\[` or a
`\\begin{…}` in it, it is taken as it stands (text with math in it, `align`
and the like).

pdflatex runs without shell escape, in a temporary directory, with a timeout.
The packages that make maths comfortable are loaded when installed, so a
missing one narrows the preview instead of breaking it.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

TIMEOUT = 20

# Loaded when kpsewhich finds them. The first five are in every TeX Live.
PACKAGES = ["amsmath", "amssymb", "amsfonts", "mathtools", "xcolor",
            "bm", "physics", "siunitx", "cancel", "mathrsfs", "braket",
            "mhchem"]


def installed() -> list:
    """The packages above that TeX can find, in one kpsewhich call."""
    out = subprocess.run(["kpsewhich"] + [p + ".sty" for p in PACKAGES],
                         capture_output=True, text=True).stdout
    return [os.path.basename(line)[:-4] for line in out.split() if line.endswith(".sty")]


def tools() -> dict:
    return {
        "pdflatex": shutil.which("pdflatex"),
        "raster": shutil.which("pdftocairo") or shutil.which("pdftoppm"),
        "convert": shutil.which("magick") or shutil.which("convert"),
        "clip": shutil.which("wl-copy"),
    }


def is_text(source: str) -> bool:
    return bool(re.search(r"\$|\\\(|\\\[|\\begin\{", source))


def body(source: str) -> str:
    text = source.strip()
    if is_text(text):
        return text
    return "\\(\\displaystyle " + text + "\\)"


def document(source: str, fg: str) -> str:
    uses = "\n".join(f"\\usepackage{{{p}}}" for p in installed() if p != "xcolor")
    return (
        # A formula is one tight box; text and environments are paragraphs.
        f"\\documentclass[border=8pt{',varwidth' if is_text(source) else ''}]{{standalone}}\n"
        "\\usepackage[utf8]{inputenc}\n"
        "\\usepackage[T1]{fontenc}\n"
        "\\usepackage{xcolor}\n"
        f"{uses}\n"
        f"\\definecolor{{ink}}{{rgb}}{{{fg}}}\n"
        "\\begin{document}\n"
        "\\color{ink}\n"
        f"{body(source)}\n"
        "\\end{document}\n")


def first_error(log: str) -> str:
    lines = log.splitlines()
    for at, line in enumerate(lines):
        if line.startswith("!"):
            found = line[1:].strip()
            for after in lines[at + 1:at + 6]:
                if after.startswith("l."):
                    found += "  ·  " + after.strip()
                    break
            return found
    return "TeX could not set that"


def render(source: str, out: str, fg: str, dpi: int, white: bool) -> dict:
    found = tools()
    missing = [n for n in ("pdflatex", "raster") if not found[n]]
    if missing:
        return {"ok": False, "missing": True,
                "error": "LaTeX is not installed (pdflatex, poppler)"}

    with tempfile.TemporaryDirectory(prefix="impasto-latex-") as work:
        path = os.path.join(work, "doc.tex")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(document(source, fg))
        try:
            run = subprocess.run(
                [found["pdflatex"], "-interaction=nonstopmode", "-halt-on-error",
                 "-no-shell-escape", "doc.tex"],
                cwd=work, capture_output=True, text=True, errors="replace",
                timeout=TIMEOUT)
        except subprocess.TimeoutExpired:
            return {"ok": False, "error": "TeX took too long"}
        if run.returncode != 0 or not os.path.exists(os.path.join(work, "doc.pdf")):
            return {"ok": False, "error": first_error(run.stdout)}

        stem = os.path.join(work, "page")
        if os.path.basename(found["raster"]) == "pdftocairo":
            command = [found["raster"], "-png", "-singlefile", "-r", str(dpi)]
            if not white:
                command.append("-transp")
        else:
            command = [found["raster"], "-png", "-singlefile", "-r", str(dpi)]
        subprocess.run(command + [os.path.join(work, "doc.pdf"), stem],
                       capture_output=True, timeout=TIMEOUT)
        if not os.path.exists(stem + ".png"):
            return {"ok": False, "error": "The page could not be rasterised"}

        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        if white and found["convert"]:
            subprocess.run([found["convert"], stem + ".png", "-background", "white",
                            "-alpha", "remove", "-alpha", "off",
                            "-bordercolor", "white", "-border", "16", out],
                           capture_output=True, timeout=TIMEOUT)
        if not (white and found["convert"]) or not os.path.exists(out):
            shutil.copyfile(stem + ".png", out)
    return {"ok": True}


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="verb", required=True)
    sub.add_parser("check")
    one = sub.add_parser("render")
    one.add_argument("--out", required=True)
    one.add_argument("--fg", default="1,1,1")
    one.add_argument("--dpi", type=int, default=200)
    one.add_argument("source")
    two = sub.add_parser("copy")
    two.add_argument("source")
    args = parser.parse_args()

    if args.verb == "check":
        found = tools()
        print(json.dumps({"ok": bool(found["pdflatex"] and found["raster"])}))
        return 0

    if args.verb == "render":
        print(json.dumps(render(args.source, args.out, args.fg, args.dpi, False)))
        return 0

    out = os.path.join(tempfile.gettempdir(), f"impasto-latex-{os.getpid()}.png")
    result = render(args.source, out, "0,0,0", 300, True)
    if not result["ok"]:
        subprocess.run(["notify-send", "-a", "impasto", "LaTeX", result["error"]])
        return 1
    with open(out, "rb") as image:
        subprocess.run(["wl-copy", "-t", "image/png"], stdin=image)
    os.remove(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
