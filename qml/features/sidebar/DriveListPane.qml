import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/theme" as Theme
import "../../shared/cards"

Rectangle {
    required property var rootWindow
    required property var drivesModel
    required property var sidebarContextMenu

    Layout.fillWidth: true
    Layout.preferredHeight: 20 + 22 + (drivesModel.count * 48) + Math.max(0, drivesModel.count - 1) * 1 + 20
    Layout.minimumHeight: 120
    radius: Theme.Metrics.radiusXl
    color: Theme.AppTheme.isDark ? "#171d27" : "#fbfcfd"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingLg
        spacing: 1

        Text {
            text: "Drives"
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.body
            font.bold: true
        }

        Repeater {
            model: drivesModel

            delegate: DriveCard {
                rootWindow: parent.parent.parent.rootWindow
                modelData: modelData
                sidebarContextMenu: parent.parent.parent.sidebarContextMenu
            }
        }
    }
}