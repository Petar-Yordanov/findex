import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels as Labs
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    required property var rootWindow
    required property var sidebarModel
    required property var sidebarContextMenu

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Theme.Metrics.radiusLg
    color: "transparent"

    TreeView {
        id: sidebarTree
        anchors.fill: parent
        model: sidebarModel
        clip: true
        alternatingRows: false
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width

        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
        ScrollBar.horizontal: null

        delegate: SidebarItem {
            rootWindow: parent.rootWindow
            sidebarContextMenu: parent.sidebarContextMenu
        }

        Component.onCompleted: expand(0)
    }
}