import QtQuick
import QtQuick.Controls

TextField {
    id: control

    property bool darkTheme: false
    property color textColor: darkTheme ? "#edf1f7" : "#1f2329"
    property color bgColor: darkTheme ? "#1b2230" : "#ffffff"
    property color accentColor: "#4c82f7"

    selectByMouse: true
    color: textColor
    topPadding: 0
    bottomPadding: 0

    background: Rectangle {
        radius: 6
        color: control.bgColor
        border.color: control.accentColor
        border.width: 1
    }

    Keys.onEscapePressed: control.focus = false
}