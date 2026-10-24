#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   S Y M B O L S                                                          │
# │   every named Unicode character, for the launcher's symbol lookup        │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""List the Unicode characters worth searching by name, as JSON.

Usage: symbols.py

`[[code point, NAME, 1 if it combines with the one before], …]`, in code point
order. Controls, private use and unassigned points are left out, and so are
the blocks that are tens of thousands of near-identical names (CJK ideographs,
Hangul syllables): nobody finds those by name. The names come from Python's
own `unicodedata`, so the list is as new as the system's Python.
"""

import json
import unicodedata

SKIP = [(0x3400, 0x4DBF), (0x4E00, 0x9FFF), (0xAC00, 0xD7AF), (0xD800, 0xF8FF),
        (0xF900, 0xFAFF), (0x17000, 0x18AFF), (0x1B170, 0x1B2FF)]


def main():
    out = []
    for code in range(0x20, 0x20000):
        if any(low <= code <= high for low, high in SKIP):
            continue
        char = chr(code)
        if unicodedata.category(char).startswith("C"):
            continue
        name = unicodedata.name(char, "")
        if name:
            out.append([code, name, 1 if unicodedata.combining(char) else 0])
    print(json.dumps(out, separators=(",", ":")))


if __name__ == "__main__":
    main()
