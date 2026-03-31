import QtQuick
import QtQuick.Controls.Basic

ScrollBar {
    id: control

    orientation: Qt.Vertical
    policy: ScrollBar.AsNeeded
    width: 10
    minimumSize: 0.08

    contentItem: Rectangle {
        implicitWidth: 6
        radius: width / 2
        color: control.pressed
               ? "#7a7a7a"
               : control.hovered
                 ? "#8a8a8a"
                 : "#9a9a9a"
    }

    background: Rectangle {
        implicitWidth: 10
        radius: width / 2
        color: "#22000000"
    }
}