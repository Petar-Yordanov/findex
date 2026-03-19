import QtQuick
import "../theme" as Theme

Rectangle {
    id: control

    property string iconName: ""
    property string tooltipText: ""
    property bool darkTheme: Theme.AppTheme.isDark
    property color hoverColor: Theme.AppTheme.hover
    property color pressedColor: Theme.AppTheme.pressed
    property int iconSize: Theme.Metrics.iconLg
    property int tooltipDelay: 450

    width: 32
    height: 32
    radius: Theme.Metrics.radiusMd
    clip: false

    color: mouseArea.pressed
           ? control.pressedColor
           : mouseArea.containsMouse
             ? control.hoverColor
             : "transparent"

    signal clicked()

    AppIcon {
        anchors.centerIn: parent
        name: control.iconName
        darkTheme: control.darkTheme
        iconSize: control.iconSize
    }

    Timer {
        id: tooltipTimer
        interval: control.tooltipDelay
        repeat: false

        onTriggered: {
            if (mouseArea.containsMouse && control.tooltipText !== "")
                tooltipBubble.opacity = 1
        }
    }

    Rectangle {
        id: tooltipBubble
        visible: opacity > 0
        opacity: 0
        z: 9999

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 8

        width: Math.min(240, tooltipLabel.implicitWidth + 16)
        height: tooltipLabel.implicitHeight + 10
        radius: 8

        color: control.darkTheme ? "#202632" : "#ffffff"
        border.color: control.darkTheme ? "#3a4456" : "#d7deea"
        border.width: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: tooltipLabel
            anchors.centerIn: parent
            text: control.tooltipText
            color: control.darkTheme ? "#f3f6fb" : "#1f2937"
            font.pixelSize: 11
            font.bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if (control.tooltipText !== "")
                tooltipTimer.restart()
        }

        onExited: {
            tooltipTimer.stop()
            tooltipBubble.opacity = 0
        }

        onPressed: {
            tooltipTimer.stop()
            tooltipBubble.opacity = 0
        }

        onCanceled: {
            tooltipTimer.stop()
            tooltipBubble.opacity = 0
        }

        onClicked: control.clicked()
    }
}