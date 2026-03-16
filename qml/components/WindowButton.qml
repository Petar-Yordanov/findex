import QtQuick

Rectangle {
    id: control

    property bool darkTheme: false
    property bool hoverFxEnabled: true

    property string iconName: ""
    property color hoverColor: darkTheme ? "#2c3544" : "#dbe7fb"
    property color pressedColor: darkTheme ? "#39465b" : "#c9daf8"
    property color hoverBorderColor: darkTheme ? "#3b4659" : "#bfd0ef"

    signal clicked

    width: 42
    height: 28
    radius: 8

    color: mouse.pressed
           ? control.pressedColor
           : (control.hoverFxEnabled && mouse.containsMouse ? control.hoverColor : "transparent")

    border.color: control.hoverFxEnabled && mouse.containsMouse && !mouse.pressed
                  ? control.hoverBorderColor
                  : "transparent"
    border.width: control.hoverFxEnabled && mouse.containsMouse ? 1 : 0

    AppIcon {
        anchors.centerIn: parent
        name: control.iconName
        darkTheme: control.darkTheme
        iconSize: 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: control.hoverFxEnabled
        onClicked: control.clicked()
    }
}