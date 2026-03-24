import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: tilesRoot

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

    FontMetrics {
        id: tilesFontMetrics
        font.pixelSize: 14
    }

    function rowsArray() {
        return (filesTableModel && filesTableModel.rows) ? filesTableModel.rows : []
    }

    function tileHitWidthForName(name) {
        return Math.min(
            Math.max(220, tilesFontMetrics.advanceWidth(name || "") + 110),
            360
        )
    }

    function tileHitRectForRow(row) {
        var rows = rowsArray()
        var item = (row >= 0 && row < rows.length) ? rows[row] : null
        return {
            x: 14,
            y: row * (82 + tilesView.spacing) + 10,
            w: tileHitWidthForName(item ? item.name : ""),
            h: 62
        }
    }

    function tileSelectionRectForRow(row) {
        return {
            x: 0,
            y: row * (82 + tilesView.spacing),
            w: tilesView.width,
            h: 82
        }
    }

    function clampX(x) {
        return Math.max(0, Math.min(width, x))
    }

    function clampY(y) {
        return Math.max(0, Math.min(height, y))
    }

    function updateBandSelection() {
        var left = Math.min(selectionStartX, selectionCurrentX)
        var right = Math.max(selectionStartX, selectionCurrentX)
        var top = Math.min(selectionStartY, selectionCurrentY) + tilesView.contentY
        var bottom = Math.max(selectionStartY, selectionCurrentY) + tilesView.contentY

        var next = {}
        var rows = rowsArray()

        for (var i = 0; i < rows.length; ++i) {
            var r = tileSelectionRectForRow(i)

            if (right >= r.x && left <= (r.x + r.w)
                    && bottom >= r.y && top <= (r.y + r.h)) {
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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 12
        radius: 10
        color: "transparent"

        ListView {
            id: tilesView
            anchors.fill: parent
            clip: true
            spacing: 2
            model: tilesRoot.rowsArray()
            interactive: !tilesRoot.selectionActive
            boundsBehavior: Flickable.StopAtBounds
            pixelAligned: true
            maximumFlickVelocity: 2200
            flickDeceleration: 9000

            ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
            ScrollBar.horizontal: null

            delegate: Item {
                id: tileDelegate
                required property int index
                required property var modelData

                width: ListView.view.width
                height: 82

                readonly property bool isFolderTarget: modelData.type === "File folder"
                readonly property bool sameAsDragged: rootWindow.isDraggedRow(index)

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: rootWindow.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                           ? Theme.AppTheme.selectedSoft
                           : rootWindow.isFileRowSelected(index)
                             ? Theme.AppTheme.selected
                             : tileMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
                    border.color: rootWindow.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                                  ? Theme.AppTheme.accent
                                  : "transparent"
                    border.width: rootWindow.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged ? Theme.Metrics.borderWidth : 0
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.AppTheme.borderSoft
                    opacity: 0.9
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
                        name: modelData.icon
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: 34
                    }

                    Column {
                        width: Math.max(220, parent.width - 420)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            visible: rootWindow.editingFileRow !== index
                            text: modelData.name
                            color: Theme.AppTheme.text
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        TextField {
                            visible: rootWindow.editingFileRow === index
                            width: parent.width
                            height: 26
                            text: rootWindow.editingFileNameDraft
                            color: Theme.AppTheme.text
                            font.pixelSize: 14
                            selectByMouse: true
                            leftPadding: 8
                            rightPadding: 8
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

                        Text {
                            text: "Type: " + (modelData.type || "")
                            color: Theme.AppTheme.muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Item { width: 1; height: 1 }

                    Column {
                        width: 280
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "Date modified: " + (modelData.dateModified || "")
                            color: Theme.AppTheme.text
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: "Size: " + ((modelData.size && modelData.size !== "") ? modelData.size : "—")
                            color: Theme.AppTheme.text
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                DropArea {
                    anchors.fill: parent

                    onEntered: function(drag) {
                        var ok = tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                        drag.accepted = ok
                        if (ok)
                            rootWindow.detailsDropHoverRow = index
                    }

                    onExited: function(drag) {
                        if (rootWindow.detailsDropHoverRow === index)
                            rootWindow.detailsDropHoverRow = -1
                    }

                    onDropped: function(drop) {
                        if (tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged) {
                            drop.accepted = true
                            rootWindow.handleDroppedItem(modelData.name, "folder")
                        }

                        if (rootWindow.detailsDropHoverRow === index)
                            rootWindow.detailsDropHoverRow = -1
                    }
                }

                MouseArea {
                    id: tileMouse
                    x: 14
                    y: 10
                    width: tilesRoot.tileHitWidthForName(modelData.name)
                    height: 62
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

                        Drag.active: tileMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.MoveAction
                        Drag.source: tileDelegate
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

            MouseArea {
                id: tilesOverlayMouse
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: false
                preventStealing: true

                property bool bandSelecting: false
                property bool pendingEmptyContextMenu: false

                function pointHitsRealTile(xInView, yInView) {
                    var yInContent = yInView + tilesView.contentY
                    var rowStep = 82 + tilesView.spacing
                    var row = Math.floor(yInContent / rowStep)
                    var rows = tilesRoot.rowsArray()

                    if (row < 0 || row >= rows.length)
                        return false

                    var r = tilesRoot.tileHitRectForRow(row)

                    return xInView >= r.x
                        && xInView <= (r.x + r.w)
                        && yInContent >= r.y
                        && yInContent <= (r.y + r.h)
                }

                onPressed: function(mouse) {
                    if (rootWindow.editingFileRow >= 0)
                        rootWindow.commitRenameRow(rootWindow.editingFileRow, rootWindow.editingFileNameDraft)

                    var overItem = pointHitsRealTile(mouse.x, mouse.y)

                    var bothButtons =
                            (tilesOverlayMouse.pressedButtons & Qt.LeftButton)
                            && (tilesOverlayMouse.pressedButtons & Qt.RightButton)

                    bandSelecting = bothButtons || (mouse.button === Qt.LeftButton && !overItem)
                    pendingEmptyContextMenu = (mouse.button === Qt.RightButton && !overItem && !bothButtons)

                    if (bandSelecting) {
                        tilesRoot.selectionActive = true
                        tilesRoot.selectionMoved = false
                        tilesRoot.selectionStartX = tilesRoot.clampX(mouse.x)
                        tilesRoot.selectionStartY = tilesRoot.clampY(mouse.y)
                        tilesRoot.selectionCurrentX = tilesRoot.selectionStartX
                        tilesRoot.selectionCurrentY = tilesRoot.selectionStartY
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
                    if (!bandSelecting || !tilesRoot.selectionActive)
                        return

                    tilesRoot.selectionCurrentX = tilesRoot.clampX(mouse.x)
                    tilesRoot.selectionCurrentY = tilesRoot.clampY(mouse.y)

                    if (Math.abs(tilesRoot.selectionCurrentX - tilesRoot.selectionStartX) > 2
                            || Math.abs(tilesRoot.selectionCurrentY - tilesRoot.selectionStartY) > 2) {
                        tilesRoot.selectionMoved = true
                    }

                    tilesRoot.updateBandSelection()
                }

                onReleased: function(mouse) {
                    if (pendingEmptyContextMenu && !tilesRoot.selectionMoved) {
                        rootWindow.contextFileRow = -1
                        emptyContextMenu.popup()
                    }

                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    tilesRoot.selectionActive = false
                    tilesRoot.selectionMoved = false
                }

                onCanceled: {
                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    tilesRoot.selectionActive = false
                    tilesRoot.selectionMoved = false
                }
            }

            Rectangle {
                visible: tilesRoot.selectionActive && tilesRoot.selectionMoved
                z: 1001

                x: Math.min(tilesRoot.selectionStartX, tilesRoot.selectionCurrentX)
                y: Math.min(tilesRoot.selectionStartY, tilesRoot.selectionCurrentY)
                width: Math.abs(tilesRoot.selectionCurrentX - tilesRoot.selectionStartX)
                height: Math.abs(tilesRoot.selectionCurrentY - tilesRoot.selectionStartY)

                color: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)
                border.color: Theme.AppTheme.accent
                border.width: 1
            }
        }
    }
}