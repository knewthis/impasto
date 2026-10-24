// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   K E Y B O A R D   M O D U L E                                          │
// │   keyboard layout · the active one, a button for the next                │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts

import "../../theme"
import "../../services"
import "../../components"

// No ring: a layout has nothing to fill, so the chip is the symbol and the
// layout's code, drawn like the network's (`ModuleService.glyphOf`, `valueOf`).
// The detail names the layout in full and moves to the next one.
Item {
    id: root

    implicitWidth: holder.implicitWidth
    implicitHeight: holder.implicitHeight

    Loader {
        id: holder
        anchors.fill: parent
        sourceComponent: detail
    }

    Component {
        id: detail

        ModuleCard {
            title: KeyboardService.name || "Keyboard"
            subtitle: "Layout"
            figure: KeyboardService.code

            mark: Text {
                anchors.centerIn: parent
                text: KeyboardService.icon
                font.family: Theme.fontMono
                font.pixelSize: 18
                color: Theme.indicator
            }

            CardFact {
                name: "Layouts"
                value: KeyboardService.layoutList.replace(/,/g, " · ")
            }

            PillButton {
                Layout.fillWidth: true
                text: "Next layout"
                icon: KeyboardService.icon
                implicitHeight: Theme.cardRow
                onClicked: KeyboardService.next()
            }
        }
    }
}
