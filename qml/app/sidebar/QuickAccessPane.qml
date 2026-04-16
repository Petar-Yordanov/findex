import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root

    required property var viewModel
    required property var sidebarContextMenu

    Layout.fillWidth: true
    Layout.preferredHeight: 280
    Layout.minimumHeight: 180

    radius: Theme.Metrics.radiusLg
    color: Theme.AppTheme.isDark ? "#131923" : "#f8fafc"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingSm
        spacing: Theme.Metrics.spacingSm

        Text {
            text: "Quick Access"
            color: Theme.AppTheme.muted
            font.pixelSize: 11
            font.bold: true
            Layout.leftMargin: Theme.Metrics.spacingSm
            Layout.rightMargin: Theme.Metrics.spacingSm
            Layout.topMargin: Theme.Metrics.spacingXs
        }

        ListView {
            id: quickAccessList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds
            model: root.viewModel ? root.viewModel.quickAccessModel : null

            ScrollBar.vertical: ExplorerScrollbarV {
                id: quickAccessScrollBar
            }

            delegate: Rectangle {
                required property string label
                required property string path
                required property string icon
                required property string kind

                readonly property bool selectedState: root.viewModel
                    ? root.viewModel.isSelected(label, kind, path)
                    : false

                readonly property bool hoverState: root.viewModel
                    ? root.viewModel.isHovered(label, kind, path)
                    : false

                width: ListView.view
                    ? ListView.view.width - (quickAccessScrollBar.visible ? quickAccessScrollBar.width + Theme.Metrics.spacingSm : 0)
                    : 0
                height: 34
                radius: Theme.Metrics.radiusMd

                color: hoverState
                    ? Theme.AppTheme.selectedSoft
                    : quickAccessMouseArea.pressed
                      ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                      : selectedState
                        ? Theme.AppTheme.selected
                        : quickAccessMouseArea.containsMouse
                          ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                          : "transparent"

                border.color: selectedState
                    ? Theme.AppTheme.accent
                    : hoverState
                      ? Theme.AppTheme.accent
                      : quickAccessMouseArea.pressed
                        ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                        : "transparent"

                border.width: (selectedState || hoverState || quickAccessMouseArea.pressed) ? 1 : 0

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.Metrics.spacingMd
                    anchors.rightMargin: Theme.Metrics.spacingMd
                    spacing: Theme.Metrics.spacingSm

                    AppIcon {
                        id: quickAccessIcon
                        name: icon
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: label
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, parent.width - quickAccessIcon.width - parent.spacing)
                    }
                }

                MouseArea {
                    id: quickAccessMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true

                    onEntered: {
                        if (root.viewModel)
                            root.viewModel.setHoveredItem(label, kind, path)
                    }

                    onExited: {
                        if (root.viewModel)
                            root.viewModel.clearHoveredItem(label, kind, path)
                    }

                    onClicked: function(mouse) {
                        if (!root.viewModel || mouse.button !== Qt.LeftButton)
                            return

                        root.viewModel.openLocation(label, icon, kind, path)
                    }

                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton && root.viewModel) {
                            root.viewModel.setContextItem(label, icon, kind, path)
                            var p = quickAccessMouseArea.mapToItem(root.sidebarContextMenu.parent, mouse.x, mouse.y)
                            root.sidebarContextMenu.popupAt(p.x, p.y)
                        }
                    }
                }
            }
        }
    }
}
