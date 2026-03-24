import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: navBar

    required property var rootWindow
    required property var pathModel
    required property var breadcrumbContextMenu
    required property var searchScopeMenu

    readonly property alias pathFieldRef: pathField
    readonly property alias pathBarRef: pathBar

    color: Theme.AppTheme.surface
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingLg

        IconButton {
            iconName: "arrow-back"
            tooltipText: "Back"
            darkTheme: Theme.AppTheme.isDark
            onClicked: navBar.rootWindow.applySnapshot(navBar.rootWindow.backend.goBack())
        }

        IconButton {
            iconName: "arrow-forward"
            tooltipText: "Forward"
            darkTheme: Theme.AppTheme.isDark
            onClicked: navBar.rootWindow.applySnapshot(navBar.rootWindow.backend.goForward())
        }

        IconButton {
            iconName: "arrow-upward"
            tooltipText: "Up"
            darkTheme: Theme.AppTheme.isDark
            onClicked: navBar.rootWindow.applySnapshot(navBar.rootWindow.backend.goUp())
        }

        IconButton {
            iconName: "refresh"
            tooltipText: "Refresh"
            darkTheme: Theme.AppTheme.isDark
            onClicked: navBar.rootWindow.applySnapshot(navBar.rootWindow.backend.refresh())
        }

        Rectangle {
            id: pathBar
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: Theme.Metrics.radiusLg
            color: Theme.AppTheme.popupBg
            border.color: navBar.rootWindow.editingPath ? Theme.AppTheme.accent : Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            StackLayout {
                anchors.fill: parent
                currentIndex: navBar.rootWindow.editingPath ? 1 : 0

                Item {
                    clip: true

                    Flickable {
                        id: breadcrumbFlick
                        anchors.fill: parent
                        anchors.leftMargin: Theme.Metrics.spacingXl
                        anchors.rightMargin: Theme.Metrics.spacingXl
                        contentWidth: Math.max(width, breadcrumbRow.width)
                        contentHeight: height
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: breadcrumbRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.Metrics.spacingSm

                            Repeater {
                                model: navBar.pathModel

                                delegate: Row {
                                    id: breadcrumbDelegate
                                    required property int index
                                    required property var modelData
                                    spacing: Theme.Metrics.spacingSm

                                    readonly property var rw: navBar.rootWindow
                                    readonly property var bcMenu: navBar.breadcrumbContextMenu

                                    readonly property bool dropHovered: breadcrumbDelegate.rw.breadcrumbDropHoverIndex === index

                                    Rectangle {
                                        id: crumbPill
                                        height: Theme.Metrics.controlHeightMd
                                        radius: Theme.Metrics.radiusMd
                                        color: breadcrumbDelegate.dropHovered
                                               ? Theme.AppTheme.selectedSoft
                                               : crumbMouse.pressed
                                                 ? Theme.AppTheme.pressed
                                                 : crumbMouse.containsMouse
                                                   ? (Theme.AppTheme.isDark ? "#344055" : "#dfe9f8")
                                                   : "transparent"
                                        border.color: breadcrumbDelegate.dropHovered ? Theme.AppTheme.accent : "transparent"
                                        border.width: breadcrumbDelegate.dropHovered ? 1 : 0
                                        width: Math.min(crumbContent.implicitWidth + 16, 190)
                                        clip: true

                                        DropArea {
                                            anchors.fill: parent

                                            onEntered: function(drag) {
                                                drag.accepted = breadcrumbDelegate.rw.draggedFileCount > 0
                                                if (drag.accepted)
                                                    breadcrumbDelegate.rw.breadcrumbDropHoverIndex = breadcrumbDelegate.index
                                            }

                                            onExited: {
                                                if (breadcrumbDelegate.rw.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                    breadcrumbDelegate.rw.breadcrumbDropHoverIndex = -1
                                            }

                                            onDropped: function(drop) {
                                                if (breadcrumbDelegate.rw.draggedFileCount > 0) {
                                                    drop.accepted = true
                                                    breadcrumbDelegate.rw.handleDroppedItem(breadcrumbDelegate.modelData.label, "breadcrumb")
                                                }

                                                if (breadcrumbDelegate.rw.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                    breadcrumbDelegate.rw.breadcrumbDropHoverIndex = -1
                                            }
                                        }

                                        Row {
                                            id: crumbContent
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.Metrics.spacingMd
                                            spacing: Theme.Metrics.spacingSm

                                            AppIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: modelData.icon
                                                darkTheme: Theme.AppTheme.isDark
                                                iconSize: 13
                                                visible: modelData.icon !== ""
                                            }

                                            Text {
                                                id: crumbText
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.label
                                                color: Theme.AppTheme.text
                                                font.pixelSize: Theme.Typography.bodyLg
                                                elide: Text.ElideRight
                                                width: Math.min(140, implicitWidth)
                                            }
                                        }

                                        MouseArea {
                                            id: crumbMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            z: 1

                                            onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton) {
                                                    breadcrumbDelegate.rw.contextBreadcrumbIndex = breadcrumbDelegate.index
                                                    breadcrumbDelegate.bcMenu.popup()
                                                    mouse.accepted = true
                                                }
                                            }

                                            onClicked: function(mouse) {
                                                if (mouse.button === Qt.LeftButton)
                                                    breadcrumbDelegate.rw.setPathFromIndex(breadcrumbDelegate.index)
                                            }

                                            onDoubleClicked: {
                                                breadcrumbDelegate.rw.editingPath = true
                                                pathField.forceActiveFocus()
                                                pathField.selectAll()
                                            }
                                        }
                                    }

                                    AppIcon {
                                        visible: breadcrumbDelegate.index < pathModel.count - 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "chevron-right"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                        iconOpacity: 0.65
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            x: breadcrumbRow.width
                            width: Math.max(0, parent.width - breadcrumbRow.width)
                            acceptedButtons: Qt.LeftButton

                            onDoubleClicked: {
                                navBar.rootWindow.editingPath = true
                                pathField.forceActiveFocus()
                                pathField.selectAll()
                            }
                        }

                        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
                    }
                }

                TextField {
                    id: pathField
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.bodyLg
                    leftPadding: Theme.Metrics.spacingXl
                    rightPadding: Theme.Metrics.spacingXl
                    topPadding: 0
                    bottomPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { color: "transparent" }

                    onAccepted: navBar.rootWindow.finishPathEditing(true)
                    onActiveFocusChanged: {
                        if (!activeFocus && navBar.rootWindow.editingPath)
                            navBar.rootWindow.finishPathEditing(false)
                    }
                    Keys.onEscapePressed: navBar.rootWindow.finishPathEditing(false)
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 300
            Layout.preferredHeight: 38
            radius: Theme.Metrics.radiusLg
            color: Theme.AppTheme.popupBg
            border.color: searchField.activeFocus ? Theme.AppTheme.accent : Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.Metrics.spacingMd
                anchors.rightMargin: Theme.Metrics.spacingLg
                spacing: Theme.Metrics.spacingMd

                Rectangle {
                    id: searchScopeButton
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 28
                    radius: Theme.Metrics.radiusMd
                    color: searchScopeMouse.pressed
                           ? Theme.AppTheme.pressed
                           : searchScopeMouse.containsMouse
                             ? Theme.AppTheme.hover
                             : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        AppIcon {
                            name: navBar.rootWindow.searchScope === "global" ? "hard-drive" : "folder"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: Theme.Metrics.iconSm
                        }

                        AppIcon {
                            name: (navBar.searchScopeMenu && navBar.searchScopeMenu.visible)
                                  ? "keyboard-arrow-up"
                                  : "keyboard-arrow-down"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 10
                            iconOpacity: 0.6
                        }
                    }

                    MouseArea {
                        id: searchScopeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: {
                            if (!navBar.searchScopeMenu)
                                return

                            var p = searchScopeButton.mapToItem(navBar.rootWindow.contentItem, 0, searchScopeButton.height + 6)
                            navBar.searchScopeMenu.x = p.x
                            navBar.searchScopeMenu.y = p.y
                            navBar.searchScopeMenu.open()
                        }
                    }
                }

                AppIcon {
                    name: "search"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconSm
                    iconOpacity: 0.65
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: navBar.rootWindow.searchScope === "global"
                                     ? "Search everywhere"
                                     : "Search in folder"
                    placeholderTextColor: Theme.AppTheme.muted
                    text: navBar.rootWindow.currentSearch
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.bodyLg
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    background: Rectangle { color: "transparent" }

                    onTextChanged: navBar.rootWindow.currentSearch = text
                    onAccepted: navBar.rootWindow.applySnapshot(navBar.rootWindow.backend.search(text, navBar.rootWindow.searchScope))
                }
            }
        }
    }
}