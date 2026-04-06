import QtQuick
import QtQuick.Window
import "components/theme" as Theme
import "app/layout" as Layout
import "app/runtime" as Runtime

Window {
    id: root

    width: 1400
    height: 860
    visible: true
    title: "Findex"
    color: Theme.AppTheme.bg

    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint
    minimumWidth: 640
    minimumHeight: 480

    property var sidebarVm: appSidebarViewModel
    property var navigationVm: appNavigationViewModel
    property var commandBarVm: appCommandBarViewModel
    property var tabsVm: appTabsViewModel
    property var previewPaneVm: appPreviewPaneViewModel
    property var statusBarVm: appStatusBarViewModel
    property var workspaceVm: appWorkspaceViewModel

    property var createMenu: overlays.createMenu
    property var moreActionsMenu: overlays.moreActionsMenu
    property var viewModeMenu: overlays.viewModeMenu
    property var themeMenu: overlays.themeMenu
    property var notificationsPopupRef: overlays.notificationsPopup

    property int resizeMargin: 6
    property int resizeCornerSize: 12

    Binding {
        target: Theme.AppTheme
        property: "mode"
        value: root.commandBarVm ? root.commandBarVm.themeMode : "Light"
    }

    function popupBelow(anchorItem, popup) {
        if (!anchorItem || !popup || !popup.parent)
            return
        var p = anchorItem.mapToItem(popup.parent, 0, anchorItem.height + 2)
        popup.popupAt(p.x, p.y)
    }

    Layout.AppShell {
        id: shell
        anchors.fill: parent
        z: 0

        rootWindow: root

        sidebarViewModel: root.sidebarVm
        navigationViewModel: root.navigationVm
        commandBarViewModel: root.commandBarVm
        tabsViewModel: root.tabsVm
        previewViewModel: root.previewPaneVm
        statusBarViewModel: root.statusBarVm
        workspaceViewModel: root.workspaceVm

        createMenu: overlays.createMenu
        moreActionsMenu: overlays.moreActionsMenu
        viewModeMenu: overlays.viewModeMenu
        themeMenu: overlays.themeMenu
        breadcrumbContextMenu: overlays.breadcrumbContextMenu
        tabContextMenu: overlays.tabContextMenu
        sidebarContextMenu: overlays.sidebarContextMenu
        notificationsPopup: overlays.notificationsPopup
        fileContextMenu: overlays.fileContextMenu
    }

    Runtime.AppOverlays {
        id: overlays
        anchors.fill: parent
        z: 100000

        rootWindow: root
        sidebarViewModel: root.sidebarVm
        tabsViewModel: root.tabsVm
        statusBarViewModel: root.statusBarVm
        workspaceViewModel: root.workspaceVm
    }

    Item {
        id: resizeLayer
        anchors.fill: parent
        z: 200000
        visible: root.visibility !== Window.Maximized

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.resizeMargin
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeVerCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.TopEdge)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.resizeMargin
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeVerCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.BottomEdge)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.resizeMargin
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeHorCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.LeftEdge)
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.resizeMargin
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeHorCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.RightEdge)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            width: root.resizeCornerSize
            height: root.resizeCornerSize
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeFDiagCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            width: root.resizeCornerSize
            height: root.resizeCornerSize
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeBDiagCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.RightEdge | Qt.TopEdge)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.resizeCornerSize
            height: root.resizeCornerSize
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeBDiagCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: root.resizeCornerSize
            height: root.resizeCornerSize
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SizeFDiagCursor
                onPressed: function(mouse) {
                    mouse.accepted = root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
                }
            }
        }
    }
}