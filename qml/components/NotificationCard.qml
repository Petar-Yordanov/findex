import QtQuick
import QtQuick.Layouts

Rectangle {
    id: control

    property bool darkTheme: false

    property int notificationId: -1
    property string title: ""
    property string kind: "info"
    property int progress: -1
    property bool autoClose: false
    property bool done: false

    property color bgColor: darkTheme ? "#1b2230" : "#ffffff"
    property color borderColor: darkTheme ? "#252b36" : "#d7dbe1"
    property color textColor: darkTheme ? "#edf1f7" : "#1f2329"
    property color mutedColor: darkTheme ? "#9aa4b2" : "#6b7280"
    property color hoverColor: darkTheme ? "#212835" : "#e9edf3"
    property color accentColor: "#4c82f7"
    property color successColor: "#3f73f1"
    property color trackColor: darkTheme ? "#4b5563" : "#d4d8de"

    signal closeRequested(int notificationId)

    width: 320
    height: progress >= 0 ? 84 : 58
    radius: 12
    color: control.bgColor
    border.color: control.borderColor
    border.width: 1

    function restartTimer() {
        if (autoClose)
            closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 2600
        repeat: false
        onTriggered: control.closeRequested(control.notificationId)
    }

    Component.onCompleted: {
        if (control.autoClose)
            closeTimer.start()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Row {
            width: parent.width
            spacing: 8

            AppIcon {
                name: control.kind === "success"
                      ? "check"
                      : control.kind === "error"
                        ? "close"
                        : control.kind === "warning"
                          ? "error"
                          : control.kind === "progress"
                            ? "sync"
                            : "info"
                darkTheme: control.darkTheme
                iconSize: 16
            }

            Text {
                width: parent.width - 40
                text: control.title
                color: control.textColor
                font.pixelSize: 13
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: control.progress >= 0 ? 2 : 1
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: closeToastMouse.containsMouse ? control.hoverColor : "transparent"

                AppIcon {
                    anchors.centerIn: parent
                    name: "close"
                    darkTheme: control.darkTheme
                    iconSize: 12
                }

                MouseArea {
                    id: closeToastMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: control.closeRequested(control.notificationId)
                }
            }
        }

        ThinProgressBar {
            visible: control.progress >= 0
            width: parent.width
            height: 6
            value: Math.max(0, Math.min(1, control.progress / 100))
            trackColor: control.trackColor
            fillColor: control.done ? control.successColor : control.accentColor
        }

        Text {
            visible: control.progress >= 0
            text: control.done ? "Completed" : (control.progress + "%")
            color: control.mutedColor
            font.pixelSize: 11
        }
    }
}