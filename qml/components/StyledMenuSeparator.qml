import QtQuick
import QtQuick.Controls

MenuSeparator {
    id: control

    property bool darkTheme: false

    implicitWidth: 220
    implicitHeight: 12

    contentItem: Rectangle {
        x: 10
        y: Math.round((parent.height - height) / 2)
        width: parent.width - 20
        height: 1
        color: control.darkTheme ? "#2b3442" : "#e4e7ec"
    }

    background: Item {}
}