import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "../../components/theme" as Theme
import "../headers"

Rectangle {
    id: shell
    anchors.fill: parent

    required property var rootWindow
    required property var tabsModel
    required property var pathModel
    required property var sidebarModel
    required property var drivesModel
    required property var filesModel

    required property var createMenu
    required property var moreActionsMenu
    required property var viewModeMenu
    required property var themeMenu
    required property var searchScopeMenu
    required property var breadcrumbContextMenu
    required property var fileRowContextMenu
    required property var multiFileContextMenu
    required property var emptyAreaContextMenu
    required property var sidebarContextMenu
    required property var notificationsPopup
    required property var notificationsModel

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
            tabsModel: shell.tabsModel
        }

        NavigationBar {
            id: navigationBar
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            rootWindow: shell.rootWindow
            pathModel: shell.pathModel
            searchScopeMenu: shell.searchScopeMenu
            breadcrumbContextMenu: shell.breadcrumbContextMenu
        }

        CommandBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            rootWindow: shell.rootWindow
            createMenu: shell.createMenu
            moreActionsMenu: shell.moreActionsMenu
            viewModeMenu: shell.viewModeMenu
            themeMenu: shell.themeMenu
        }

        SplitWorkspace {
            Layout.fillWidth: true
            Layout.fillHeight: true

            rootWindow: shell.rootWindow
            sidebarModel: shell.sidebarModel
            drivesModel: shell.drivesModel
            filesModel: shell.filesModel

            fileRowContextMenu: shell.fileRowContextMenu
            multiFileContextMenu: shell.multiFileContextMenu
            emptyAreaContextMenu: shell.emptyAreaContextMenu
            sidebarContextMenu: shell.sidebarContextMenu
            viewModeMenu: shell.viewModeMenu
            notificationsPopup: shell.notificationsPopup
            notificationsModel: shell.notificationsModel
        }
    }
}