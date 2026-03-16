import QtQuick
import QtQuick.Controls

MenuItem {
    id: control

    property bool darkTheme: false

    implicitWidth: 220
    implicitHeight: 40
    leftPadding: 14
    rightPadding: 14
    topPadding: 0
    bottomPadding: 0

    arrow: Item {
        implicitWidth: control.subMenu ? 18 : 0
        implicitHeight: 18

        AppIcon {
            anchors.centerIn: parent
            visible: control.subMenu !== null
            name: "chevron-right"
            darkTheme: control.darkTheme
            iconSize: 14
            iconOpacity: control.enabled ? 0.8 : 0.4
        }
    }

    indicator: Item {
        implicitWidth: 0
        implicitHeight: 0
    }

    contentItem: Text {
        text: control.text
        color: control.enabled
               ? (control.darkTheme ? "#edf1f7" : "#1f2329")
               : (control.darkTheme ? "#6f7b8c" : "#9aa3af")
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 10
        color: !control.enabled
               ? "transparent"
               : control.highlighted
                 ? (control.darkTheme ? "#2a3444" : "#dfe9f8")
                 : "transparent"

        border.color: control.highlighted
                      ? (control.darkTheme ? "#4a5a72" : "#b7caf0")
                      : "transparent"
        border.width: control.highlighted ? 1 : 0
    }
}