import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Popup {
    required property var rootWindow
    required property var notificationsModel

    width: 340
    height: 320
    padding: Theme.Metrics.spacingMd
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        implicitWidth: parent.width
        implicitHeight: parent.height
        radius: Theme.Metrics.radiusXl
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    Column {
        anchors.fill: parent
        spacing: Theme.Metrics.spacingMd

        Text {
            text: "Notifications"
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.bodyLg
            font.bold: true
            leftPadding: Theme.Metrics.spacingXs
        }

        Flickable {
            width: parent.width
            height: parent.height - 28
            contentWidth: width
            contentHeight: trayColumn.height
            clip: true

            Column {
                id: trayColumn
                width: parent.width
                spacing: Theme.Metrics.spacingMd

                Repeater {
                    model: notificationsModel

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: modelData.progress >= 0 ? 78 : 54
                        radius: Theme.Metrics.radiusLg
                        color: Theme.AppTheme.popupBg
                        border.color: Theme.AppTheme.borderSoft
                        border.width: Theme.Metrics.borderWidth

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.Metrics.spacingLg
                            spacing: Theme.Metrics.spacingSm

                            Row {
                                width: parent.width
                                spacing: Theme.Metrics.spacingMd

                                Text {
                                    width: parent.width - 30
                                    text: modelData.title
                                    color: Theme.AppTheme.text
                                    font.pixelSize: Theme.Typography.body
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: Theme.Metrics.radiusLg
                                    color: trayCloseMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

                                    AppIcon {
                                        anchors.centerIn: parent
                                        name: "close"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                        iconOpacity: 0.75
                                    }

                                    MouseArea {
                                        id: trayCloseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: rootWindow.removeNotification(modelData.notificationId)
                                    }
                                }
                            }

                            Rectangle {
                                visible: modelData.progress >= 0
                                width: parent.width
                                height: 6
                                radius: Theme.Metrics.radiusXs
                                color: Theme.AppTheme.driveFree

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, modelData.progress / 100))
                                    height: parent.height
                                    radius: Theme.Metrics.radiusXs
                                    color: modelData.done ? Theme.AppTheme.driveUsedBlue : Theme.AppTheme.accent
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}