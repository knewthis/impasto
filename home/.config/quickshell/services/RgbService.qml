// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   R G B   S E R V I C E                                                  │
// │   the accent on the keyboard, mouse, memory and case, through OpenRGB    │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell

import "../theme"

// Sends the accent to every device OpenRGB drives whenever it changes: a new
// wallpaper, a palette switch, the cycle timer. Off by default, and a setting
// of the machine, since the hardware is.
//
// Each call is `openrgb --color RRGGBB --mode static`. With `openrgb --server`
// running (started at login) the call is a client of it and returns at once;
// without one, openrgb scans the devices every time, which takes seconds.
Singleton {
    id: root

    readonly property bool enabled: SettingsService.rgbSync

    // `rrggbb`, no hash, as openrgb takes it.
    readonly property string hex: {
        const channel = value => Math.round(value * 255).toString(16).padStart(2, "0")
        return channel(Theme.accent.r) + channel(Theme.accent.g) + channel(Theme.accent.b)
    }

    onHexChanged: root.settle.restart()
    onEnabledChanged: root.settle.restart()

    // A palette change moves the accent through several values in a moment;
    // only the last one is worth sending.
    readonly property Timer settle: Timer {
        interval: 800
        onTriggered: {
            if (root.enabled)
                root.apply()
        }
    }

    function apply(): void {
        Quickshell.execDetached(["openrgb", "--color", root.hex, "--mode", "static"])
    }
}
