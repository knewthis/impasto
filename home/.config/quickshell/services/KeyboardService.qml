// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   K E Y B O A R D   S E R V I C E                                        │
// │   keyboard layout · the active one, and how to move to the next          │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The layout Hyprland is typing in, read from `hyprctl devices -j` and read
// again whenever the compositor says the layout changed, so a switch made by a
// key, by `hyprctl` or from here all show up the same way.
//
// Hyprland names the active layout in words ("Polish"); the bar wants "PL".
// xkeyboard-config lists both, in `evdev.lst`, and that file is read once.
// A name it does not know falls back to its first two letters.
Singleton {
    id: root

    readonly property string icon: "󰌌"

    // The active layout as Hyprland names it, and the configured list
    // (`input:kb_layout`, comma separated), from the main keyboard.
    property string name: ""
    property string layoutList: ""

    readonly property int count: root.layoutList === "" ? 0 : root.layoutList.split(",").length

    // One layout has nothing to indicate, so the module only shows with two.
    readonly property bool available: root.count > 1

    readonly property string code: root.codeOf(root.name)

    // ── INPUT METHOD ────────────────────────────────────────────────────────
    //
    // Some layouts are typed through an input method: with `cn` the keys are
    // QWERTY and pinyin turns them into characters. fcitx5 holds that, and
    // here it is switched on while one of these layouts is active and off
    // otherwise, so the layout alone decides and nothing is toggled by hand.
    // `fcitx5-remote -o` and `-c` open and close the active input method; with
    // fcitx5 absent or not yet started they fail and nothing happens.
    readonly property var imeLayouts: ["CN"]

    readonly property bool wantsIme: root.imeLayouts.indexOf(root.code) >= 0

    onWantsImeChanged: root.syncIme()

    function syncIme(): void {
        Quickshell.execDetached(["fcitx5-remote", root.wantsIme ? "-o" : "-c"])
    }

    // fcitx5 starts beside the shell and may not be listening yet at login.
    readonly property Timer imeSettled: Timer {
        interval: 4000
        running: true
        onTriggered: root.syncIme()
    }

    // Layout and variant descriptions to their codes, from `evdev.lst`.
    property var codes: ({})

    function codeOf(layout: string): string {
        if (!layout)
            return "--"
        return (root.codes[layout] ?? layout.slice(0, 2)).toUpperCase()
    }

    // `! layout` rows are `  pl   Polish`; `! variant` rows are
    // `  legacy   pl: Polish (legacy)`. The first row for a description wins.
    function parseRules(text: string): void {
        const found = {}
        let section = ""
        for (const line of text.split("\n")) {
            if (line.startsWith("!")) {
                section = line.slice(1).trim()
                continue
            }
            let row = null
            if (section === "layout") {
                row = /^\s+(\S+)\s+(.+?)\s*$/.exec(line)
                if (row && !(row[2] in found))
                    found[row[2]] = row[1]
            } else if (section === "variant") {
                row = /^\s+\S+\s+(\S+):\s+(.+?)\s*$/.exec(line)
                if (row && !(row[2] in found))
                    found[row[2]] = row[1]
            }
        }
        root.codes = found
    }

    function read(text: string): void {
        let devices
        try {
            devices = JSON.parse(text)
        } catch (error) {
            console.warn("Cannot parse the keyboard list:", error)
            return
        }
        const keyboards = devices.keyboards ?? []
        const main = keyboards.find(keyboard => keyboard.main) ?? keyboards[0]
        if (!main)
            return
        root.layoutList = main.layout ?? ""
        root.name = main.active_keymap ?? ""
    }

    // Every keyboard, so one a key was pressed on is the one that is switched.
    function next(): void {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    readonly property Process rules: Process {
        command: ["cat", "/usr/share/X11/xkb/rules/evdev.lst"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseRules(text)
        }
    }

    readonly property Process query: Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.read(text)
        }
    }

    // One switch sends an event per keyboard, so a burst becomes one query.
    readonly property Connections events: Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "activelayout")
                root.refreshSoon.restart()
        }
    }

    readonly property Timer refreshSoon: Timer {
        interval: 60
        onTriggered: root.query.running = true
    }
}
