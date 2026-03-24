import QtQuick
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    required property var rootWindow

    x: -10000
    y: -10000
    width: Math.min(260, previewContent.implicitWidth + 20)
    height: 42
    visible: true
    opacity: 0.01

    Rectangle {
        anchors.fill: parent
        radius: Theme.Metrics.radiusLg
        color: Theme.AppTheme.popupBg
        border.color: Theme.AppTheme.border
        border.width: Theme.Metrics.borderWidth
    }

    Row {
        id: previewContent
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.Metrics.spacingLg
        spacing: Theme.Metrics.spacingMd

        AppIcon {
            name: rootWindow.draggedFileIcon !== "" ? rootWindow.draggedFileIcon : "insert-drive-file"
            darkTheme: Theme.AppTheme.isDark
            iconSize: Theme.Metrics.icon2xl
        }

        Text {
            text: rootWindow.draggedFileCount > 1
                  ? (rootWindow.draggedFileCount + " items")
                  : rootWindow.draggedFileName
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.bodyLg
            font.bold: true
            elide: Text.ElideRight
            width: 210
            verticalAlignment: Text.AlignVCenter
        }
    }
}