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

    color: Theme.AppTheme.surface
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    Component.onCompleted: {
        rootWindow.pathFieldRef = pathField
        rootWindow.pathBarRef = pathBar
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingXl
        anchors.rightMargin: Theme.Metrics.spacingXl
        spacing: Theme.Metrics.spacingLg

        IconButton {
            iconName: "arrow-back"
            tooltipText: "Back"
            darkTheme: Theme.AppTheme.isDark
            onClicked: rootWindow.applySnapshot(rootWindow.backend.goBack())
        }

        IconButton {
            iconName: "arrow-forward"
            tooltipText: "Forward"
            darkTheme: Theme.AppTheme.isDark
            onClicked: rootWindow.applySnapshot(rootWindow.backend.goForward())
        }

        IconButton {
            iconName: "arrow-upward"
            tooltipText: "Up"
            darkTheme: Theme.AppTheme.isDark
            onClicked: rootWindow.applySnapshot(rootWindow.backend.goUp())
        }

        IconButton {
            iconName: "refresh"
            tooltipText: "Refresh"
            darkTheme: Theme.AppTheme.isDark
            onClicked: rootWindow.applySnapshot(rootWindow.backend.refresh())
        }

        Rectangle {
            id: pathBar
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: Theme.Metrics.radiusLg
            color: Theme.AppTheme.popupBg
            border.color: rootWindow.editingPath ? Theme.AppTheme.accent : Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            StackLayout {
                anchors.fill: parent
                currentIndex: rootWindow.editingPath ? 1 : 0

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
                                model: pathModel

                                delegate: Row {
                                    id: breadcrumbDelegate
                                    required property int index
                                    required property var modelData
                                    spacing: Theme.Metrics.spacingSm

                                    readonly property bool dropHovered: rootWindow.breadcrumbDropHoverIndex === index

                                    Rectangle {
                                        id: crumbPill
                                        height: Theme.Metrics.controlHeightMd
                                        radius: Theme.Metrics.radiusMd
                                        color: dropHovered
                                               ? Theme.AppTheme.selectedSoft
                                               : crumbMouse.pressed
                                                 ? Theme.AppTheme.pressed
                                                 : crumbMouse.containsMouse
                                                   ? (Theme.AppTheme.isDark ? "#344055" : "#dfe9f8")
                                                   : "transparent"
                                        border.color: dropHovered ? Theme.AppTheme.accent : "transparent"
                                        border.width: dropHovered ? 1 : 0
                                        width: Math.min(crumbContent.implicitWidth + 16, 190)
                                        clip: true

                                        DropArea {
                                            anchors.fill: parent

                                            onEntered: function(drag) {
                                                drag.accepted = rootWindow.draggedFileCount > 0
                                                if (drag.accepted)
                                                    rootWindow.breadcrumbDropHoverIndex = breadcrumbDelegate.index
                                            }

                                            onExited: function(drag) {
                                                if (rootWindow.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                    rootWindow.breadcrumbDropHoverIndex = -1
                                            }

                                            onDropped: function(drop) {
                                                if (rootWindow.draggedFileCount > 0) {
                                                    drop.accepted = true
                                                    rootWindow.handleDroppedItem(breadcrumbDelegate.modelData.label, "breadcrumb")
                                                }

                                                if (rootWindow.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                    rootWindow.breadcrumbDropHoverIndex = -1
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
                                                    rootWindow.contextBreadcrumbIndex = index
                                                    breadcrumbContextMenu.popup()
                                                    mouse.accepted = true
                                                }
                                            }

                                            onClicked: function(mouse) {
                                                if (mouse.button === Qt.LeftButton)
                                                    rootWindow.setPathFromIndex(index)
                                            }

                                            onDoubleClicked: {
                                                rootWindow.editingPath = true
                                                pathField.forceActiveFocus()
                                                pathField.selectAll()
                                            }
                                        }
                                    }

                                    AppIcon {
                                        visible: index < pathModel.count - 1
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
                                rootWindow.editingPath = true
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

                    onAccepted: rootWindow.finishPathEditing(true)
                    onActiveFocusChanged: {
                        if (!activeFocus && rootWindow.editingPath)
                            rootWindow.finishPathEditing(false)
                    }
                    Keys.onEscapePressed: rootWindow.finishPathEditing(false)
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
                            name: rootWindow.searchScope === "global" ? "hard-drive" : "folder"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: Theme.Metrics.iconSm
                        }

                        AppIcon {
                            name: searchScopeMenu.visible ? "keyboard-arrow-up" : "keyboard-arrow-down"
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
                            var p = searchScopeButton.mapToItem(rootWindow.contentItem, 0, searchScopeButton.height + 6)
                            searchScopeMenu.x = p.x
                            searchScopeMenu.y = p.y
                            searchScopeMenu.open()
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
                    placeholderText: rootWindow.searchScope === "global"
                                     ? "Search everywhere"
                                     : "Search in folder"
                    placeholderTextColor: Theme.AppTheme.muted
                    text: rootWindow.currentSearch
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.bodyLg
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    background: Rectangle { color: "transparent" }

                    onTextChanged: rootWindow.currentSearch = text
                    onAccepted: rootWindow.applySnapshot(rootWindow.backend.search(text, rootWindow.searchScope))
                }
            }
        }
    }
}