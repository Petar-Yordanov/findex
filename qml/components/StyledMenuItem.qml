import QtQuick
import QtQuick.Controls

MenuItem {
    id: control

    property bool darkTheme: false

    implicitWidth: 220
    implicitHeight: 40

    leftPadding: 16
    rightPadding: control.subMenu ? 36 : 16
    topPadding: 0
    bottomPadding: 0

    indicator: null

    arrow: Item {
        visible: control.subMenu !== null
        width: visible ? 14 : 0
        height: control.height
        x: control.width - width - 16
        y: 0

        AppIcon {
            anchors.centerIn: parent
            name: "chevron-right"
            darkTheme: control.darkTheme
            iconSize: 14
            iconOpacity: control.enabled ? 0.8 : 0.45
        }
    }

    contentItem: Text {
        text: control.text
        color: control.enabled
               ? (control.darkTheme ? "#edf1f7" : "#1f2329")
               : (control.darkTheme ? "#7f8ba0" : "#98a1ae")
        font.pixelSize: 13
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        x: 6
        y: 4
        width: control.width - 12
        height: control.height - 8
        radius: 6

        color: control.highlighted
               ? (control.darkTheme ? "#253041" : "#dfe9f8")
               : "transparent"

        border.color: control.highlighted
                      ? (control.darkTheme ? "#334155" : "#c7d7ee")
                      : "transparent"
        border.width: control.highlighted ? 1 : 0
    }
}