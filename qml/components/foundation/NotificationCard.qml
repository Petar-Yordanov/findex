import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    property int notificationId: -1
    property string title: ""
    property string kind: "info"
    property int progress: -1
    property bool autoClose: false
    property bool done: false

    property color bgColor: Theme.AppTheme.popupBg
    property color borderColor: Theme.AppTheme.border
    property color textColor: Theme.AppTheme.text
    property color mutedColor: Theme.AppTheme.muted
    property color hoverColor: Theme.AppTheme.hover
    property color accentColor: Theme.AppTheme.accent
    property color successColor: Theme.AppTheme.success
    property color trackColor: Theme.AppTheme.driveFree

    signal closeRequested(int notificationId)

    width: 320
    height: progress >= 0 ? 84 : 58
    radius: Theme.Metrics.radiusXl
    color: control.bgColor
    border.color: control.borderColor
    border.width: Theme.Metrics.borderWidth

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
                iconSize: Theme.Metrics.iconMd
            }

            Text {
                width: parent.width - 40
                text: control.title
                color: control.textColor
                font.pixelSize: Theme.Typography.bodyLg
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
                    iconSize: Theme.Metrics.iconXs
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
            font.pixelSize: Theme.Typography.caption
        }
    }
}