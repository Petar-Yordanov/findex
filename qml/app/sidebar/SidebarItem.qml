import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: root

    required property var viewModel
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

    required property string label
    required property string icon
    required property string kind
    required property string path
    required property bool section

    readonly property string itemLabel: label || ""
    readonly property string itemIcon: icon || ""
    readonly property string itemKind: kind || ""
    readonly property string itemPath: path || ""
    readonly property bool itemSection: section === true
    readonly property bool acceptsDrop: !itemSection && itemPath !== ""

    readonly property bool selectedState: viewModel
        ? viewModel.isSelected(itemLabel, itemKind)
        : false

    readonly property bool hoverState: viewModel
        ? viewModel.isHovered(itemLabel, itemKind)
        : false

    width: treeView ? treeView.availableWidth : 0
    implicitWidth: width
    implicitHeight: itemSection ? 28 : 34

    Rectangle {
        anchors.fill: parent
        radius: Theme.Metrics.radiusMd
        color: itemSection ? "transparent"
                           : itemDropArea.containsDrag
                             ? Theme.AppTheme.selected
                             : hoverState
                               ? Theme.AppTheme.selectedSoft
                               : tapArea.pressed
                                 ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                 : selectedState
                                   ? Theme.AppTheme.selected
                                   : tapArea.containsMouse
                                     ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                     : "transparent"

        border.color: itemDropArea.containsDrag
                      ? Theme.AppTheme.accent
                      : hoverState
                        ? Theme.AppTheme.accent
                        : tapArea.pressed
                          ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                          : "transparent"

        border.width: (itemDropArea.containsDrag || hoverState || tapArea.pressed) ? 1 : 0
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingMd + depth * 14
        anchors.rightMargin: Theme.Metrics.spacingLg

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
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
                visible: !itemSection && itemIcon !== ""
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
                anchors.verticalCenter: parent.verticalCenter
                text: itemLabel
                color: itemSection ? Theme.AppTheme.muted : Theme.AppTheme.text
                font.pixelSize: itemSection ? 11 : 13
                font.bold: itemSection
                elide: Text.ElideRight
                width: Math.max(0, parent.width - x)
            }
        }
    }

    DropArea {
        id: itemDropArea
        anchors.fill: parent
        enabled: acceptsDrop && appWorkspaceViewModel && appWorkspaceViewModel.draggingItems

        onDropped: function(drop) {
            if (!appWorkspaceViewModel || !appWorkspaceViewModel.canDropToPath(itemPath))
                return
            appWorkspaceViewModel.requestDropToPath(itemPath, itemKind)
            appWorkspaceViewModel.finishFileDrag(true)
            drop.accept(Qt.MoveAction)
        }
    }

    MouseArea {
        id: tapArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            if (viewModel && !itemSection)
                viewModel.setHoveredItem(itemLabel, itemKind)
        }

        onExited: {
            if (viewModel && !itemSection)
                viewModel.clearHoveredItem(itemLabel, itemKind)
        }

        onClicked: function(mouse) {
            if (mouse.button !== Qt.LeftButton)
                return

            if (hasChildren) {
                treeView.toggleExpanded(row)
                return
            }

            if (itemSection)
                return

            if (viewModel)
                viewModel.openLocation(itemLabel, itemIcon, itemKind, itemPath)
        }

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton && !itemSection && viewModel) {
                viewModel.setContextItem(itemLabel, itemIcon, itemKind, itemPath)
                var p = tapArea.mapToItem(sidebarContextMenu.parent, mouse.x, mouse.y)
                sidebarContextMenu.popupAt(p.x, p.y)
            }
        }
    }
}