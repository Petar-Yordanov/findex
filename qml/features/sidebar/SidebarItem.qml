import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    required property var rootWindow
    required property var sidebarContextMenu

    required property TreeView treeView
    required property bool isTreeNode
    required property bool expanded
    required property bool hasChildren
    required property int depth
    required property int row
    required property int column
    required property bool current
    required property bool selected

    readonly property string itemLabel: treeView.model.data(treeView.index(row, 0), Qt.DisplayRole) || ""
    readonly property string itemIcon: treeView.model.data(treeView.index(row, 1), Qt.DisplayRole) || ""
    readonly property bool itemSection: (treeView.model.data(treeView.index(row, 2), Qt.DisplayRole) === true)
    readonly property string itemKind: treeView.model.data(treeView.index(row, 3), Qt.DisplayRole) || ""

    readonly property bool dropHovered: !itemSection
                                        && rootWindow.navDropHoverLabel === itemLabel
                                        && rootWindow.navDropHoverKind === itemKind

    width: treeView.width
    implicitWidth: treeView.width
    implicitHeight: itemSection ? 28 : 34

    Rectangle {
        anchors.fill: parent
        radius: Theme.Metrics.radiusMd
        color: itemSection ? "transparent"
                           : dropHovered
                             ? Theme.AppTheme.selectedSoft
                             : tapArea.pressed
                               ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                               : (rootWindow.selectedSidebarLabel === itemLabel && rootWindow.selectedSidebarKind === itemKind)
                                 ? Theme.AppTheme.selected
                                 : tapArea.containsMouse
                                   ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                   : "transparent"
        border.color: dropHovered
                      ? Theme.AppTheme.accent
                      : tapArea.pressed
                        ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                        : "transparent"
        border.width: (dropHovered || tapArea.pressed) ? 1 : 0
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingMd + depth * 14
        anchors.rightMargin: Theme.Metrics.spacingLg

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: itemSection ? 6 : 8
            spacing: Theme.Metrics.spacingSm

            Item {
                width: 12
                height: 12

                AppIcon {
                    anchors.centerIn: parent
                    visible: hasChildren
                    name: expanded ? "keyboard-arrow-down" : "chevron-right"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: Theme.Metrics.iconXs
                    iconOpacity: 0.65
                }

                MouseArea {
                    anchors.fill: parent
                    visible: hasChildren
                    acceptedButtons: Qt.LeftButton
                    onClicked: treeView.toggleExpanded(row)
                }
            }

            Item {
                visible: !itemSection
                width: 16
                height: 16

                AppIcon {
                    anchors.centerIn: parent
                    name: itemIcon
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 15
                }
            }

            Text {
                text: itemLabel
                color: itemSection ? Theme.AppTheme.muted : Theme.AppTheme.text
                font.pixelSize: itemSection ? 11 : 13
                font.bold: itemSection
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    DropArea {
        anchors.fill: parent

        onEntered: function(drag) {
            var ok = !itemSection && !hasChildren
            drag.accepted = ok
            if (ok)
                rootWindow.setNavDropHover(itemLabel, itemKind)
        }

        onExited: function(drag) {
            rootWindow.clearNavDropHover(itemLabel, itemKind)
        }

        onDropped: function(drop) {
            if (!itemSection) {
                drop.accepted = true
                rootWindow.handleDroppedItem(itemLabel, itemKind)
                rootWindow.clearNavDropHover(itemLabel, itemKind)
            }
        }
    }

    MouseArea {
        id: tapArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button !== Qt.LeftButton)
                return

            if (hasChildren)
                treeView.toggleExpanded(row)
            else
                rootWindow.openLocation(itemLabel, itemIcon, itemKind)
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton && !itemSection) {
                rootWindow.contextSidebarLabel = itemLabel
                rootWindow.contextSidebarKind = itemKind
                rootWindow.contextSidebarIcon = itemIcon
                sidebarContextMenu.popup()
            }
        }
    }
}