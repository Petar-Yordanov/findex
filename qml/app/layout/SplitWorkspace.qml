import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme
import "../sidebar"
import "../preview"
import "../statusbar"
import "../files"

Item {
    id: splitViewHost

    required property var rootWindow
    required property var sidebarViewModel
    required property var sidebarContextMenu
    required property var workspaceViewModel
    required property var previewViewModel
    required property var statusBarViewModel
    required property var notificationsPopup
    required property var fileContextMenu
    required property var dragOverlayHost

    property int sidebarWidth: 286
    property int sidebarMinWidth: 220
    property int sidebarMaxWidth: Math.max(360, width * 0.45)
    property int splitterWidth: 8
    property int minimumFileAreaWidth: 420

    readonly property bool hasPreviewVm: previewViewModel !== null && previewViewModel !== undefined
    readonly property bool previewEnabledSafe: hasPreviewVm && !!previewViewModel.previewEnabled
    readonly property int previewPaneWidthSafe: hasPreviewVm ? previewViewModel.previewPaneWidth : 320
    readonly property int previewPaneMinWidthSafe: hasPreviewVm ? previewViewModel.previewPaneMinWidth : 220
    readonly property int previewPaneMaxWidthSafe: hasPreviewVm ? previewViewModel.previewPaneMaxWidth : 420

    Component {
        id: detailsViewComponent
        DetailsFileView {
            viewModel: splitViewHost.workspaceViewModel
            fileContextMenu: splitViewHost.fileContextMenu
            dragOverlayHost: splitViewHost.dragOverlayHost
        }
    }

    Component {
        id: tilesViewComponent
        TilesFileView {
            viewModel: splitViewHost.workspaceViewModel
            fileContextMenu: splitViewHost.fileContextMenu
            dragOverlayHost: splitViewHost.dragOverlayHost
        }
    }

    Component {
        id: compactViewComponent
        CompactFileView {
            viewModel: splitViewHost.workspaceViewModel
            fileContextMenu: splitViewHost.fileContextMenu
            dragOverlayHost: splitViewHost.dragOverlayHost
        }
    }

    Component {
        id: largeIconsViewComponent
        LargeIconsFileView {
            viewModel: splitViewHost.workspaceViewModel
            fileContextMenu: splitViewHost.fileContextMenu
            dragOverlayHost: splitViewHost.dragOverlayHost
        }
    }

    Rectangle {
        id: sidebarPane
        x: 0
        y: 0
        width: splitViewHost.sidebarWidth
        height: parent.height
        color: Theme.AppTheme.surface2
        border.color: Theme.AppTheme.borderSoft
        border.width: Theme.Metrics.borderWidth

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.Metrics.spacingMd
            spacing: Theme.Metrics.spacingLg

            QuickAccessPane {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                Layout.minimumHeight: 180
                Layout.maximumHeight: 320
                viewModel: splitViewHost.sidebarViewModel
                sidebarContextMenu: splitViewHost.sidebarContextMenu
            }

            SidebarTreePane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 180
                viewModel: splitViewHost.sidebarViewModel
                sidebarContextMenu: splitViewHost.sidebarContextMenu
            }

            DriveListPane {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                Layout.minimumHeight: 150
                Layout.maximumHeight: 280
                viewModel: splitViewHost.sidebarViewModel
                sidebarContextMenu: splitViewHost.sidebarContextMenu
            }
        }
    }

    Rectangle {
        id: sidebarSplitter
        x: sidebarPane.width
        y: 0
        width: splitViewHost.splitterWidth
        height: parent.height
        color: sidebarSplitterMouse.pressed
               ? (Theme.AppTheme.isDark ? "#2a3342" : "#d7dfeb")
               : sidebarSplitterMouse.containsMouse
                 ? (Theme.AppTheme.isDark ? "#212938" : "#e3e9f2")
                 : "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: parent.height
            radius: 1
            color: sidebarSplitterMouse.pressed
                   ? Theme.AppTheme.accent
                   : sidebarSplitterMouse.containsMouse
                     ? Theme.AppTheme.border
                     : "transparent"
        }

        MouseArea {
            id: sidebarSplitterMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            acceptedButtons: Qt.LeftButton

            property real pressSceneX: 0
            property int startWidth: 0

            onPressed: function(mouse) {
                var p = sidebarSplitterMouse.mapToItem(splitViewHost, mouse.x, mouse.y)
                pressSceneX = p.x
                startWidth = splitViewHost.sidebarWidth
            }

            onPositionChanged: function(mouse) {
                if (!pressed)
                    return

                var p = sidebarSplitterMouse.mapToItem(splitViewHost, mouse.x, mouse.y)
                var dx = p.x - pressSceneX
                var nextWidth = startWidth + dx
                splitViewHost.sidebarWidth = Math.max(
                    splitViewHost.sidebarMinWidth,
                    Math.min(splitViewHost.sidebarMaxWidth, nextWidth)
                )
            }
        }
    }

    Rectangle {
        id: contentPane
        x: sidebarPane.width + sidebarSplitter.width
        y: 0
        width: parent.width - x
        height: parent.height
        color: Theme.AppTheme.surface3
        border.color: Theme.AppTheme.borderSoft
        border.width: Theme.Metrics.borderWidth
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                id: mainRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    id: filesPane
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: splitViewHost.minimumFileAreaWidth
                    color: Theme.AppTheme.surface3
                    border.color: Theme.AppTheme.borderSoft
                    border.width: Theme.Metrics.borderWidth
                    clip: true

                    Loader {
                        anchors.fill: parent
                        sourceComponent: {
                            var mode = splitViewHost.workspaceViewModel ? splitViewHost.workspaceViewModel.viewMode : "Details"
                            if (mode === "Details")
                                return detailsViewComponent
                            if (mode === "Tiles")
                                return tilesViewComponent
                            if (mode === "Compact")
                                return compactViewComponent
                            if (mode === "Large icons")
                                return largeIconsViewComponent
                            return detailsViewComponent
                        }
                    }
                }

                Rectangle {
                    id: previewSplitter
                    visible: splitViewHost.previewEnabledSafe
                    Layout.preferredWidth: visible ? splitViewHost.splitterWidth : 0
                    Layout.minimumWidth: visible ? splitViewHost.splitterWidth : 0
                    Layout.maximumWidth: visible ? splitViewHost.splitterWidth : 0
                    Layout.fillHeight: true
                    color: previewResizeMouse.pressed
                           ? (Theme.AppTheme.isDark ? "#2a3342" : "#d7dfeb")
                           : previewResizeMouse.containsMouse
                             ? (Theme.AppTheme.isDark ? "#212938" : "#e3e9f2")
                             : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        radius: 1
                        color: previewResizeMouse.pressed
                               ? Theme.AppTheme.accent
                               : previewResizeMouse.containsMouse
                                 ? Theme.AppTheme.border
                                 : "transparent"
                    }

                    MouseArea {
                        id: previewResizeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        acceptedButtons: Qt.LeftButton
                        enabled: splitViewHost.hasPreviewVm && splitViewHost.previewEnabledSafe

                        property real pressSceneX: 0
                        property int startWidth: 0

                        onPressed: function(mouse) {
                            if (!splitViewHost.hasPreviewVm)
                                return

                            var p = previewResizeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                            pressSceneX = p.x
                            startWidth = splitViewHost.previewPaneWidthSafe
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed || !splitViewHost.hasPreviewVm)
                                return

                            var p = previewResizeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                            var dx = p.x - pressSceneX

                            var maxAllowed = Math.max(
                                splitViewHost.previewPaneMinWidthSafe,
                                Math.min(
                                    splitViewHost.previewPaneMaxWidthSafe,
                                    contentPane.width - splitViewHost.minimumFileAreaWidth - splitViewHost.splitterWidth
                                )
                            )

                            splitViewHost.previewViewModel.previewPaneWidth = Math.max(
                                splitViewHost.previewPaneMinWidthSafe,
                                Math.min(maxAllowed, startWidth - dx)
                            )
                        }
                    }
                }

                PreviewPane {
                    visible: splitViewHost.previewEnabledSafe
                    Layout.preferredWidth: visible ? splitViewHost.previewPaneWidthSafe : 0
                    Layout.minimumWidth: visible ? splitViewHost.previewPaneMinWidthSafe : 0
                    Layout.maximumWidth: visible ? splitViewHost.previewPaneMaxWidthSafe : 0
                    Layout.fillHeight: true
                    viewModel: splitViewHost.previewViewModel
                }
            }

            StatusBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                rootWindow: splitViewHost.rootWindow
                viewModel: splitViewHost.statusBarViewModel
                viewModeMenu: splitViewHost.rootWindow ? splitViewHost.rootWindow.viewModeMenu : null
                notificationsPopup: splitViewHost.notificationsPopup
            }
        }
    }
}