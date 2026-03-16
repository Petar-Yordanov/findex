import QtQuick
import QtQuick.Controls

Menu {
    id: control

    property bool darkTheme: false

    implicitWidth: Math.max(220, contentItem ? contentItem.implicitWidth + leftPadding + rightPadding : 220)
    leftPadding: 8
    rightPadding: 8
    topPadding: 8
    bottomPadding: 8
    overlap: 2

    background: Rectangle {
        radius: 12
        color: control.darkTheme ? "#1b2230" : "#ffffff"
        border.color: control.darkTheme ? "#252b36" : "#d7dbe1"
        border.width: 1
    }

    delegate: StyledMenuItem {
        darkTheme: control.darkTheme
    }
}