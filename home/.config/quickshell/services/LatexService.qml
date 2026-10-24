// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L A T E X   S E R V I C E                                              │
// │   LaTeX to Unicode · \alpha becomes α, x^2 becomes x²                    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

// The text a launcher mode converts. A built-in table, so nothing has to be
// installed: Greek, operators, relations, arrows, blackboard letters, and
// sub- and superscripts where Unicode has the glyphs. What it cannot draw
// stays as typed (`x^(a+b)`), never silently dropped.
Singleton {
    id: root

    readonly property var symbols: ({
        // Greek
        alpha: "α", beta: "β", gamma: "γ", delta: "δ", epsilon: "ε", varepsilon: "ε",
        zeta: "ζ", eta: "η", theta: "θ", vartheta: "ϑ", iota: "ι", kappa: "κ",
        lambda: "λ", mu: "μ", nu: "ν", xi: "ξ", pi: "π", varpi: "ϖ", rho: "ρ",
        varrho: "ϱ", sigma: "σ", varsigma: "ς", tau: "τ", upsilon: "υ", phi: "φ",
        varphi: "ϕ", chi: "χ", psi: "ψ", omega: "ω",
        Gamma: "Γ", Delta: "Δ", Theta: "Θ", Lambda: "Λ", Xi: "Ξ", Pi: "Π",
        Sigma: "Σ", Upsilon: "Υ", Phi: "Φ", Psi: "Ψ", Omega: "Ω",
        // Operators
        pm: "±", mp: "∓", times: "×", div: "÷", cdot: "·", ast: "∗", star: "⋆",
        circ: "∘", bullet: "•", oplus: "⊕", ominus: "⊖", otimes: "⊗", odot: "⊙",
        cap: "∩", cup: "∪", wedge: "∧", vee: "∨", land: "∧", lor: "∨", neg: "¬",
        lnot: "¬", setminus: "∖",
        sum: "∑", prod: "∏", coprod: "∐", int: "∫", iint: "∬", iiint: "∭",
        oint: "∮", bigcup: "⋃", bigcap: "⋂", bigoplus: "⨁", bigotimes: "⨂",
        partial: "∂", nabla: "∇", infty: "∞", sqrt: "√", prime: "′",
        // Relations
        leq: "≤", le: "≤", geq: "≥", ge: "≥", neq: "≠", ne: "≠", approx: "≈",
        equiv: "≡", sim: "∼", simeq: "≃", cong: "≅", propto: "∝", ll: "≪",
        gg: "≫", subset: "⊂", supset: "⊃", subseteq: "⊆", supseteq: "⊇",
        in: "∈", notin: "∉", ni: "∋", perp: "⊥", parallel: "∥", mid: "∣",
        // Arrows
        to: "→", rightarrow: "→", leftarrow: "←", leftrightarrow: "↔",
        Rightarrow: "⇒", Leftarrow: "⇐", Leftrightarrow: "⇔", implies: "⟹",
        iff: "⟺", mapsto: "↦", uparrow: "↑", downarrow: "↓", longrightarrow: "⟶",
        // Logic and sets
        forall: "∀", exists: "∃", nexists: "∄", emptyset: "∅", varnothing: "∅",
        therefore: "∴", because: "∵", top: "⊤", bot: "⊥", vdash: "⊢", models: "⊨",
        // Misc
        hbar: "ℏ", ell: "ℓ", Re: "ℜ", Im: "ℑ", aleph: "ℵ", angle: "∠",
        degree: "°", ldots: "…", dots: "…", cdots: "⋯", vdots: "⋮", ddots: "⋱",
        langle: "⟨", rangle: "⟩", lfloor: "⌊", rfloor: "⌋", lceil: "⌈", rceil: "⌉",
        quad: " ", qquad: "  ", ",": " ", ";": " ", ":": " ", "!": "",
        "{": "{", "}": "}", "%": "%", "&": "&", "_": "_", "#": "#", "$": "$",
        "\\": "\n", " ": " "
    })

    readonly property var blackboard: ({
        R: "ℝ", N: "ℕ", Z: "ℤ", Q: "ℚ", C: "ℂ", P: "ℙ", H: "ℍ", E: "𝔼", "1": "𝟙"
    })

    readonly property var calligraphic: ({
        L: "ℒ", H: "ℋ", F: "ℱ", B: "ℬ", E: "ℰ", M: "ℳ", R: "ℛ", I: "ℐ",
        O: "𝒪", N: "𝒩", P: "𝒫", C: "𝒞", D: "𝒟", S: "𝒮", T: "𝒯", X: "𝒳"
    })

    readonly property var superscripts: ({
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶",
        "7": "⁷", "8": "⁸", "9": "⁹", "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽",
        ")": "⁾", n: "ⁿ", i: "ⁱ", a: "ᵃ", b: "ᵇ", c: "ᶜ", d: "ᵈ", e: "ᵉ",
        f: "ᶠ", g: "ᵍ", h: "ʰ", j: "ʲ", k: "ᵏ", l: "ˡ", m: "ᵐ", o: "ᵒ",
        p: "ᵖ", r: "ʳ", s: "ˢ", t: "ᵗ", u: "ᵘ", v: "ᵛ", w: "ʷ", x: "ˣ",
        y: "ʸ", z: "ᶻ", "−": "⁻", "′": "′", "∘": "°", "*": "*",
        "α": "ᵅ", "β": "ᵝ", "γ": "ᵞ", "δ": "ᵟ", "θ": "ᶿ", "φ": "ᵠ", "χ": "ᵡ"
    })

    readonly property var subscripts: ({
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆",
        "7": "₇", "8": "₈", "9": "₉", "+": "₊", "-": "₋", "=": "₌", "(": "₍",
        ")": "₎", a: "ₐ", e: "ₑ", h: "ₕ", i: "ᵢ", j: "ⱼ", k: "ₖ", l: "ₗ",
        m: "ₘ", n: "ₙ", o: "ₒ", p: "ₚ", r: "ᵣ", s: "ₛ", t: "ₜ", u: "ᵤ",
        v: "ᵥ", x: "ₓ", "−": "₋",
        "β": "ᵦ", "γ": "ᵧ", "ρ": "ᵨ", "φ": "ᵩ", "χ": "ᵪ"
    })

    // Combining marks for accents over one symbol.
    readonly property var accents: ({
        hat: "̂", bar: "̄", overline: "̄", vec: "⃗", dot: "̇", ddot: "̈",
        tilde: "̃", widetilde: "̃", widehat: "̂", underline: "̲", acute: "́",
        grave: "̀", breve: "̆", check: "̌"
    })

    readonly property var fractions: ({
        "1/2": "½", "1/3": "⅓", "2/3": "⅔", "1/4": "¼", "3/4": "¾",
        "1/5": "⅕", "1/6": "⅙", "1/8": "⅛"
    })

    // The text of the `{…}` group starting at `at`, and the index after it.
    // A bare token (one letter, digit or command) stands in for a group, as in
    // `x^2` and `\frac12`.
    function group(text: string, at: int): var {
        while (at < text.length && text[at] === " ")
            at++
        if (at >= text.length)
            return { body: "", end: at, found: false }
        if (text[at] === "{") {
            let depth = 0
            for (let i = at; i < text.length; i++) {
                if (text[i] === "{") depth++
                else if (text[i] === "}" && --depth === 0)
                    return { body: text.slice(at + 1, i), end: i + 1, found: true }
            }
            return { body: text.slice(at + 1), end: text.length, found: true }
        }
        if (text[at] === "\\") {
            const name = /^\\([A-Za-z]+|.)/.exec(text.slice(at))
            return { body: name[0], end: at + name[0].length, found: true }
        }
        return { body: text[at], end: at + 1, found: true }
    }

    // `table[char]` for every character, or null when one has no glyph.
    function mapped(text: string, table: var): var {
        let out = ""
        for (const ch of text) {
            if (table[ch] === undefined)
                return null
            out += table[ch]
        }
        return out
    }

    function wrap(text: string): string {
        return text.length <= 1 ? text : `(${text})`
    }

    function convert(source: string): string {
        const text = source ?? ""
        let out = ""
        let i = 0
        while (i < text.length) {
            const ch = text[i]

            if (ch === "\\") {
                const m = /^\\([A-Za-z]+|[^A-Za-z])/.exec(text.slice(i))
                if (!m) {
                    // A lone backslash at the end: the command is still being typed.
                    out += ch
                    i++
                    continue
                }
                const name = m[1]
                i += m[0].length

                if (name === "frac" || name === "dfrac" || name === "tfrac") {
                    const top = root.group(text, i)
                    const bottom = root.group(text, top.end)
                    i = bottom.end
                    const a = root.convert(top.body)
                    const b = root.convert(bottom.body)
                    out += root.fractions[`${a}/${b}`] ?? `${root.wrap(a)}/${root.wrap(b)}`
                } else if (name === "sqrt") {
                    const arg = root.group(text, i)
                    i = arg.end
                    const inner = root.convert(arg.body)
                    out += "√" + (inner.length > 1 ? `(${inner})` : inner)
                } else if (name === "mathbb" || name === "mathcal") {
                    const arg = root.group(text, i)
                    i = arg.end
                    const table = name === "mathbb" ? root.blackboard : root.calligraphic
                    out += root.mapped(arg.body, table) ?? root.convert(arg.body)
                } else if (root.accents[name] !== undefined) {
                    const arg = root.group(text, i)
                    i = arg.end
                    const base = root.convert(arg.body)
                    out += base + root.accents[name]
                } else if (name === "text" || name === "mathrm" || name === "mathbf"
                           || name === "mathit" || name === "operatorname"
                           || name === "left" || name === "right") {
                    // Wrappers: the content stands for itself.
                    if (name === "left" || name === "right") {
                        if (text[i] === ".") i++
                        continue
                    }
                    const arg = root.group(text, i)
                    i = arg.end
                    out += root.convert(arg.body)
                } else if (root.symbols[name] !== undefined) {
                    out += root.symbols[name]
                } else {
                    out += m[0]
                }
                continue
            }

            if (ch === "^" || ch === "_") {
                const arg = root.group(text, i + 1)
                if (!arg.found) {
                    out += ch
                    i++
                    continue
                }
                i = arg.end
                const inner = root.convert(arg.body)
                const table = ch === "^" ? root.superscripts : root.subscripts
                const small = root.mapped(inner, table)
                out += small ?? `${ch}${inner.length > 1 ? `(${inner})` : inner}`
                continue
            }

            if (ch === "{" || ch === "}") {
                i++
                continue
            }
            if (ch === "~") {
                out += " "
                i++
                continue
            }
            out += ch
            i++
        }
        return out
    }

    function copy(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text])
    }
}
