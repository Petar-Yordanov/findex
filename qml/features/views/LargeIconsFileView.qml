import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: largeIconsRoot

    required property var rootWindow
    required property var filesTableModel
    required property var rowContextMenu
    required property var multiSelectionContextMenu
    required property var emptyContextMenu

    property bool selectionActive: false
    property bool selectionMoved: false
    property real selectionStartX: 0
    property real selectionStartY: 0
    property real selectionCurrentX: 0
    property real selectionCurrentY: 0

    readonly property int delegateWidth: 104
    readonly property int delegateHeight: 92

    function rowsArray() {
        return (filesTableModel && filesTableModel.rows) ? filesTableModel.rows : []
    }

    function clampX(x) {
        return Math.max(0, Math.min(width, x))
    }

    function clampY(y) {
        return Math.max(0, Math.min(height, y))
    }

    function columnCount() {
        return Math.max(1, Math.floor(gridView.width / gridView.cellWidth))
    }

    function itemRectFor(index) {
        var cols = columnCount()
        var col = index % cols
        var row = Math.floor(index / cols)

        var x = col * gridView.cellWidth + Math.floor((gridView.cellWidth - delegateWidth) / 2)
        var y = row * gridView.cellHeight + Math.floor((gridView.cellHeight - delegateHeight) / 2)

        return {
            x: x,
            y: y,
            w: delegateWidth,
            h: delegateHeight
        }
    }

    function contentHitRectFor(index) {
        var r = itemRectFor(index)

        return {
            x: r.x + 8,
            y: r.y + 6,
            w: r.w - 16,
            h: r.h - 12
        }
    }

    function updateBandSelection() {
        var left = Math.min(selectionStartX, selectionCurrentX) + gridView.contentX
        var right = Math.max(selectionStartX, selectionCurrentX) + gridView.contentX
        var top = Math.min(selectionStartY, selectionCurrentY) + gridView.contentY
        var bottom = Math.max(selectionStartY, selectionCurrentY) + gridView.contentY

        var next = {}
        var rows = rowsArray()

        for (var i = 0; i < rows.length; ++i) {
            var r = itemRectFor(i)
            var itemLeft = r.x
            var itemRight = r.x + r.w
            var itemTop = r.y
            var itemBottom = r.y + r.h

            if (right >= itemLeft && left <= itemRight
                    && bottom >= itemTop && top <= itemBottom) {
                next[i] = true
            }
        }

        rootWindow.selectedFileRows = next

        var first = -1
        for (var k in next) {
            first = parseInt(k, 10)
            break
        }
        rootWindow.currentFileRow = first
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        clip: true
        model: largeIconsRoot.rowsArray()
        cellWidth: 118
        cellHeight: 102
        interactive: !largeIconsRoot.selectionActive
        boundsBehavior: Flickable.StopAtBounds
        pixelAligned: true
        maximumFlickVelocity: 2200
        flickDeceleration: 9000

        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
        ScrollBar.horizontal: null

        MouseArea {
            id: gridOverlayMouse
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: false
            preventStealing: true

            property bool bandSelecting: false
            property bool pendingEmptyContextMenu: false

            function pointHitsRealItem(xInView, yInView) {
                var xInContent = xInView + gridView.contentX
                var yInContent = yInView + gridView.contentY
                var rows = largeIconsRoot.rowsArray()

                for (var i = 0; i < rows.length; ++i) {
                    var r = largeIconsRoot.contentHitRectFor(i)
                    if (xInContent >= r.x && xInContent <= (r.x + r.w)
                            && yInContent >= r.y && yInContent <= (r.y + r.h)) {
                        return true
                    }
                }

                return false
            }

            onPressed: function(mouse) {
                if (rootWindow.editingFileRow >= 0)
                    rootWindow.commitRenameRow(rootWindow.editingFileRow, rootWindow.editingFileNameDraft)

                var overItem = pointHitsRealItem(mouse.x, mouse.y)

                var bothButtons =
                        (gridOverlayMouse.pressedButtons & Qt.LeftButton)
                        && (gridOverlayMouse.pressedButtons & Qt.RightButton)

                bandSelecting = bothButtons || (mouse.button === Qt.LeftButton && !overItem)
                pendingEmptyContextMenu = (mouse.button === Qt.RightButton && !overItem && !bothButtons)

                if (bandSelecting) {
                    largeIconsRoot.selectionActive = true
                    largeIconsRoot.selectionMoved = false
                    largeIconsRoot.selectionStartX = largeIconsRoot.clampX(mouse.x)
                    largeIconsRoot.selectionStartY = largeIconsRoot.clampY(mouse.y)
                    largeIconsRoot.selectionCurrentX = largeIconsRoot.selectionStartX
                    largeIconsRoot.selectionCurrentY = largeIconsRoot.selectionStartY
                    rootWindow.clearFileSelection()
                    rootWindow.contextFileRow = -1
                    mouse.accepted = true
                    return
                }

                if (pendingEmptyContextMenu) {
                    rootWindow.clearFileSelection()
                    mouse.accepted = true
                    return
                }

                mouse.accepted = false
            }

            onPositionChanged: function(mouse) {
                if (!bandSelecting || !largeIconsRoot.selectionActive)
                    return

                largeIconsRoot.selectionCurrentX = largeIconsRoot.clampX(mouse.x)
                largeIconsRoot.selectionCurrentY = largeIconsRoot.clampY(mouse.y)

                if (Math.abs(largeIconsRoot.selectionCurrentX - largeIconsRoot.selectionStartX) > 2
                        || Math.abs(largeIconsRoot.selectionCurrentY - largeIconsRoot.selectionStartY) > 2) {
                    largeIconsRoot.selectionMoved = true
                }

                largeIconsRoot.updateBandSelection()
            }

            onReleased: function(mouse) {
                if (pendingEmptyContextMenu && !largeIconsRoot.selectionMoved) {
                    rootWindow.contextFileRow = -1
                    emptyContextMenu.popup()
                }

                bandSelecting = false
                pendingEmptyContextMenu = false
                largeIconsRoot.selectionActive = false
                largeIconsRoot.selectionMoved = false
            }

            onCanceled: {
                bandSelecting = false
                pendingEmptyContextMenu = false
                largeIconsRoot.selectionActive = false
                largeIconsRoot.selectionMoved = false
            }
        }

        delegate: Rectangle {
            id: gridDelegate
            required property int index
            required property var modelData

            property real pressX: 0
            property real pressY: 0
            property bool dragStarted: false

            width: 104
            height: 92
            radius: 10

            readonly property bool isFolderTarget: modelData.type === "File folder"
            readonly property bool sameAsDragged: rootWindow.isDraggedRow(index)

            color: rootWindow.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                   ? Theme.AppTheme.selectedSoft
                   : rootWindow.isFileRowSelected(index)
                     ? Theme.AppTheme.selected
                     : gridMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
            border.color: rootWindow.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                          ? Theme.AppTheme.accent
                          : "transparent"
            border.width: rootWindow.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged ? Theme.Metrics.borderWidth : 0

            Column {
                anchors.centerIn: parent
                spacing: 8

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: modelData.icon
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 28
                }

                Text {
                    visible: rootWindow.editingFileRow !== index
                    width: 88
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: modelData.name
                    color: Theme.AppTheme.text
                    font.pixelSize: 12
                }

                TextField {
                    visible: rootWindow.editingFileRow === index
                    width: 88
                    height: 24
                    text: rootWindow.editingFileNameDraft
                    color: Theme.AppTheme.text
                    font.pixelSize: 12
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    leftPadding: 6
                    rightPadding: 6
                    topPadding: 0
                    bottomPadding: 0

                    background: Rectangle {
                        radius: 6
                        color: Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
                        border.color: Theme.AppTheme.accent
                        border.width: 1
                    }

                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus()
                            selectAll()
                        }
                    }

                    onTextChanged: {
                        if (visible)
                            rootWindow.editingFileNameDraft = text
                    }

                    onAccepted: rootWindow.commitRenameRow(index, rootWindow.editingFileNameDraft)

                    onActiveFocusChanged: {
                        if (!activeFocus && visible)
                            rootWindow.commitRenameRow(index, rootWindow.editingFileNameDraft)
                    }

                    Keys.onEscapePressed: rootWindow.cancelRenameRow()
                }
            }

            DropArea {
                anchors.fill: parent

                onEntered: function(drag) {
                    var ok = gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                    drag.accepted = ok
                    if (ok)
                        rootWindow.detailsDropHoverRow = index
                }

                onExited: function(drag) {
                    if (rootWindow.detailsDropHoverRow === index)
                        rootWindow.detailsDropHoverRow = -1
                }

                onDropped: function(drop) {
                    if (gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged) {
                        drop.accepted = true
                        rootWindow.handleDroppedItem(modelData.name, "folder")
                    }

                    if (rootWindow.detailsDropHoverRow === index)
                        rootWindow.detailsDropHoverRow = -1
                }
            }

            MouseArea {
                id: gridMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true

                drag.target: dragProxy
                drag.axis: Drag.XAndYAxis
                drag.smoothed: false

                onClicked: function(mouse) {
                    mouse.accepted = true
                }

                onPressed: function(mouse) {
                    if (rootWindow.editingFileRow >= 0 && rootWindow.editingFileRow !== index)
                        rootWindow.commitRenameRow(rootWindow.editingFileRow, rootWindow.editingFileNameDraft)

                    var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                    var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                    var alreadySelected = rootWindow.isFileRowSelected(index)

                    if (mouse.button === Qt.RightButton) {
                        if (!alreadySelected)
                            rootWindow.selectOnlyFileRow(index)

                        rootWindow.contextFileRow = index

                        if (rootWindow.selectedFileCount() > 1)
                            multiSelectionContextMenu.popup()
                        else
                            rowContextMenu.popup()

                        return
                    }

                    if (mouse.button === Qt.LeftButton) {
                        if (shift) {
                            var anchor = rootWindow.selectionAnchorRow >= 0 ? rootWindow.selectionAnchorRow : index
                            rootWindow.selectFileRange(anchor, index, true)
                        } else if (ctrl) {
                            rootWindow.toggleFileRowSelection(index)
                        } else {
                            if (!alreadySelected)
                                rootWindow.selectOnlyFileRow(index)
                        }

                        if (!ctrl && !shift && rootWindow.isFileRowSelected(index))
                            rootWindow.beginFileDrag(index)
                    }
                }

                onDoubleClicked: {
                    rootWindow.applySnapshot(
                        rootWindow.backend.openItems(
                            rootWindow.singleItemForBackend(index)
                        )
                    )
                }

                Item {
                    id: dragProxy
                    x: 0
                    y: 0
                    width: 24
                    height: 24
                    opacity: 0.01

                    Drag.active: gridMouse.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.MoveAction
                    Drag.source: gridDelegate
                    Drag.hotSpot.x: 18
                    Drag.hotSpot.y: 18
                    Drag.imageSource: rootWindow.dragPreviewReady ? rootWindow.draggedFilePreviewUrl : ""
                    Drag.mimeData: ({
                        "application/x-fileexplorer-item": JSON.stringify({
                            row: index,
                            rows: rootWindow.selectedFileRowsArray(),
                            count: rootWindow.draggedFileCount,
                            name: rootWindow.draggedFileName,
                            type: rootWindow.draggedFileType,
                            icon: rootWindow.draggedFileIcon
                        })
                    })

                    Drag.onDragFinished: function(dropAction) {
                        dragProxy.x = 0
                        dragProxy.y = 0
                        rootWindow.detailsDropHoverRow = -1
                        rootWindow.clearFileDrag()
                    }
                }
            }
        }

        Rectangle {
            visible: largeIconsRoot.selectionActive && largeIconsRoot.selectionMoved
            z: 1001

            x: Math.min(largeIconsRoot.selectionStartX, largeIconsRoot.selectionCurrentX)
            y: Math.min(largeIconsRoot.selectionStartY, largeIconsRoot.selectionCurrentY)
            width: Math.abs(largeIconsRoot.selectionCurrentX - largeIconsRoot.selectionStartX)
            height: Math.abs(largeIconsRoot.selectionCurrentY - largeIconsRoot.selectionStartY)

            color: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)
            border.color: Theme.AppTheme.accent
            border.width: 1
        }
    }
}