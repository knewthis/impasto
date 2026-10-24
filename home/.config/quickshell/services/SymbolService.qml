// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S Y M B O L   S E R V I C E                                            │
// │   find a Unicode character by name or code point                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// `scripts/symbols.py` lists the named characters once per session, the first
// time the mode is entered. A search is every word of the term found in the
// name (`arrow up`, `partial`, `greek alpha`), `U+2202` or `0x2202` for a code
// point, or a single pasted character to learn its name.
Singleton {
    id: root

    // `[code point, NAME, combining]`, in code point order.
    property var symbols: []
    property bool requested: false

    function load(): void {
        if (root.requested)
            return
        root.requested = true
        root.indexProcess.running = true
    }

    readonly property Process indexProcess: Process {
        command: [Quickshell.shellPath("scripts/symbols.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.symbols = JSON.parse(text)
                } catch (error) {
                    console.warn("Cannot parse the symbol list:", error)
                    root.requested = false
                }
            }
        }
    }

    function glyph(entry: var): string {
        // A combining mark needs something to sit on.
        return (entry[2] ? "◌" : "") + String.fromCodePoint(entry[0])
    }

    function titled(name: string): string {
        const lower = name.toLowerCase()
        return lower.charAt(0).toUpperCase() + lower.slice(1)
    }

    function row(entry: var): var {
        const code = entry[0].toString(16).toUpperCase().padStart(4, "0")
        return {
            kind: "symbol", id: code, icon: "", glyph: root.glyph(entry),
            copy: String.fromCodePoint(entry[0]),
            name: root.titled(entry[1]),
            subtitle: `U+${code}  ·  Enter copies it`
        }
    }

    function at(code: int): var {
        let low = 0
        let high = root.symbols.length - 1
        while (low <= high) {
            const middle = (low + high) >> 1
            const found = root.symbols[middle][0]
            if (found === code)
                return root.symbols[middle]
            if (found < code)
                low = middle + 1
            else
                high = middle - 1
        }
        return null
    }

    function search(term: string, limit: int): var {
        if (root.symbols.length === 0 || term === "")
            return []

        const point = /^(?:u\+|0x|\\u)([0-9a-f]{2,6})$/i.exec(term)
        if (point) {
            const entry = root.at(parseInt(point[1], 16))
            return entry ? [root.row(entry)] : []
        }

        const chars = Array.from(term)
        if (chars.length === 1) {
            const entry = root.at(chars[0].codePointAt(0))
            return entry ? [root.row(entry)] : []
        }

        const words = term.toUpperCase().split(/\s+/).filter(word => word !== "")
        const phrase = words.join(" ")
        const found = []
        for (const entry of root.symbols) {
            const name = entry[1]
            let rank = 3
            let matched = true
            for (const word of words) {
                const at = name.indexOf(word)
                if (at < 0) {
                    matched = false
                    break
                }
                if (at > 0 && name[at - 1] !== " " && name[at - 1] !== "-")
                    rank = Math.max(rank, 4)
            }
            if (!matched)
                continue
            if (name === phrase)
                rank = 0
            else if (name.startsWith(phrase))
                rank = 1
            else if (rank === 3)
                rank = 2
            found.push([rank, name.length, entry])
        }
        found.sort((a, b) => a[0] - b[0] || a[1] - b[1] || a[2][0] - b[2][0])
        return found.slice(0, limit).map(item => root.row(item[2]))
    }
}
