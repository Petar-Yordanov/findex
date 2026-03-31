import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root

    required property var viewModel
    required property var sidebarContextMenu

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Theme.Metrics.radiusLg
    color: Theme.AppTheme.isDark ? "#131923" : "#f8fafc"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth
    clip: true

    TreeView {
        id: sidebarTree
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingSm

        model: root.viewModel ? root.viewModel.treeModel : null
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

        Component.onCompleted: {
            if (model && model.rowCount() > 0)
                expand(0)
        }
    }
}