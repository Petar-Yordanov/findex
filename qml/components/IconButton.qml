import QtQuick
import QtQuick.Controls

Rectangle {
    id: control

    property string iconName: ""
    property string tooltipText: ""
    property bool darkTheme: false

    width: 32
    height: 32
    radius: 8
    color: mouseArea.pressed
           ? (darkTheme ? "#2c3646" : "#dde4ee")
           : mouseArea.containsMouse
             ? (darkTheme ? "#212835" : "#e9edf3")
             : "transparent"

    signal clicked()

    AppIcon {
        anchors.centerIn: parent
        name: control.iconName
        darkTheme: control.darkTheme
        iconSize: 18
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: control.clicked()
    }
}