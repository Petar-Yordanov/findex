import QtQuick
import QtQuick.Controls

MenuSeparator {
    id: control

    property bool darkTheme: false

    implicitWidth: 220
    implicitHeight: 10
    padding: 0

    contentItem: Item {
        implicitWidth: 220
        implicitHeight: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: parent.width - 24
            height: 1
            color: control.darkTheme ? "#3a4352" : "#d9dde4"
        }
    }

    background: Item {}
}