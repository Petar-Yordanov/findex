import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import "../../components/foundation"
import "../../components/theme" as Theme
import "./tabs" as Tabs

Rectangle {
    id: titleBar

    required property var rootWindow
    required property var viewModel
    required property var tabContextMenu

    color: Theme.AppTheme.titleBg
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton

        onPressed: function(mouse) {
            if (titleBar.viewModel && titleBar.viewModel.editingIndex >= 0)
                titleBar.viewModel.cancelRenameTab()

            if (mouse.button === Qt.LeftButton)
                titleBar.rootWindow.startSystemMove()
        }

        onDoubleClicked: {
            if (titleBar.viewModel && titleBar.viewModel.editingIndex >= 0)
                titleBar.viewModel.cancelRenameTab()

            if (titleBar.rootWindow.visibility === Window.Maximized)
                titleBar.rootWindow.showNormal()
            else
                titleBar.rootWindow.showMaximized()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingLg
        anchors.rightMargin: Theme.Metrics.spacingSm
        anchors.topMargin: 4
        anchors.bottomMargin: 2
        spacing: Theme.Metrics.spacingSm
        z: 1

        Tabs.TabStrip {
            Layout.fillWidth: true
            Layout.fillHeight: true

            rootWindow: titleBar.rootWindow
            viewModel: titleBar.viewModel
            tabContextMenu: titleBar.tabContextMenu
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            WindowButton {
                iconName: "minimize"
                darkTheme: Theme.AppTheme.isDark
                onClicked: {
                    if (titleBar.viewModel && titleBar.viewModel.editingIndex >= 0)
                        titleBar.viewModel.cancelRenameTab()
                    titleBar.rootWindow.showMinimized()
                }
            }

            WindowButton {
                iconName: titleBar.rootWindow.visibility === Window.Maximized
                          ? "filter-none"
                          : "check-box-outline-blank"
                darkTheme: Theme.AppTheme.isDark
                onClicked: {
                    if (titleBar.viewModel && titleBar.viewModel.editingIndex >= 0)
                        titleBar.viewModel.cancelRenameTab()

                    if (titleBar.rootWindow.visibility === Window.Maximized)
                        titleBar.rootWindow.showNormal()
                    else
                        titleBar.rootWindow.showMaximized()
                }
            }

            WindowButton {
                iconName: "close"
                darkTheme: Theme.AppTheme.isDark
                hoverColor: "#d85b5b"
                pressedColor: "#c94c4c"
                onClicked: {
                    if (titleBar.viewModel && titleBar.viewModel.editingIndex >= 0)
                        titleBar.viewModel.cancelRenameTab()
                    titleBar.rootWindow.close()
                }
            }
        }
    }
}