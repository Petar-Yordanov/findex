import QtQuick
import "../sidebar"
import "../titlebar"
import "../statusbar"
import "../files"
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: root
    anchors.fill: parent

    required property var rootWindow
    required property var sidebarViewModel
    required property var tabsViewModel
    required property var statusBarViewModel
    required property var workspaceViewModel

    property alias sidebarContextMenu: sidebarContextMenu
    property alias breadcrumbContextMenu: breadcrumbContextMenu
    property alias tabContextMenu: tabContextMenu
    property alias fileContextMenu: fileContextMenu

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

    FileContextMenu {
        id: fileContextMenu
        viewModel: root.workspaceViewModel
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

    Item {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 14
        anchors.bottomMargin: 42
        z: 60000
        width: 360
        height: parent.height
        clip: false

        Column {
            id: toastColumn
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Theme.Metrics.spacingSm

            Repeater {
                model: root.statusBarViewModel ? root.statusBarViewModel.toastNotifications : []

                delegate: NotificationCard {
                    required property var modelData

                    width: 340
                    darkTheme: Theme.AppTheme.isDark

                    notificationId: modelData.id
                    title: modelData.title || ""
                    kind: modelData.kind || "info"
                    progress: modelData.progress === undefined ? -1 : modelData.progress
                    autoClose: modelData.autoClose === undefined ? true : !!modelData.autoClose
                    done: !!modelData.done

                    onCloseRequested: function(id) {
                        if (root.statusBarViewModel)
                            root.statusBarViewModel.dismissToast(id)
                    }
                }
            }
        }
    }
}