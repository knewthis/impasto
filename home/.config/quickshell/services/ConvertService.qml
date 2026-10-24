// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C O N V E R T   S E R V I C E                                          │
// │   units and currencies · `10 km in mi`, `20 c to f`, `50 eur in usd`     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Units are a table of factors to each category's base unit, so adding one is
// a line. Currencies are the ECB's reference rates (`scripts/rates.py`),
// refreshed when the mode is entered and at most twice a day.
Singleton {
    id: root

    // name -> factor to the base unit, `show` being what a bare `10 km` lists.
    readonly property var categories: [
        { id: "length", show: ["mm", "cm", "m", "km", "in", "ft", "yd", "mi"],
          units: { mm: 0.001, cm: 0.01, m: 1, km: 1000, in: 0.0254, ft: 0.3048,
                   yd: 0.9144, mi: 1609.344, nmi: 1852, um: 1e-6 } },
        { id: "mass", show: ["mg", "g", "kg", "oz", "lb", "st"],
          units: { mg: 0.001, g: 1, kg: 1000, t: 1e6, oz: 28.349523125,
                   lb: 453.59237, st: 6350.29318 } },
        { id: "volume", show: ["ml", "l", "tsp", "tbsp", "floz", "cup", "pt", "gal"],
          units: { ml: 0.001, l: 1, tsp: 0.00492892159375, tbsp: 0.01478676478125,
                   floz: 0.0295735295625, cup: 0.2365882365, pt: 0.473176473,
                   qt: 0.946352946, gal: 3.785411784 } },
        { id: "time", show: ["s", "min", "h", "d", "wk"],
          units: { ms: 0.001, s: 1, min: 60, h: 3600, d: 86400, wk: 604800,
                   yr: 31557600 } },
        { id: "speed", show: ["m/s", "km/h", "mph", "kn"],
          units: { "m/s": 1, "km/h": 1 / 3.6, mph: 0.44704, kn: 0.514444 } },
        { id: "area", show: ["cm2", "m2", "km2", "ha", "ft2", "ac"],
          units: { cm2: 1e-4, m2: 1, km2: 1e6, ha: 1e4, ft2: 0.09290304,
                   ac: 4046.8564224 } },
        { id: "data", show: ["byte", "kb", "mb", "gb", "tb", "kib", "mib", "gib"],
          units: { bit: 0.125, byte: 1, kbit: 125, mbit: 125000, gbit: 1.25e8,
                   kb: 1e3, mb: 1e6, gb: 1e9, tb: 1e12,
                   kib: 1024, mib: 1048576, gib: 1073741824, tib: 1099511627776 } },
        { id: "temperature", show: ["c", "f", "k"], units: { c: 1, f: 1, k: 1 } }
    ]

    // What people type -> the name in the table above.
    readonly property var aliases: ({
        meter: "m", meters: "m", metre: "m", metres: "m", millimeter: "mm",
        millimeters: "mm", centimeter: "cm", centimeters: "cm", kilometer: "km",
        kilometers: "km", kilometre: "km", kilometres: "km", inch: "in",
        inches: "in", "\"": "in", foot: "ft", feet: "ft", "'": "ft", yard: "yd",
        yards: "yd", mile: "mi", miles: "mi", "µm": "um",
        gram: "g", grams: "g", kilo: "kg", kilos: "kg", kilogram: "kg",
        kilograms: "kg", ounce: "oz", ounces: "oz", pound: "lb", pounds: "lb",
        lbs: "lb", stone: "st", tonne: "t", ton: "t",
        liter: "l", liters: "l", litre: "l", litres: "l", milliliter: "ml",
        teaspoon: "tsp", tablespoon: "tbsp", cups: "cup", pint: "pt",
        pints: "pt", quart: "qt", gallon: "gal", gallons: "gal",
        sec: "s", secs: "s", second: "s", seconds: "s", minute: "min",
        minutes: "min", mins: "min", hour: "h", hours: "h", hr: "h", hrs: "h",
        day: "d", days: "d", week: "wk", weeks: "wk", year: "yr", years: "yr",
        kph: "km/h", kmh: "km/h", knot: "kn", knots: "kn",
        sqm: "m2", "m²": "m2", "km²": "km2", "cm²": "cm2", "ft²": "ft2",
        hectare: "ha", acre: "ac", acres: "ac",
        bytes: "byte", b: "byte", kbyte: "kb", mbyte: "mb", gbyte: "gb",
        bits: "bit", kbps: "kbit", mbps: "mbit", gbps: "gbit",
        celsius: "c", "°c": "c", fahrenheit: "f", "°f": "f", kelvin: "k"
    })

    function canonical(word: string): string {
        const lower = word.toLowerCase()
        return root.aliases[lower] ?? lower
    }

    // `{ category, unit }` or null.
    function find(word: string): var {
        const unit = root.canonical(word)
        for (const category of root.categories) {
            if (category.units[unit] !== undefined)
                return { category: category, unit: unit }
        }
        return null
    }

    function toBase(category: var, unit: string, value: real): real {
        if (category.id !== "temperature")
            return value * category.units[unit]
        // Celsius is the base.
        return unit === "f" ? (value - 32) * 5 / 9 : unit === "k" ? value - 273.15 : value
    }

    function fromBase(category: var, unit: string, value: real): real {
        if (category.id !== "temperature")
            return value / category.units[unit]
        return unit === "f" ? value * 9 / 5 + 32 : unit === "k" ? value + 273.15 : value
    }

    function label(unit: string): string {
        const nice = ({ c: "°C", f: "°F", k: "K", in: "in", byte: "B", floz: "fl oz",
                        yr: "yr", wk: "wk", um: "µm", m2: "m²", km2: "km²", cm2: "cm²",
                        ft2: "ft²", kb: "kB", mb: "MB", gb: "GB", tb: "TB", kib: "KiB",
                        mib: "MiB", gib: "GiB", tib: "TiB", kbit: "kbit", mbit: "Mbit",
                        gbit: "Gbit" })
        return nice[unit] ?? unit
    }

    // Seven significant figures, no exponent for ordinary sizes.
    function format(value: real): string {
        if (value === 0)
            return "0"
        const size = Math.abs(value)
        if (size >= 1e12 || size < 1e-5)
            return value.toExponential(5).replace(/\.?0+e/, "e")
        return `${parseFloat(value.toPrecision(7))}`
    }

    // ── CURRENCY ────────────────────────────────────────────────────────────

    property var rates: ({})
    property string ratesDate: ""

    readonly property string ratesPath: `${SettingsService.stateDirectory}/rates.json`

    readonly property FileView ratesFile: FileView {
        path: root.ratesPath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text())
                root.rates = data.rates ?? ({})
                root.ratesDate = data.date ?? ""
            } catch (error) {
                console.warn("Cannot parse the currency rates:", error)
            }
        }
    }

    function refresh(): void {
        if (!root.fetch.running)
            root.fetch.running = true
    }

    readonly property Process fetch: Process {
        command: [Quickshell.shellPath("scripts/rates.py"), root.ratesPath]
    }

    function currency(word: string): string {
        const code = word.toUpperCase()
        return root.rates[code] !== undefined ? code : ""
    }

    // ── PARSING ─────────────────────────────────────────────────────────────

    // `12.5 km in mi`, `12,5km to mi`, `-5 c > f`, `100 eur usd`.
    readonly property var full:
        /^\s*(-?\d+(?:[.,]\d+)?)\s*([^\s\d,.][^\s]*)\s+(?:(?:to|in|as|->|=>|>|=)\s+)?([^\s]+)\s*$/i
    // `12.5 km`: list the category.
    readonly property var bare: /^\s*(-?\d+(?:[.,]\d+)?)\s*([^\s\d,.][^\s]*)\s*$/

    function number(text: string): real {
        return parseFloat(text.replace(",", "."))
    }

    // Rows of `{ name, subtitle, value }`.
    function convert(term: string): var {
        const pair = root.full.exec(term)
        if (pair) {
            const value = root.number(pair[1])
            const from = pair[2]
            const into = pair[3]

            const a = root.currency(from)
            const b = root.currency(into)
            if (a !== "" && b !== "") {
                const out = value / root.rates[a] * root.rates[b]
                return [root.row(out, b, `${root.format(value)} ${a}  ·  ECB ${root.ratesDate}`)]
            }

            const left = root.find(from)
            const right = root.find(into)
            if (left && right && left.category === right.category) {
                const base = root.toBase(left.category, left.unit, value)
                const out = root.fromBase(right.category, right.unit, base)
                return [root.row(out, root.label(right.unit),
                    `${root.format(value)} ${root.label(left.unit)}`)]
            }
            return []
        }

        const single = root.bare.exec(term)
        if (!single)
            return []
        const value = root.number(single[1])
        const code = root.currency(single[2])
        if (code !== "") {
            const rows = []
            for (const other of ["EUR", "USD", "GBP", "PLN", "CHF", "JPY"]) {
                if (other === code || root.rates[other] === undefined)
                    continue
                rows.push(root.row(value / root.rates[code] * root.rates[other], other,
                    `${root.format(value)} ${code}  ·  ECB ${root.ratesDate}`))
            }
            return rows
        }

        const left = root.find(single[2])
        if (!left)
            return []
        const base = root.toBase(left.category, left.unit, value)
        return left.category.show.filter(unit => unit !== left.unit).map(unit =>
            root.row(root.fromBase(left.category, unit, base), root.label(unit),
                `${root.format(value)} ${root.label(left.unit)}`))
    }

    function row(value: real, unit: string, from: string): var {
        const shown = root.format(value)
        return { name: `${shown} ${unit}`, value: shown, subtitle: `${from}  ·  Enter copies the number` }
    }
}
