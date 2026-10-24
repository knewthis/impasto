// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L A T E X   I M A G E   S E R V I C E                                  │
// │   the launcher's `~` mode · a live preview, and the image to copy        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../theme"

// Renders what is typed after the sigil through `scripts/latex.py`, a moment
// after the last key, and keeps the picture to show under the field. One render
// runs at a time: a key typed meanwhile is rendered when it finishes, so the
// preview trails the typing by one pass instead of queueing every keystroke.
Singleton {
    id: root

    readonly property bool active: LauncherService.modeFor(LauncherService.query).id === "tex"
    readonly property string source: root.active
        ? LauncherService.termFor(LauncherService.query) : ""

    // The preview is drawn in the panel's text colour.
    readonly property string ink:
        `${Theme.text.r.toFixed(3)},${Theme.text.g.toFixed(3)},${Theme.text.b.toFixed(3)}`

    // `{ ok, error?, missing? }` of the last render, and its picture.
    property string image: ""
    property string error: ""
    property bool missing: false
    property bool busy: false

    readonly property string directory: `${SettingsService.stateDirectory}/latex`
    property int serial: 0
    property string pending: ""
    property string rendering: ""

    onSourceChanged: {
        if (root.source === "") {
            debounce.stop()
            root.image = ""
            root.error = ""
            return
        }
        debounce.restart()
    }
    onInkChanged: if (root.source !== "") debounce.restart()

    readonly property Timer debounce: Timer {
        interval: 350
        onTriggered: root.render()
    }

    function render(): void {
        if (root.source === "")
            return
        if (root.job.running) {
            root.pending = root.source
            return
        }
        root.rendering = root.source
        root.pending = ""
        root.busy = true
        root.serial += 1
        // A new name each time: the Image would keep showing the old file.
        root.job.out = `${root.directory}/preview-${root.serial % 2}.png`
        root.job.command = [Quickshell.shellPath("scripts/latex.py"), "render",
            "--out", root.job.out, "--fg", root.ink, "--dpi", "220", root.rendering]
        root.job.running = true
    }

    readonly property Process job: Process {
        property string out: ""

        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false
                try {
                    const result = JSON.parse(text)
                    root.missing = result.missing === true
                    if (result.ok) {
                        root.error = ""
                        root.image = `file://${root.job.out}?${root.serial}`
                    } else {
                        root.error = result.error ?? "TeX could not set that"
                    }
                } catch (failure) {
                    root.error = "The renderer gave no answer"
                }
                if (root.pending !== "" && root.pending !== root.rendering)
                    root.render()
            }
        }
    }

    // Black on white, with a margin, onto the clipboard. Detached so it
    // outlives the launcher closing.
    function copy(source: string): void {
        Quickshell.execDetached([Quickshell.shellPath("scripts/latex.py"), "copy", source])
    }
}
