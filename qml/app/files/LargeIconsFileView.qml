import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root
    required property var viewModel
    color: "transparent"

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function columnsCount() {
        return Math.max(1, Math.floor(fileGrid.width / fileGrid.cellWidth))
    }

    function pointToIndex(contentX, contentY) {
        if (!viewModel || !viewModel.fileModel)
            return -1

        var count = viewModel.fileModel.rowCount()
        if (count <= 0)
            return -1

        var col = Math.floor(contentX / fileGrid.cellWidth)
        var row = Math.floor(contentY / fileGrid.cellHeight)

        if (col < 0)
            col = 0
        if (row < 0)
            row = 0

        var idx = row * columnsCount() + col
        return clamp(idx, 0, count - 1)
    }

    function rowsIntersectingSelection(x1, y1, x2, y2) {
        if (!viewModel || !viewModel.fileModel)
            return []

        var count = viewModel.fileModel.rowCount()
        if (count <= 0)
            return []

        var left = Math.min(x1, x2)
        var right = Math.max(x1, x2)
        var top = Math.min(y1, y2)
        var bottom = Math.max(y1, y2)

        var cols = columnsCount()
        var rows = []

        for (var i = 0; i < count; ++i) {
            var col = i % cols
            var row = Math.floor(i / cols)

            var itemLeft = col * fileGrid.cellWidth
            var itemTop = row * fileGrid.cellHeight
            var itemRight = itemLeft + fileGrid.cellWidth
            var itemBottom = itemTop + fileGrid.cellHeight

            var intersects =
                right > itemLeft &&
                left < itemRight &&
                bottom > itemTop &&
                top < itemBottom

            if (intersects)
                rows.push(i)
        }

        return rows
    }

    GridView {
        id: fileGrid
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        model: viewModel ? viewModel.fileModel : null
        cellWidth: 118
        cellHeight: 102
        boundsBehavior: Flickable.StopAtBounds
        interactive: !(viewModel && viewModel.dragSelecting)

        ScrollBar.vertical: ExplorerScrollbarV {}

        SelectionBand {
            id: selectionBand
            parent: fileGrid.contentItem
            active: overlay.dragActive || dragState.dragActive
            startX: overlay.dragActive ? overlay.startX : dragState.startX
            startY: overlay.dragActive ? overlay.startY : dragState.startY
            currentX: overlay.dragActive ? overlay.currentX : dragState.currentX
            currentY: overlay.dragActive ? overlay.currentY : dragState.currentY
        }

        QtObject {
            id: dragState
            property bool dragActive: false
            property real startX: 0
            property real startY: 0
            property real currentX: 0
            property real currentY: 0
        }

        delegate: Rectangle {
            required property int index
            required property string name
            required property string icon

            readonly property bool selectedState: {
                const rev = viewModel ? viewModel.selectionRevision : 0
                return viewModel ? viewModel.isRowSelected(index) : false
            }

            width: 104
            height: 92
            radius: 10

            color: selectedState
                   ? Theme.AppTheme.selected
                   : mouseArea.containsMouse
                     ? Theme.AppTheme.selectedSoft
                     : "transparent"

            border.color: selectedState ? Theme.AppTheme.accent : "transparent"
            border.width: selectedState ? 1 : 0

            Column {
                anchors.centerIn: parent
                spacing: 8

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: icon
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 28
                }

                Text {
                    width: 88
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: name
                    color: Theme.AppTheme.text
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true

                property real pressX: 0
                property real pressY: 0
                property bool dragStarted: false
                property bool suppressNextClick: false

                onPressed: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    pressX = mouse.x
                    pressY = mouse.y
                    dragStarted = false

                    var p = mouseArea.mapToItem(fileGrid.contentItem, mouse.x, mouse.y)
                    dragState.startX = p.x
                    dragState.startY = p.y
                    dragState.currentX = p.x
                    dragState.currentY = p.y
                    dragState.dragActive = false
                }

                onPositionChanged: function(mouse) {
                    if (!(mouse.buttons & Qt.LeftButton))
                        return

                    if (mouse.modifiers & Qt.ControlModifier)
                        return

                    var p = mouseArea.mapToItem(fileGrid.contentItem, mouse.x, mouse.y)
                    dragState.currentX = p.x
                    dragState.currentY = p.y

                    if (!dragStarted) {
                        if (Math.abs(mouse.x - pressX) < 6 && Math.abs(mouse.y - pressY) < 6)
                            return

                        dragStarted = true
                        suppressNextClick = true
                        dragState.dragActive = true
                        viewModel.beginDragSelection(index)
                    }

                    var rows = root.rowsIntersectingSelection(
                        dragState.startX,
                        dragState.startY,
                        dragState.currentX,
                        dragState.currentY
                    )

                    if (rows.length > 0)
                        viewModel.replaceSelectionRows(rows, rows[rows.length - 1], index)
                }

                onReleased: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (dragStarted)
                        viewModel.endDragSelection()

                    dragState.dragActive = false
                }

                onCanceled: {
                    dragStarted = false
                    suppressNextClick = false
                    dragState.dragActive = false
                    viewModel.endDragSelection()
                }

                onClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (suppressNextClick) {
                        suppressNextClick = false
                        dragStarted = false
                        return
                    }

                    viewModel.clickRow(index, mouse.modifiers)
                }

                onDoubleClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    dragStarted = false
                    suppressNextClick = false
                    dragState.dragActive = false
                    viewModel.endDragSelection()
                    viewModel.openRow(index)
                }
            }
        }

        MouseArea {
            id: overlay
            anchors.fill: parent
            z: 1000
            acceptedButtons: Qt.LeftButton
            hoverEnabled: false
            enabled: true

            property real pressX: 0
            property real pressY: 0
            property real startX: 0
            property real startY: 0
            property real currentX: 0
            property real currentY: 0
            property bool dragActive: false
            property bool pressedOnItem: false
            property int anchorIndex: -1

            onPressed: function(mouse) {
                var idx = fileGrid.indexAt(mouse.x, mouse.y)
                pressedOnItem = idx >= 0

                if (pressedOnItem) {
                    mouse.accepted = false
                    return
                }

                pressX = mouse.x
                pressY = mouse.y

                var p = overlay.mapToItem(fileGrid.contentItem, mouse.x, mouse.y)
                startX = p.x
                startY = p.y
                currentX = p.x
                currentY = p.y
                dragActive = false
                anchorIndex = -1
            }

            onPositionChanged: function(mouse) {
                if (pressedOnItem) {
                    mouse.accepted = false
                    return
                }

                if (!(mouse.buttons & Qt.LeftButton))
                    return

                if (Math.abs(mouse.x - pressX) < 6 && Math.abs(mouse.y - pressY) < 6)
                    return

                var p = overlay.mapToItem(fileGrid.contentItem, mouse.x, mouse.y)
                currentX = p.x
                currentY = p.y

                var rows = root.rowsIntersectingSelection(startX, startY, currentX, currentY)
                if (rows.length <= 0)
                    return

                if (!dragActive) {
                    dragActive = true
                    anchorIndex = rows[0]
                    viewModel.beginDragSelection(anchorIndex)
                }

                viewModel.replaceSelectionRows(rows, rows[rows.length - 1], anchorIndex)
            }

            onReleased: function(mouse) {
                if (pressedOnItem) {
                    pressedOnItem = false
                    mouse.accepted = false
                    return
                }

                if (dragActive)
                    viewModel.endDragSelection()

                dragActive = false
                anchorIndex = -1
                pressedOnItem = false
            }

            onCanceled: {
                if (dragActive)
                    viewModel.endDragSelection()

                dragActive = false
                anchorIndex = -1
                pressedOnItem = false
            }
        }
    }
}