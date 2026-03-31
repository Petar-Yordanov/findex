import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: navBar

    required property var viewModel
    required property var breadcrumbContextMenu

    readonly property alias pathFieldRef: pathField
    readonly property alias pathBarRef: pathBar

    readonly property bool hasVm: viewModel !== null && viewModel !== undefined
    readonly property var crumbsModel: hasVm ? viewModel.breadcrumbModel : null

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
            enabled: navBar.hasVm
            onClicked: if (navBar.hasVm) navBar.viewModel.goBack()
        }

        IconButton {
            iconName: "arrow-forward"
            tooltipText: "Forward"
            darkTheme: Theme.AppTheme.isDark
            enabled: navBar.hasVm
            onClicked: if (navBar.hasVm) navBar.viewModel.goForward()
        }

        IconButton {
            iconName: "arrow-upward"
            tooltipText: "Up"
            darkTheme: Theme.AppTheme.isDark
            enabled: navBar.hasVm
            onClicked: if (navBar.hasVm) navBar.viewModel.goUp()
        }

        IconButton {
            iconName: "refresh"
            tooltipText: "Refresh"
            darkTheme: Theme.AppTheme.isDark
            enabled: navBar.hasVm
            onClicked: if (navBar.hasVm) navBar.viewModel.refresh()
        }

        Rectangle {
            id: pathBar
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: Theme.Metrics.radiusLg
            color: Theme.AppTheme.popupBg
            border.color: navBar.hasVm && navBar.viewModel.editingPath
                          ? Theme.AppTheme.accent
                          : Theme.AppTheme.border
            border.width: Theme.Metrics.borderWidth

            StackLayout {
                anchors.fill: parent
                currentIndex: navBar.hasVm && navBar.viewModel.editingPath ? 1 : 0

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
                                model: navBar.crumbsModel

                                delegate: Row {
                                    required property int index
                                    required property string label
                                    required property string icon

                                    spacing: Theme.Metrics.spacingSm

                                    Rectangle {
                                        id: crumbPill
                                        height: Theme.Metrics.controlHeightMd
                                        radius: Theme.Metrics.radiusMd
                                        color: crumbMouse.pressed
                                               ? Theme.AppTheme.pressed
                                               : crumbMouse.containsMouse
                                                 ? (Theme.AppTheme.isDark ? "#344055" : "#dfe9f8")
                                                 : "transparent"
                                        width: Math.min(crumbContent.implicitWidth + 16, 220)
                                        clip: true

                                        Row {
                                            id: crumbContent
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.Metrics.spacingMd
                                            spacing: Theme.Metrics.spacingSm

                                            AppIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: icon || ""
                                                darkTheme: Theme.AppTheme.isDark
                                                iconSize: 13
                                                visible: icon !== ""
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: label || ""
                                                color: Theme.AppTheme.text
                                                font.pixelSize: Theme.Typography.bodyLg
                                                elide: Text.ElideRight
                                                width: Math.min(150, implicitWidth)
                                            }
                                        }

                                        MouseArea {
                                            id: crumbMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                                            onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton && navBar.breadcrumbContextMenu) {
                                                    var p = crumbPill.mapToItem(
                                                                navBar.breadcrumbContextMenu.parent,
                                                                mouse.x,
                                                                mouse.y)
                                                    navBar.breadcrumbContextMenu.popupAt(p.x, p.y)
                                                    mouse.accepted = true
                                                }
                                            }

                                            onClicked: function(mouse) {
                                                if (mouse.button === Qt.LeftButton && navBar.hasVm)
                                                    navBar.viewModel.navigateToBreadcrumb(index)
                                            }

                                            onDoubleClicked: {
                                                if (!navBar.hasVm)
                                                    return
                                                navBar.viewModel.beginPathEdit()
                                                pathField.forceActiveFocus()
                                                pathField.selectAll()
                                            }
                                        }
                                    }

                                    AppIcon {
                                        visible: navBar.crumbsModel && index < navBar.crumbsModel.rowCount() - 1
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
                                if (!navBar.hasVm)
                                    return
                                navBar.viewModel.beginPathEdit()
                                pathField.forceActiveFocus()
                                pathField.selectAll()
                            }
                        }

                        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
                    }
                }

                Basic.TextField {
                    id: pathField
                    text: navBar.hasVm ? navBar.viewModel.pathText : ""
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.bodyLg
                    leftPadding: Theme.Metrics.spacingXl
                    rightPadding: Theme.Metrics.spacingXl
                    topPadding: 0
                    bottomPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle { color: "transparent" }

                    onAccepted: if (navBar.hasVm) navBar.viewModel.commitPathEdit(text)
                    onActiveFocusChanged: {
                        if (!activeFocus && navBar.hasVm && navBar.viewModel.editingPath)
                            navBar.viewModel.cancelPathEdit()
                    }
                    Keys.onEscapePressed: if (navBar.hasVm) navBar.viewModel.cancelPathEdit()
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
                            name: navBar.hasVm && navBar.viewModel.searchScope === "global"
                                  ? "hard-drive"
                                  : "folder"
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
                            if (!searchScopeMenu.parent)
                                return

                            var p = searchScopeButton.mapToItem(
                                        searchScopeMenu.parent,
                                        0,
                                        searchScopeButton.height + 2)

                            searchScopeMenu.x = p.x
                            searchScopeMenu.y = p.y
                            searchScopeMenu.open()
                        }
                    }
                }

                StyledMenu {
                    id: searchScopeMenu
                    darkTheme: Theme.AppTheme.isDark
                    menuWidth: 150

                    StyledMenuItem {
                        text: "This folder"
                        darkTheme: Theme.AppTheme.isDark
                        onTriggered: {
                            if (navBar.hasVm)
                                navBar.viewModel.searchScope = "folder"
                            searchScopeMenu.close()
                        }
                    }

                    StyledMenuItem {
                        text: "Everywhere"
                        darkTheme: Theme.AppTheme.isDark
                        onTriggered: {
                            if (navBar.hasVm)
                                navBar.viewModel.searchScope = "global"
                            searchScopeMenu.close()
                        }
                    }
                }

                AppIcon {
                    name: "search"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconSm
                    iconOpacity: 0.65
                }

                Basic.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: navBar.hasVm && navBar.viewModel.searchScope === "global"
                                     ? "Search everywhere"
                                     : "Search in folder"
                    placeholderTextColor: Theme.AppTheme.muted
                    text: navBar.hasVm ? navBar.viewModel.currentSearch : ""
                    color: Theme.AppTheme.text
                    font.pixelSize: Theme.Typography.bodyLg
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    background: Rectangle { color: "transparent" }

                    onTextEdited: if (navBar.hasVm) navBar.viewModel.currentSearch = text
                    onAccepted: if (navBar.hasVm) navBar.viewModel.submitSearch()
                }
            }
        }
    }
}