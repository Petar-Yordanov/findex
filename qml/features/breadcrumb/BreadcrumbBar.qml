import QtQuick
import QtQuick.Controls
import "../../components/theme" as Theme

Item {
    required property var rootWindow
    required property var pathModel
    required property var breadcrumbContextMenu
    required property var pathField

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

                delegate: BreadcrumbItem {
                    rootWindow: parent.parent.parent.parent.rootWindow
                    modelData: modelData
                    index: index
                    breadcrumbContextMenu: parent.parent.parent.parent.breadcrumbContextMenu
                    pathField: parent.parent.parent.parent.pathField
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