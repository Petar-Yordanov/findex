import QtQuick
import QtQuick.Controls
import "../../components/theme" as Theme

Rectangle {
    required property var rootWindow
    required property Item mapTarget
    required property var fileViewLoader

    color: Theme.AppTheme.surface2
    border.color: Theme.AppTheme.borderSoft
    border.width: Theme.Metrics.borderWidth

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.Metrics.spacingLg
        anchors.rightMargin: Theme.Metrics.spacingLg

        ResizableHeaderCell {
            x: 0
            y: 0
            titleText: "Name"
            widthValue: rootWindow.detailsNameWidth
            showSortIcon: rootWindow.sortColumn === 0
            sortAscending: rootWindow.sortAscending
            sortHandler: function() { rootWindow.sortFiles(0) }
            mapTarget: parent.parent.mapTarget
            minimumWidth: 180
            resizeHandler: function(dx) {
                rootWindow.detailsNameWidth = Math.max(180, rootWindow.detailsNameWidth + dx)
                if (fileViewLoader.item && fileViewLoader.item.relayout)
                    fileViewLoader.item.relayout()
            }
        }

        ResizableHeaderCell {
            x: rootWindow.detailsNameWidth
            y: 0
            titleText: "Date modified"
            widthValue: rootWindow.detailsDateWidth
            showSortIcon: rootWindow.sortColumn === 1
            sortAscending: rootWindow.sortAscending
            sortHandler: function() { rootWindow.sortFiles(1) }
            mapTarget: parent.parent.mapTarget
            minimumWidth: 160
            resizeHandler: function(dx) {
                rootWindow.detailsDateWidth = Math.max(160, rootWindow.detailsDateWidth + dx)
                if (fileViewLoader.item && fileViewLoader.item.relayout)
                    fileViewLoader.item.relayout()
            }
        }

        ResizableHeaderCell {
            x: rootWindow.detailsNameWidth + rootWindow.detailsDateWidth
            y: 0
            titleText: "Type"
            widthValue: rootWindow.detailsTypeWidth
            showSortIcon: rootWindow.sortColumn === 2
            sortAscending: rootWindow.sortAscending
            sortHandler: function() { rootWindow.sortFiles(2) }
            mapTarget: parent.parent.mapTarget
            minimumWidth: 140
            resizeHandler: function(dx) {
                rootWindow.detailsTypeWidth = Math.max(140, rootWindow.detailsTypeWidth + dx)
                if (fileViewLoader.item && fileViewLoader.item.relayout)
                    fileViewLoader.item.relayout()
            }
        }

        ResizableHeaderCell {
            x: rootWindow.detailsNameWidth + rootWindow.detailsDateWidth + rootWindow.detailsTypeWidth
            y: 0
            titleText: "Size"
            widthValue: Math.max(0, parent.width - x)
            showSortIcon: rootWindow.sortColumn === 3
            sortAscending: rootWindow.sortAscending
            sortHandler: function() { rootWindow.sortFiles(3) }
            mapTarget: parent.parent.mapTarget
            resizable: false
        }
    }
}