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

    Runtime.AppOverlays {
        id: overlays
        anchors.fill: parent
        rootWindow: root
        sidebarViewModel: root.sidebarVm
        tabsViewModel: root.tabsVm
        statusBarViewModel: root.statusBarVm
    }

    Layout.AppShell {
        anchors.fill: parent

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
    }
}