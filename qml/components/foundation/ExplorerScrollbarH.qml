import QtQuick
import QtQuick.Controls.Basic

ScrollBar {
    id: control

    orientation: Qt.Horizontal
    policy: ScrollBar.AsNeeded
    height: 10
    minimumSize: 0.08

    contentItem: Rectangle {
        implicitHeight: 6
        radius: height / 2
        color: control.pressed
               ? "#7a7a7a"
               : control.hovered
                 ? "#8a8a8a"
                 : "#9a9a9a"
    }

    background: Rectangle {
        implicitHeight: 10
        radius: height / 2
        color: "#22000000"
    }
}