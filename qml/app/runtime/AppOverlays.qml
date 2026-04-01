import QtQuick
import "../sidebar"
import "../titlebar"
import "../statusbar"
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: root
    anchors.fill: parent

    required property var rootWindow
    required property var sidebarViewModel
    required property var tabsViewModel
    required property var statusBarViewModel

    property alias sidebarContextMenu: sidebarContextMenu
    property alias breadcrumbContextMenu: breadcrumbContextMenu
    property alias tabContextMenu: tabContextMenu

    property alias createMenu: createMenu
    property alias moreActionsMenu: moreActionsMenu
    property alias viewModeMenu: viewModeMenu
    property alias themeMenu: themeMenu
    property alias notificationsPopup: notificationsPopup

    SidebarContextMenu {
        id: sidebarContextMenu
        viewModel: root.sidebarViewModel
    }

    StyledMenu {
        id: breadcrumbContextMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Copy path"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: breadcrumbContextMenu.close()
        }
    }

    TabContextMenu {
        id: tabContextMenu
        viewModel: root.tabsViewModel
    }

    StyledMenu {
        id: createMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "New folder"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.createFolder()
                createMenu.close()
            }
        }

        StyledMenuItem {
            text: "New file"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.createFile()
                createMenu.close()
            }
        }
    }

    StyledMenu {
        id: viewModeMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Details"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyViewMode("Details")
                viewModeMenu.close()
            }
        }

        StyledMenuItem {
            text: "Tiles"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyViewMode("Tiles")
                viewModeMenu.close()
            }
        }

        StyledMenuItem {
            text: "Compact"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyViewMode("Compact")
                viewModeMenu.close()
            }
        }

        StyledMenuItem {
            text: "Large icons"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyViewMode("Large icons")
                viewModeMenu.close()
            }
        }
    }

    StyledMenu {
        id: themeMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Dark"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyTheme("Dark")
                themeMenu.close()
            }
        }

        StyledMenuItem {
            text: "Light"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyTheme("Light")
                themeMenu.close()
            }
        }

        StyledMenuItem {
            text: "System"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.applyTheme("System")
                themeMenu.close()
            }
        }
    }

    StyledMenu {
        id: moreActionsMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Compress"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.compressSelection()
                moreActionsMenu.close()
            }
        }

        StyledMenuItem {
            text: "Extract here"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.extractSelection()
                moreActionsMenu.close()
            }
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Select all"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.selectAll()
                moreActionsMenu.close()
            }
        }

        StyledMenuItem {
            text: root.rootWindow.commandBarVm && root.rootWindow.commandBarVm.showHiddenFiles
                  ? "Hide hidden files"
                  : "Show hidden files"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.toggleHiddenFiles()
                moreActionsMenu.close()
            }
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Properties"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                if (root.rootWindow.commandBarVm)
                    root.rootWindow.commandBarVm.showProperties()
                moreActionsMenu.close()
            }
        }
    }

    NotificationsPopup {
        id: notificationsPopup
        viewModel: root.statusBarViewModel
    }
}