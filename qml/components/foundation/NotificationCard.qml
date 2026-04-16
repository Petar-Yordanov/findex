import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark

    property int notificationId: -1
    property string title: ""
    property string details: ""
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

    width: 340
    implicitHeight: contentColumn.implicitHeight + Theme.Metrics.spacingXl * 2
    radius: Theme.Metrics.radiusXl
    color: control.bgColor
    border.color: control.borderColor
    border.width: Theme.Metrics.borderWidth

    Timer {
        id: closeTimer
        interval: 5000
        repeat: false
        onTriggered: control.closeRequested(control.notificationId)
    }

    Component.onCompleted: {
        if (control.autoClose && control.progress < 0)
            closeTimer.start()
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingMd

        Row {
            width: parent.width
            spacing: Theme.Metrics.spacingMd

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
                width: Math.max(0, parent.width - 54)
                text: control.title
                color: control.textColor
                font.pixelSize: Theme.Typography.bodyLg
                font.bold: true
                wrapMode: Text.Wrap
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

        Text {
            visible: control.details !== ""
            width: parent.width
            text: control.details
            color: control.mutedColor
            font.pixelSize: Theme.Typography.caption
            wrapMode: Text.Wrap
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
            visible: control.progress >= 0 && control.details === ""
            text: control.done ? "Completed" : (control.progress + "%")
            color: control.mutedColor
            font.pixelSize: Theme.Typography.caption
        }
    }
}