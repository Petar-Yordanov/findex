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

            if (right > itemLeft && left < itemRight && bottom > itemTop && top < itemBottom)
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
        interactive: !(viewModel && viewModel.dragSelecting) && !overlay.pointerArmed

        ScrollBar.vertical: ExplorerScrollbarV {}

        SelectionBand {
            id: selectionBand
            parent: fileGrid.contentItem
            active: overlay.dragActive
            startX: overlay.startX
            startY: overlay.startY
            currentX: overlay.currentX
            currentY: overlay.currentY
        }

        delegate: Rectangle {
            required property int index
            required property string name
            required property string path
            required property string icon
            required property bool isDir

            readonly property bool selectedState: {
                const rev = viewModel ? viewModel.selectionRevision : 0
                return viewModel ? viewModel.isRowSelected(index) : false
            }

            width: 104
            height: 92
            radius: 10

            color: folderDropArea.containsDrag
                   ? Theme.AppTheme.selected
                   : selectedState
                     ? Theme.AppTheme.selected
                     : mouseArea.containsMouse
                       ? Theme.AppTheme.selectedSoft
                       : "transparent"

            border.color: folderDropArea.containsDrag
                          ? Theme.AppTheme.accent
                          : selectedState ? Theme.AppTheme.accent : "transparent"
            border.width: (folderDropArea.containsDrag || selectedState) ? 1 : 0

            Item {
                id: dragProxy
                visible: false
                Drag.active: mouseArea.fileDragActive
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.MoveAction
                Drag.hotSpot.x: 20
                Drag.hotSpot.y: 20
                Drag.mimeData: {
                    "text/plain": viewModel ? viewModel.draggedPathsText : ""
                }
            }

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

            DropArea {
                id: folderDropArea
                anchors.fill: parent
                enabled: isDir && viewModel && viewModel.draggingItems && !viewModel.isOnlyDraggingRow(index)

                onDropped: function(drop) {
                    if (!viewModel || !viewModel.canDropOnRow(index))
                        return
                    viewModel.dropOnRow(index)
                    viewModel.finishFileDrag(true)
                    drop.accept(Qt.MoveAction)
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true

                drag.target: dragProxy
                drag.axis: Drag.XAndYAxis
                drag.threshold: 8

                property bool fileDragActive: false
                property bool dragStarted: false
                property bool suppressNextClick: false
                property bool pressStartedOnSelectedItem: false
                property real pressX: 0
                property real pressY: 0

                onPressed: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (mouse.modifiers & Qt.AltModifier) {
                        fileDragActive = false
                        dragStarted = false
                        suppressNextClick = false
                        pressStartedOnSelectedItem = false
                        dragProxy.x = 0
                        dragProxy.y = 0
                        mouse.accepted = false
                        return
                    }

                    fileDragActive = false
                    dragStarted = false
                    suppressNextClick = false
                    pressX = mouse.x
                    pressY = mouse.y
                    pressStartedOnSelectedItem = viewModel ? viewModel.isRowSelected(index) : false
                }

                onPositionChanged: function(mouse) {
                    if (!(mouse.buttons & Qt.LeftButton))
                        return

                    if (mouse.modifiers & Qt.AltModifier)
                        return
                    if (mouse.modifiers & Qt.ControlModifier)
                        return
                    if (mouse.modifiers & Qt.ShiftModifier)
                        return

                    if (Math.abs(mouse.x - pressX) < 6 && Math.abs(mouse.y - pressY) < 6)
                        return

                    if (!dragStarted) {
                        dragStarted = true
                        suppressNextClick = true

                        if (viewModel && !pressStartedOnSelectedItem)
                            viewModel.selectOnlyRow(index)

                        if (viewModel)
                            viewModel.startFileDrag(index, mouse.modifiers)

                        fileDragActive = true
                    }
                }

                onReleased: function(mouse) {
                    dragProxy.x = 0
                    dragProxy.y = 0

                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (mouse.modifiers & Qt.AltModifier) {
                        fileDragActive = false
                        dragStarted = false
                        suppressNextClick = false
                        pressStartedOnSelectedItem = false
                        return
                    }

                    if (fileDragActive && viewModel)
                        viewModel.finishFileDrag(false)

                    fileDragActive = false
                    dragStarted = false
                    pressStartedOnSelectedItem = false
                }

                onCanceled: {
                    dragProxy.x = 0
                    dragProxy.y = 0
                    fileDragActive = false
                    dragStarted = false
                    suppressNextClick = false
                    pressStartedOnSelectedItem = false
                    if (viewModel)
                        viewModel.cancelFileDrag()
                }

                onClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (mouse.modifiers & Qt.AltModifier)
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

                    if (mouse.modifiers & Qt.AltModifier)
                        return

                    fileDragActive = false
                    dragStarted = false
                    suppressNextClick = false
                    pressStartedOnSelectedItem = false
                    if (viewModel)
                        viewModel.cancelFileDrag()
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
            preventStealing: true

            property real pressX: 0
            property real pressY: 0
            property real startX: 0
            property real startY: 0
            property real currentX: 0
            property real currentY: 0
            property bool dragActive: false
            property bool pointerArmed: false
            property bool forcedMarquee: false
            property bool pressedOnItem: false
            property int anchorIndex: -1

            onPressed: function(mouse) {
                forcedMarquee = (mouse.modifiers & Qt.AltModifier) !== 0
                var idx = fileGrid.indexAt(mouse.x, mouse.y)
                pressedOnItem = idx >= 0
                pointerArmed = forcedMarquee || !pressedOnItem

                if (!pointerArmed) {
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
                if (!pointerArmed) {
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
                if (!pointerArmed) {
                    mouse.accepted = false
                    return
                }

                if (dragActive)
                    viewModel.endDragSelection()

                dragActive = false
                pointerArmed = false
                forcedMarquee = false
                pressedOnItem = false
                anchorIndex = -1
            }

            onCanceled: {
                if (dragActive)
                    viewModel.endDragSelection()

                dragActive = false
                pointerArmed = false
                forcedMarquee = false
                pressedOnItem = false
                anchorIndex = -1
            }
        }
    }
}