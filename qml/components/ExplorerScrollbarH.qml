import QtQuick
import QtQuick.Controls

ScrollBar {
    id: control

    property bool darkTheme: false
    property color thumbColor: darkTheme ? "#8f98a7" : "#b8c0cb"
    property color thumbHoverColor: darkTheme ? "#a0a9b8" : "#9ea8b6"
    property color thumbPressedColor: darkTheme ? "#b0b8c6" : "#8d98a8"
    property color trackColor: darkTheme ? "transparent" : "#eef1f5"

    orientation: Qt.Horizontal
    height: 10
    policy: ScrollBar.AsNeeded

    contentItem: Rectangle {
        implicitHeight: 6
        radius: 3
        color: control.pressed ? control.thumbPressedColor
                               : control.hovered ? control.thumbHoverColor
                                                 : control.thumbColor
        opacity: control.darkTheme ? (control.active ? 0.95 : 0.75)
                                   : (control.active ? 0.9 : 0.8)
    }

    background: Rectangle {
        radius: 3
        color: control.trackColor
        opacity: control.darkTheme ? 0.0 : 1.0
    }
}