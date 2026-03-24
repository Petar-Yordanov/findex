import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: root
    anchors.fill: parent

    required property var rootWindow
    required property var toastsModel

    function removeToast(toastId) {
        for (var i = 0; i < toastsModel.count; ++i) {
            if (toastsModel.get(i).toastId === toastId) {
                toastsModel.remove(i)
                return
            }
        }
    }

    Column {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: root.rootWindow.notificationOverlayBottomOffset
        spacing: Theme.Metrics.spacingMd

        Repeater {
            model: root.toastsModel

            delegate: Rectangle {
                required property var modelData

                width: 320
                height: 42
                radius: Theme.Metrics.radiusLg
                color: Theme.AppTheme.popupBg
                border.color: Theme.AppTheme.border
                border.width: Theme.Metrics.borderWidth

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.Metrics.spacingLg
                    anchors.rightMargin: Theme.Metrics.spacingMd
                    spacing: Theme.Metrics.spacingMd

                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: modelData.kind === "success"
                              ? "check"
                              : modelData.kind === "error"
                                ? "error"
                                : "info"
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: Theme.Metrics.iconMd
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 240
                        text: modelData.title || ""
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: closeMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

                        AppIcon {
                            anchors.centerIn: parent
                            name: "close"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: Theme.Metrics.iconXs
                            iconOpacity: 0.75
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.removeToast(modelData.toastId)
                        }
                    }
                }

                Timer {
                    interval: modelData.duration || 5000
                    repeat: false
                    running: true
                    onTriggered: root.removeToast(modelData.toastId)
                }
            }
        }
    }
}