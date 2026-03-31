import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "../../components/theme" as Theme
import "../layout" as AppLayout
import "../topbar" as TopBar
import "../titlebar" as TitleBar

Rectangle {
    id: shell

    required property var rootWindow
    required property var sidebarViewModel
    required property var sidebarContextMenu
    required property var navigationViewModel
    required property var commandBarViewModel
    required property var tabsViewModel
    required property var workspaceViewModel
    required property var tabContextMenu
    required property var breadcrumbContextMenu
    required property var createMenu
    required property var moreActionsMenu
    required property var viewModeMenu
    required property var themeMenu
    required property var previewViewModel
    required property var statusBarViewModel
    required property var notificationsPopup

    radius: rootWindow.visibility === Window.Maximized ? 0 : 14
    color: Theme.AppTheme.bg
    border.color: rootWindow.visibility === Window.Maximized ? "transparent" : Theme.AppTheme.border
    border.width: rootWindow.visibility === Window.Maximized ? 0 : 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar.AppTitleBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            rootWindow: shell.rootWindow
            viewModel: shell.tabsViewModel
            tabContextMenu: shell.tabContextMenu
        }

        TopBar.NavigationBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            viewModel: shell.navigationViewModel
            breadcrumbContextMenu: shell.breadcrumbContextMenu
        }

        TopBar.CommandBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            rootWindow: shell.rootWindow
            viewModel: shell.commandBarViewModel
            createMenu: shell.createMenu
            moreActionsMenu: shell.moreActionsMenu
            viewModeMenu: shell.viewModeMenu
            themeMenu: shell.themeMenu
            previewPaneViewModel: shell.previewViewModel
        }

        AppLayout.SplitWorkspace {
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
}