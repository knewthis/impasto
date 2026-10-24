// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C O L O U R   S E R V I C E                                            │
// │   a colour in any notation, shown in all of them                         │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

// Reads `#222`, `222222`, `#22222280`, `34 34 34`, `rgb(34, 34, 34)`,
// `hsl(0, 0%, 13%)` and a few names, and gives back hex, rgb, hsl and the
// forms LaTeX takes.
Singleton {
    id: root

    readonly property var names: ({
        black: "000000", white: "ffffff", red: "ff0000", green: "008000",
        blue: "0000ff", yellow: "ffff00", orange: "ffa500", purple: "800080",
        pink: "ffc0cb", cyan: "00ffff", magenta: "ff00ff", gray: "808080",
        grey: "808080", brown: "a52a2a", teal: "008080", navy: "000080"
    })

    function clamp(value: real, low: real, high: real): real {
        return Math.max(low, Math.min(high, value))
    }

    // `{ r, g, b, a }` with r, g, b in 0-255 and a in 0-1, or null.
    function parse(text: string): var {
        let term = (text ?? "").trim().toLowerCase().replace(/^#/, "")
        if (term === "")
            return null
        if (root.names[term] !== undefined)
            term = root.names[term]

        if (/^[0-9a-f]{3,4}$/.test(term))
            term = term.split("").map(digit => digit + digit).join("")
        if (/^[0-9a-f]{6}([0-9a-f]{2})?$/.test(term)) {
            return {
                r: parseInt(term.slice(0, 2), 16),
                g: parseInt(term.slice(2, 4), 16),
                b: parseInt(term.slice(4, 6), 16),
                a: term.length === 8 ? parseInt(term.slice(6, 8), 16) / 255 : 1
            }
        }

        const numbers = term.match(/-?\d+(?:\.\d+)?/g)
        if (!numbers || numbers.length < 3)
            return null
        const [x, y, z] = numbers.map(Number)

        if (/^hsl/.test(term) || /%/.test(term))
            return root.fromHsl(x, y, z)
        return { r: root.clamp(x, 0, 255), g: root.clamp(y, 0, 255),
                 b: root.clamp(z, 0, 255), a: 1 }
    }

    function fromHsl(h: real, s: real, l: real): var {
        const sat = root.clamp(s, 0, 100) / 100
        const light = root.clamp(l, 0, 100) / 100
        const chroma = (1 - Math.abs(2 * light - 1)) * sat
        const hue = ((h % 360) + 360) % 360 / 60
        const second = chroma * (1 - Math.abs(hue % 2 - 1))
        const [r, g, b] = hue < 1 ? [chroma, second, 0] : hue < 2 ? [second, chroma, 0]
            : hue < 3 ? [0, chroma, second] : hue < 4 ? [0, second, chroma]
            : hue < 5 ? [second, 0, chroma] : [chroma, 0, second]
        const shift = light - chroma / 2
        return { r: Math.round((r + shift) * 255), g: Math.round((g + shift) * 255),
                 b: Math.round((b + shift) * 255), a: 1 }
    }

    function toHsl(c: var): var {
        const r = c.r / 255, g = c.g / 255, b = c.b / 255
        const high = Math.max(r, g, b), low = Math.min(r, g, b)
        const light = (high + low) / 2
        const delta = high - low
        if (delta === 0)
            return { h: 0, s: 0, l: Math.round(light * 100) }
        const sat = delta / (1 - Math.abs(2 * light - 1))
        let hue = high === r ? ((g - b) / delta) % 6 : high === g ? (b - r) / delta + 2
            : (r - g) / delta + 4
        hue = (hue * 60 + 360) % 360
        return { h: Math.round(hue), s: Math.round(sat * 100), l: Math.round(light * 100) }
    }

    function hex(c: var): string {
        const part = value => Math.round(value).toString(16).padStart(2, "0")
        return part(c.r) + part(c.g) + part(c.b)
            + (c.a < 1 ? part(c.a * 255) : "")
    }

    // Rows of `{ name, value, subtitle, swatch }`.
    function rows(term: string): var {
        const c = root.parse(term)
        if (!c)
            return []
        const hsl = root.toHsl(c)
        const swatch = `#${root.hex({ r: c.r, g: c.g, b: c.b, a: 1 })}`
        const hexText = `#${root.hex(c)}`
        const rgbText = c.a < 1
            ? `rgba(${Math.round(c.r)}, ${Math.round(c.g)}, ${Math.round(c.b)}, ${+c.a.toFixed(2)})`
            : `rgb(${Math.round(c.r)}, ${Math.round(c.g)}, ${Math.round(c.b)})`
        const hslText = `hsl(${hsl.h}, ${hsl.s}%, ${hsl.l}%)`
        const html = root.hex({ r: c.r, g: c.g, b: c.b, a: 1 }).toUpperCase()
        const unit = value => +(value / 255).toFixed(3)
        const forms = [
            ["Hex", hexText], ["RGB", rgbText], ["HSL", hslText],
            ["LaTeX", `\\color[HTML]{${html}}`],
            ["LaTeX rgb", `\\definecolor{name}{rgb}{${unit(c.r)}, ${unit(c.g)}, ${unit(c.b)}}`]
        ]
        return forms.map(form => ({
            kind: "colour", id: form[1], swatch: swatch, name: form[1],
            value: form[1], subtitle: `${form[0]}  ·  Enter copies it`
        }))
    }
}
