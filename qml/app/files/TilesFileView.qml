import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root
    required property var viewModel
    color: "transparent"

    ListView {
        id: fileList
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        spacing: 2
        model: viewModel ? viewModel.fileModel : null
        boundsBehavior: Flickable.StopAtBounds
        interactive: !(viewModel && viewModel.dragSelecting) && !overlay.pointerArmed

        ScrollBar.vertical: ExplorerScrollbarV {
            id: fileScrollBar
        }

        SelectionBand {
            id: selectionBand
            parent: fileList.contentItem
            active: overlay.dragActive
            startX: overlay.startX
            currentX: overlay.currentX
            startY: overlay.startY
            currentY: overlay.currentY
        }

        delegate: Item {
            required property int index
            required property string name
            required property string path
            required property string dateModified
            required property string type
            required property string size
            required property string icon
            required property bool isDir

            readonly property bool selectedState: {
                const rev = viewModel ? viewModel.selectionRevision : 0
                return viewModel ? viewModel.isRowSelected(index) : false
            }

            width: ListView.view.width
            height: 82

            Item {
                id: dragProxy
                visible: false
                width: 1
                height: 1

                Drag.active: mouseArea.fileDragActive
                Drag.dragType: Drag.Internal
                Drag.supportedActions: Qt.MoveAction
                Drag.hotSpot.x: mouseArea.pressX
                Drag.hotSpot.y: mouseArea.pressY
                Drag.mimeData: {
                    "text/plain": viewModel ? viewModel.draggedPathsText : ""
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
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
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 18
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 14

                AppIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: icon
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 34
                }

                Column {
                    width: Math.max(220, parent.width - 420)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: name
                        color: Theme.AppTheme.text
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: "Type: " + type
                        color: Theme.AppTheme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Column {
                    width: 280
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "Date modified: " + dateModified
                        color: Theme.AppTheme.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: "Size: " + (size !== "" ? size : "—")
                        color: Theme.AppTheme.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: parent.width
                    }
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

                function dragPreviewText() {
                    if (!viewModel)
                        return name
                    return viewModel.selectedItems > 1 ? (viewModel.selectedItems + " items") : name
                }

                function pushDragPreview(mouse) {
                    if (!viewModel)
                        return
                    var p = mouseArea.mapToItem(null, mouse.x, mouse.y)
                    if (!viewModel.dragPreviewVisible)
                        viewModel.beginFileDragPreview(p.x, p.y, dragPreviewText(), icon)
                    else
                        viewModel.updateFileDragPreview(p.x, p.y)
                }

                onPressed: function(mouse) {
                    if (mouse.button !== Qt.LeftButton)
                        return

                    if (mouse.modifiers & Qt.AltModifier) {
                        fileDragActive = false
                        dragStarted = false
                        suppressNextClick = false
                        pressStartedOnSelectedItem = false
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

                    if (fileDragActive)
                        pushDragPreview(mouse)
                }

                onReleased: function(mouse) {
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
            property bool pressedInRealEmptyArea: false
            property int anchorIndex: -1

            function isBelowItems(yInView) {
                return yInView > (fileList.contentHeight - fileList.contentY)
            }

            onPressed: function(mouse) {
                forcedMarquee = (mouse.modifiers & Qt.AltModifier) !== 0
                pressedInRealEmptyArea = isBelowItems(mouse.y)
                pointerArmed = forcedMarquee || pressedInRealEmptyArea

                if (!pointerArmed) {
                    mouse.accepted = false
                    return
                }

                pressX = mouse.x
                pressY = mouse.y

                var p = overlay.mapToItem(fileList.contentItem, mouse.x, mouse.y)
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

                var p = overlay.mapToItem(fileList.contentItem, mouse.x, mouse.y)
                currentX = p.x
                currentY = p.y

                var top = Math.min(startY, currentY)
                var bottom = Math.max(startY, currentY)

                var rows = []
                for (var i = 0; i < fileList.count; ++i) {
                    var itemY = i * 84
                    var itemBottom = itemY + 82
                    if (bottom > itemY && top < itemBottom)
                        rows.push(i)
                }

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
                pressedInRealEmptyArea = false
                anchorIndex = -1
            }

            onCanceled: {
                if (dragActive)
                    viewModel.endDragSelection()

                dragActive = false
                pointerArmed = false
                forcedMarquee = false
                pressedInRealEmptyArea = false
                anchorIndex = -1
            }
        }
    }
}