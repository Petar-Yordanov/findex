import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root

    required property var viewModel
    required property var sidebarContextMenu

    visible: Qt.platform.os === "windows"
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Theme.Metrics.radiusLg
    color: Theme.AppTheme.isDark ? "#131923" : "#f8fafc"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingSm
        spacing: Theme.Metrics.spacingSm

        Text {
            text: "WSL"
            color: Theme.AppTheme.muted
            font.pixelSize: 11
            font.bold: true
            Layout.leftMargin: Theme.Metrics.spacingSm
            Layout.rightMargin: Theme.Metrics.spacingSm
            Layout.topMargin: Theme.Metrics.spacingXs
        }

        TreeView {
            id: sidebarTree
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: root.viewModel ? root.viewModel.wslModel : null
            clip: true
            alternatingRows: false
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            contentWidth: availableWidth

            readonly property real availableWidth: Math.max(
                0,
                width - (verticalScrollBar.visible ? verticalScrollBar.width + 4 : 0)
            )

            columnWidthProvider: function(column) {
                return sidebarTree.availableWidth
            }

            ScrollBar.vertical: ExplorerScrollbarV {
                id: verticalScrollBar
            }

            ScrollBar.horizontal: null

            delegate: SidebarItem {
                viewModel: root.viewModel
                sidebarContextMenu: root.sidebarContextMenu
            }
        }
    }
}