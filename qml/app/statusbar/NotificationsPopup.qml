import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

StyledMenu {
    id: popup

    required property var viewModel
    darkTheme: Theme.AppTheme.isDark
    menuWidth: 380

    Item {
        width: parent ? parent.width : 380
        implicitHeight: notificationsContainer.implicitHeight

        Column {
            id: notificationsContainer
            width: parent.width
            spacing: Theme.Metrics.spacingSm

            Text {
                width: parent.width
                text: "Notifications"
                color: Theme.AppTheme.text
                font.pixelSize: Theme.Typography.bodyLg
                font.bold: true
            }

            Rectangle {
                visible: !popup.viewModel || popup.viewModel.notificationCount <= 0
                width: parent.width
                implicitHeight: emptyText.implicitHeight + Theme.Metrics.spacingXl * 2
                radius: Theme.Metrics.radiusLg
                color: Theme.AppTheme.popupAltBg
                border.color: Theme.AppTheme.borderSoft
                border.width: Theme.Metrics.borderWidth

                Text {
                    id: emptyText
                    anchors.centerIn: parent
                    text: "No notifications yet"
                    color: Theme.AppTheme.muted
                    font.pixelSize: Theme.Typography.body
                }
            }

            Repeater {
                model: popup.viewModel ? popup.viewModel.notifications : []

                delegate: NotificationCard {
                    required property var modelData

                    width: notificationsContainer.width
                    darkTheme: Theme.AppTheme.isDark

                    notificationId: modelData.id
                    title: modelData.title || ""
                    kind: modelData.kind || "info"
                    progress: modelData.progress === undefined ? -1 : modelData.progress
                    autoClose: false
                    done: !!modelData.done

                    onCloseRequested: function(id) {
                        if (popup.viewModel)
                            popup.viewModel.dismissNotification(id)
                    }
                }
            }
        }
    }
}