import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: compactRoot

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

    function rowsArray() {
        return (filesTableModel && filesTableModel.rows) ? filesTableModel.rows : []
    }

    FontMetrics {
        id: compactFontMetrics
        font.pixelSize: 13
    }

    function compactContentWidthForName(name) {
        return Math.min(
            Math.max(110, compactFontMetrics.advanceWidth(name || "") + 34),
            Math.max(110, compactView.width - 24)
        )
    }

    function compactHitRectForRow(row) {
        var rows = rowsArray()
        var item = (row >= 0 && row < rows.length) ? rows[row] : null
        return {
            x: 12,
            y: row * (30 + compactView.spacing) + 4,
            w: compactContentWidthForName(item ? item.name : ""),
            h: 22
        }
    }

    function compactSelectionRectForRow(row) {
        return {
            x: 0,
            y: row * (30 + compactView.spacing),
            w: compactView.width,
            h: 30
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
        var top = Math.min(selectionStartY, selectionCurrentY) + compactView.contentY
        var bottom = Math.max(selectionStartY, selectionCurrentY) + compactView.contentY

        var next = {}
        var rows = rowsArray()

        for (var i = 0; i < rows.length; ++i) {
            var r = compactSelectionRectForRow(i)

            var horizontallyHit = right >= r.x && left <= (r.x + r.w)
            var verticallyHit = bottom >= r.y && top <= (r.y + r.h)

            if (horizontallyHit && verticallyHit)
                next[i] = true
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
            id: compactView
            anchors.fill: parent
            clip: true
            spacing: 1
            model: compactRoot.rowsArray()
            interactive: !compactRoot.selectionActive
            boundsBehavior: Flickable.StopAtBounds
            pixelAligned: true
            maximumFlickVelocity: 2200
            flickDeceleration: 9000

            ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
            ScrollBar.horizontal: null

            delegate: Item {
                id: compactDelegate
                required property int index
                required property var modelData

                width: ListView.view.width
                height: 30

                readonly property bool isFolderTarget: modelData.type === "File folder"
                readonly property bool sameAsDragged: rootWindow.isDraggedRow(index)

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: rootWindow.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                           ? Theme.AppTheme.selectedSoft
                           : rootWindow.isFileRowSelected(index)
                             ? Theme.AppTheme.selected
                             : compactMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
                    border.color: rootWindow.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                  ? Theme.AppTheme.accent
                                  : "transparent"
                    border.width: rootWindow.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged ? Theme.Metrics.borderWidth : 0
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    AppIcon {
                        name: modelData.icon
                        darkTheme: Theme.AppTheme.isDark
                        iconSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: rootWindow.editingFileRow !== index
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Theme.AppTheme.text
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 24
                    }

                    TextField {
                        visible: rootWindow.editingFileRow === index
                        width: parent.width - 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: rootWindow.editingFileNameDraft
                        color: Theme.AppTheme.text
                        font.pixelSize: 13
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
                }

                DropArea {
                    anchors.fill: parent

                    onEntered: function(drag) {
                        var ok = compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                        drag.accepted = ok
                        if (ok)
                            rootWindow.detailsDropHoverRow = index
                    }

                    onExited: function(drag) {
                        if (rootWindow.detailsDropHoverRow === index)
                            rootWindow.detailsDropHoverRow = -1
                    }

                    onDropped: function(drop) {
                        if (compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged) {
                            drop.accepted = true
                            rootWindow.handleDroppedItem(modelData.name, "folder")
                        }

                        if (rootWindow.detailsDropHoverRow === index)
                            rootWindow.detailsDropHoverRow = -1
                    }
                }

                MouseArea {
                    id: compactMouse
                    x: 12
                    y: 4
                    width: compactRoot.compactContentWidthForName(modelData.name)
                    height: 22
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

                            if (rootWindow.isFileRowSelected(index))
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

                        Drag.active: compactMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.MoveAction
                        Drag.source: compactDelegate
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
                id: compactOverlayMouse
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: false
                preventStealing: true

                property bool bandSelecting: false
                property bool pendingEmptyContextMenu: false

                function pointHitsRealItem(xInView, yInView) {
                    var yInContent = yInView + compactView.contentY
                    var rowStep = 30 + compactView.spacing
                    var row = Math.floor(yInContent / rowStep)
                    var rows = compactRoot.rowsArray()

                    if (row < 0 || row >= rows.length)
                        return false

                    var r = compactRoot.compactHitRectForRow(row)

                    return xInView >= r.x
                        && xInView <= (r.x + r.w)
                        && yInContent >= r.y
                        && yInContent <= (r.y + r.h)
                }

                onPressed: function(mouse) {
                    if (rootWindow.editingFileRow >= 0)
                        rootWindow.commitRenameRow(rootWindow.editingFileRow, rootWindow.editingFileNameDraft)

                    var overItem = pointHitsRealItem(mouse.x, mouse.y)

                    var bothButtons =
                            (compactOverlayMouse.pressedButtons & Qt.LeftButton)
                            && (compactOverlayMouse.pressedButtons & Qt.RightButton)

                    bandSelecting = bothButtons || (mouse.button === Qt.LeftButton && !overItem)
                    pendingEmptyContextMenu = (mouse.button === Qt.RightButton && !overItem && !bothButtons)

                    if (bandSelecting) {
                        compactRoot.selectionActive = true
                        compactRoot.selectionMoved = false
                        compactRoot.selectionStartX = compactRoot.clampX(mouse.x)
                        compactRoot.selectionStartY = compactRoot.clampY(mouse.y)
                        compactRoot.selectionCurrentX = compactRoot.selectionStartX
                        compactRoot.selectionCurrentY = compactRoot.selectionStartY
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
                    if (!bandSelecting || !compactRoot.selectionActive)
                        return

                    compactRoot.selectionCurrentX = compactRoot.clampX(mouse.x)
                    compactRoot.selectionCurrentY = compactRoot.clampY(mouse.y)

                    if (Math.abs(compactRoot.selectionCurrentX - compactRoot.selectionStartX) > 2
                            || Math.abs(compactRoot.selectionCurrentY - compactRoot.selectionStartY) > 2) {
                        compactRoot.selectionMoved = true
                    }

                    compactRoot.updateBandSelection()
                }

                onReleased: function(mouse) {
                    if (pendingEmptyContextMenu && !compactRoot.selectionMoved) {
                        rootWindow.contextFileRow = -1
                        emptyContextMenu.popup()
                    }

                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    compactRoot.selectionActive = false
                    compactRoot.selectionMoved = false
                }

                onCanceled: {
                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    compactRoot.selectionActive = false
                    compactRoot.selectionMoved = false
                }
            }

            Rectangle {
                visible: compactRoot.selectionActive && compactRoot.selectionMoved
                z: 1001

                x: Math.min(compactRoot.selectionStartX, compactRoot.selectionCurrentX)
                y: Math.min(compactRoot.selectionStartY, compactRoot.selectionCurrentY)
                width: Math.abs(compactRoot.selectionCurrentX - compactRoot.selectionStartX)
                height: Math.abs(compactRoot.selectionCurrentY - compactRoot.selectionStartY)

                color: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)
                border.color: Theme.AppTheme.accent
                border.width: 1
            }
        }
    }
}