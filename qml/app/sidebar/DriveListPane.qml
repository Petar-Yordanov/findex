import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/theme" as Theme
import "../../components/foundation"

Rectangle {
    id: root

    required property var viewModel
    required property var sidebarContextMenu

    Layout.fillWidth: true
    Layout.preferredHeight: 220
    Layout.minimumHeight: 150

    radius: Theme.Metrics.radiusXl
    color: Theme.AppTheme.isDark ? "#171d27" : "#fbfcfd"
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.Metrics.spacingLg
        spacing: Theme.Metrics.spacingMd

        Text {
            text: "Drives"
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.body
            font.bold: true
        }

        ListView {
            id: drivesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds
            model: root.viewModel ? root.viewModel.drivesModel : null

            ScrollBar.vertical: ExplorerScrollbarV {
                id: drivesScrollBar
            }

            delegate: Rectangle {
                required property string label
                required property string path
                required property string icon
                required property double used
                required property double total
                required property string usedText

                width: ListView.view ? ListView.view.width - (drivesScrollBar.visible ? drivesScrollBar.width + Theme.Metrics.spacingSm : 0) : 0
                height: 56
                radius: Theme.Metrics.radiusMd

                readonly property real usedPct: total > 0 ? (used / total) : 0
                readonly property color usedColor: usedPct >= 0.85
                    ? Theme.AppTheme.driveUsedRed
                    : Theme.AppTheme.driveUsedBlue

                color: driveDropArea.containsDrag
                    ? Theme.AppTheme.selected
                    : driveMouseArea.pressed
                      ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                      : driveMouseArea.containsMouse
                        ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                        : "transparent"

                border.color: driveDropArea.containsDrag
                    ? Theme.AppTheme.accent
                    : driveMouseArea.pressed
                      ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                      : "transparent"

                border.width: (driveDropArea.containsDrag || driveMouseArea.pressed) ? 1 : 0

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.Metrics.spacingMd
                    anchors.rightMargin: Theme.Metrics.spacingMd
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 3

                    Row {
                        id: titleRow
                        width: parent.width
                        spacing: Theme.Metrics.spacingSm

                        AppIcon {
                            id: driveIcon
                            name: icon
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: Theme.Metrics.iconSm
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: label
                            color: Theme.AppTheme.text
                            font.pixelSize: Theme.Typography.body
                            font.bold: true
                            elide: Text.ElideRight
                            width: Math.max(0, titleRow.width - driveIcon.width - titleRow.spacing)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 5
                        radius: Theme.Metrics.radiusXs
                        color: Theme.AppTheme.driveFree

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, usedPct))
                            height: parent.height
                            radius: Theme.Metrics.radiusXs
                            color: usedColor
                        }
                    }

                    Text {
                        text: usedText
                        color: Theme.AppTheme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                DropArea {
                    id: driveDropArea
                    anchors.fill: parent
                    enabled: appWorkspaceViewModel && appWorkspaceViewModel.draggingItems

                    onDropped: function(drop) {
                        if (!appWorkspaceViewModel || !appWorkspaceViewModel.canDropToPath(path))
                            return
                        appWorkspaceViewModel.requestDropToPath(path, "drive")
                        drop.accept(Qt.MoveAction)
                    }
                }

                MouseArea {
                    id: driveMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true

                    onClicked: function(mouse) {
                        if (!root.viewModel)
                            return

                        if (mouse.button === Qt.LeftButton)
                            root.viewModel.openLocation(label, icon, "drive", path)
                    }

                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton && root.viewModel) {
                            root.viewModel.setContextItem(label, icon, "drive", path)
                            var p = driveMouseArea.mapToItem(root.sidebarContextMenu.parent, mouse.x, mouse.y)
                            root.sidebarContextMenu.popupAt(p.x, p.y)
                        }
                    }
                }
            }
        }
    }
}