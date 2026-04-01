import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "../../components/theme" as Theme
import "../../components/foundation"
import "../titlebar"
import "../topbar"

Rectangle {
    id: shell
    anchors.fill: parent

    required property var rootWindow

    required property var sidebarViewModel
    required property var navigationViewModel
    required property var commandBarViewModel
    required property var tabsViewModel
    required property var workspaceViewModel
    required property var previewViewModel
    required property var statusBarViewModel

    required property var sidebarContextMenu
    required property var tabContextMenu
    required property var breadcrumbContextMenu
    required property var createMenu
    required property var moreActionsMenu
    required property var viewModeMenu
    required property var themeMenu
    required property var notificationsPopup

    readonly property alias navigationBarRef: navigationBar
    readonly property alias titleBarRef: titleBar

    radius: (rootWindow.visibility === Window.Maximized || rootWindow.windowMoveActive) ? 0 : 14
    color: Theme.AppTheme.bg
    border.color: (rootWindow.visibility === Window.Maximized || rootWindow.windowMoveActive)
        ? "transparent"
        : Theme.AppTheme.border
    border.width: (rootWindow.visibility === Window.Maximized || rootWindow.windowMoveActive) ? 0 : 1
    clip: !rootWindow.windowMoveActive

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        AppTitleBar {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            rootWindow: shell.rootWindow
            viewModel: shell.tabsViewModel
            tabContextMenu: shell.tabContextMenu
        }

        NavigationBar {
            id: navigationBar
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            rootWindow: shell.rootWindow
            viewModel: shell.navigationViewModel
            breadcrumbContextMenu: shell.breadcrumbContextMenu
        }

        CommandBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            rootWindow: shell.rootWindow
            viewModel: shell.commandBarViewModel
            createMenu: shell.createMenu
            moreActionsMenu: shell.moreActionsMenu
            viewModeMenu: shell.viewModeMenu
            themeMenu: shell.themeMenu
            previewViewModel: shell.previewViewModel
        }

        SplitWorkspace {
            Layout.fillWidth: true
            Layout.fillHeight: true

            rootWindow: shell.rootWindow
            sidebarViewModel: shell.sidebarViewModel
            sidebarContextMenu: shell.sidebarContextMenu
            workspaceViewModel: shell.workspaceViewModel
            previewViewModel: shell.previewViewModel
            statusBarViewModel: shell.statusBarViewModel
            notificationsPopup: shell.notificationsPopup
        }
    }

    Item {
        id: dragOverlayLayer
        anchors.fill: parent
        z: 50000
        visible: shell.workspaceViewModel && shell.workspaceViewModel.dragPreviewVisible
        enabled: false

        Rectangle {
            id: dragBadge
            visible: dragOverlayLayer.visible

            property real edgePadding: 8
            property real iconAnchorX: 18
            property real iconAnchorY: height / 2

            x: {
                const cursorX = shell.workspaceViewModel ? shell.workspaceViewModel.dragPreviewX : 0
                const rawX = cursorX - iconAnchorX
                return Math.max(edgePadding, Math.min(rawX, dragOverlayLayer.width - width - edgePadding))
            }

            y: {
                const cursorY = shell.workspaceViewModel ? shell.workspaceViewModel.dragPreviewY : 0
                const rawY = cursorY - iconAnchorY
                return Math.max(edgePadding, Math.min(rawY, dragOverlayLayer.height - height - edgePadding))
            }

            radius: 8
            color: Theme.AppTheme.popupBg
            border.color: Theme.AppTheme.accent
            border.width: Theme.Metrics.borderWidth
            width: Math.min(260, dragRow.implicitWidth + 16)
            height: 34
            opacity: 0.98

            Row {
                id: dragRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 8

                AppIcon {
                    name: shell.workspaceViewModel ? shell.workspaceViewModel.dragPreviewIcon : "insert-drive-file"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: shell.workspaceViewModel ? shell.workspaceViewModel.dragPreviewText : ""
                    color: Theme.AppTheme.text
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    width: 220
                }
            }
        }
    }
}