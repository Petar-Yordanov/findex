import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme
import "../menus"
import "../popups"
import "../dialogs"
import "../../features/files"
import "../../features/breadcrumb"
import "../../features/sidebar"
import "../../features/tabs"

Item {
    id: root
    anchors.fill: parent

    required property var rootWindow
    required property var notificationsModel

    property alias createMenu: createMenu
    property alias moreActionsMenu: moreActionsMenu
    property alias confirmDialog: confirmDialog
    property alias notificationsPopup: notificationsPopup
    property alias searchScopeMenu: searchScopeMenu
    property alias breadcrumbContextMenu: breadcrumbContextMenu
    property alias emptyAreaContextMenu: emptyAreaContextMenu
    property alias tabContextMenu: tabContextMenu
    property alias sidebarContextMenu: sidebarContextMenu
    property alias fileRowContextMenu: fileRowContextMenu
    property alias multiFileContextMenu: multiFileContextMenu
    property alias fileAreaContextMenu: fileAreaContextMenu
    property alias viewModeMenu: viewModeMenu
    property alias themeMenu: themeMenu

    CreateMenu {
        id: createMenu
        rootWindow: root.rootWindow
    }

    MoreActionsMenu {
        id: moreActionsMenu
        rootWindow: root.rootWindow
    }

    ConfirmDialog {
        id: confirmDialog
        rootWindow: root.rootWindow
    }

    NotificationsPopup {
        id: notificationsPopup
        rootWindow: root.rootWindow
        notificationsModel: root.notificationsModel
    }

    SearchScopePopup {
        id: searchScopeMenu
        rootWindow: root.rootWindow
    }

    BreadcrumbContextMenu {
        id: breadcrumbContextMenu
        rootWindow: root.rootWindow
    }

    EmptyAreaContextMenu {
        id: emptyAreaContextMenu
        rootWindow: root.rootWindow
    }

    TabContextMenu {
        id: tabContextMenu
        rootWindow: root.rootWindow
        tabsCount: root.rootWindow.tabsModel.count
    }

    SidebarContextMenu {
        id: sidebarContextMenu
        rootWindow: root.rootWindow
    }

    FileContextMenu {
        id: fileRowContextMenu
        rootWindow: root.rootWindow
    }

    MultiFileContextMenu {
        id: multiFileContextMenu
        rootWindow: root.rootWindow
    }

    StyledMenu {
        id: fileAreaContextMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "New folder"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.rootWindow.addNewFolder()
        }

        StyledMenuItem {
            text: "New file"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.rootWindow.addNewFile()
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Paste"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.rootWindow.applySnapshot(root.rootWindow.backend.pasteItems())
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Refresh"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.rootWindow.applySnapshot(root.rootWindow.backend.refresh())
        }

        StyledMenuItem {
            text: "Properties"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.rootWindow.applySnapshot(root.rootWindow.backend.showCurrentLocationProperties())
        }
    }

    ViewModeMenu {
        id: viewModeMenu
        rootWindow: root.rootWindow
    }

    ThemeMenu {
        id: themeMenu
        rootWindow: root.rootWindow
    }
}