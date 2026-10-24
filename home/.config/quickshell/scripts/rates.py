#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   R A T E S                                                              │
# │   currency rates for the launcher's converter                            │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""Keep a day-old copy of the European Central Bank's reference rates.

Usage: rates.py FILE

Fetches from frankfurter.dev (the ECB's daily rates, no key) unless FILE is
under twelve hours old, and writes `{ "base": "EUR", "date": …, "rates": … }`
whole, so the shell never reads half of it. Offline, the old file stays.
"""

import json
import os
import sys
import time
import urllib.request

URL = "https://api.frankfurter.dev/v1/latest?base=EUR"
FRESH = 12 * 3600


def main():
    path = sys.argv[1]
    try:
        if time.time() - os.path.getmtime(path) < FRESH:
            return
    except OSError:
        pass
    try:
        with urllib.request.urlopen(URL, timeout=10) as reply:
            data = json.load(reply)
        data["rates"]["EUR"] = 1.0
        os.makedirs(os.path.dirname(path), exist_ok=True)
        temporary = path + ".tmp"
        with open(temporary, "w") as handle:
            json.dump({"base": "EUR", "date": data.get("date", ""),
                       "rates": data["rates"]}, handle)
        os.replace(temporary, path)
    except Exception:
        pass


if __name__ == "__main__":
    main()
