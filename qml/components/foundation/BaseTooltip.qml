import QtQuick
import "../theme" as Theme

Item {
    id: root
    property string text: ""
    property bool darkTheme: Theme.AppTheme.isDark
    property bool shown: false
    property int offsetY: 8
    property int maxWidth: 260

    visible: opacity > 0
    opacity: shown && text !== "" ? 1 : 0
    z: 10000
    clip: false

    width: bubble.width
    height: bubble.height + 6

    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: (parent ? parent.height : 0) + offsetY

    Behavior on opacity {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: shadow
        anchors.fill: bubble
        anchors.topMargin: 2
        radius: bubble.radius
        color: "#000000"
        opacity: root.darkTheme ? 0.22 : 0.10
        z: -2
    }

    Rectangle {
        id: arrow
        width: 10
        height: 10
        rotation: 45
        anchors.horizontalCenter: bubble.horizontalCenter
        anchors.bottom: bubble.top
        anchors.bottomMargin: -5
        color: bubble.color
        border.color: bubble.border.color
        border.width: 1
        z: -1
    }

    Rectangle {
        id: bubble
        width: Math.min(root.maxWidth, tooltipText.implicitWidth + 18)
        height: tooltipText.implicitHeight + 12
        radius: 8
        color: root.darkTheme ? "#202938" : "#ffffff"
        border.color: root.darkTheme ? "#3a465c" : "#d7deea"
        border.width: 1

        Text {
            id: tooltipText
            anchors.fill: parent
            anchors.margins: 6
            text: root.text
            color: root.darkTheme ? "#f3f6fb" : "#1f2937"
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }
}