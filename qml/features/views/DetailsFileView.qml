import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: detailsRoot

    required property var rootWindow
    required property var filesTableModel
    required property var rowContextMenu
    required property var multiSelectionContextMenu
    required property var emptyContextMenu

    anchors.margins: 10
    clip: true

    function rowsArray() {
        return (filesTableModel && filesTableModel.rows) ? filesTableModel.rows : []
    }

    function relayout() {
        fileTable.forceLayout()
    }

    function clampX(x) {
        return Math.max(0, Math.min(width, x))
    }

    function clampY(y) {
        return Math.max(0, Math.min(height, y))
    }

    TableView {
        id: fileTable
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        rowSpacing: 1
        columnSpacing: 0
        model: detailsRoot.filesTableModel

        onWidthChanged: forceLayout()
        Component.onCompleted: forceLayout()

        columnWidthProvider: function(column) {
            switch (column) {
            case 0: return detailsRoot.rootWindow.detailsNameWidth
            case 1: return detailsRoot.rootWindow.detailsDateWidth
            case 2: return detailsRoot.rootWindow.detailsTypeWidth
            case 3: return Math.max(
                        detailsRoot.rootWindow.detailsSizeWidth,
                        fileTable.width - (
                            detailsRoot.rootWindow.detailsNameWidth
                            + detailsRoot.rootWindow.detailsDateWidth
                            + detailsRoot.rootWindow.detailsTypeWidth
                        )
                    )
            case 4: return 0
            default: return 120
            }
        }

        rowHeightProvider: function(row) {
            return detailsRoot.rootWindow.detailsRowHeight
        }

        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
        ScrollBar.horizontal: ExplorerScrollbarH { darkTheme: Theme.AppTheme.isDark }

        delegate: Rectangle {
            id: rowDelegate
            required property bool selected
            required property bool current
            required property int row
            required property int column
            required property bool editing

            readonly property bool isFolderTarget: detailsRoot.rootWindow.fileRowValue(row, "type") === "File folder"
            readonly property bool sameAsDragged: detailsRoot.rootWindow.isDraggedRow(row)

            clip: false
            z: column === 0 ? 50 : 1

            color: detailsRoot.rootWindow.detailsDropHoverRow === row && isFolderTarget && !sameAsDragged
                   ? Theme.AppTheme.selectedSoft
                   : detailsRoot.rootWindow.isFileRowSelected(row)
                     ? Theme.AppTheme.selected
                     : cellMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8

                AppIcon {
                    visible: column === 0
                    name: detailsRoot.rootWindow.fileRowValue(row, "icon")
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: !(column === 0 && detailsRoot.rootWindow.editingFileRow === row)
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (column === 0) return detailsRoot.rootWindow.fileRowValue(row, "name")
                        if (column === 1) return detailsRoot.rootWindow.fileRowValue(row, "dateModified")
                        if (column === 2) return detailsRoot.rootWindow.fileRowValue(row, "type")
                        if (column === 3) return detailsRoot.rootWindow.fileRowValue(row, "size")
                        return ""
                    }
                    color: column === 0 ? Theme.AppTheme.text : Theme.AppTheme.muted
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    width: parent.width - (column === 0 ? 28 : 0)
                    horizontalAlignment: Text.AlignLeft
                }

                TextField {
                    id: renameField
                    visible: column === 0 && detailsRoot.rootWindow.editingFileRow === row
                    width: parent.width - 28
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: detailsRoot.rootWindow.editingFileNameDraft
                    color: Theme.AppTheme.text
                    font.pixelSize: 13
                    selectByMouse: true
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 0
                    bottomPadding: 0

                    property var validation: detailsRoot.rootWindow.validateNameDraft(text)
                    property bool showValidation: visible && text.length > 0 && !validation.ok

                    background: Rectangle {
                        radius: 6
                        color: Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
                        border.color: renameField.showValidation ? "#df5c5c" : Theme.AppTheme.accent
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
                            detailsRoot.rootWindow.editingFileNameDraft = text
                    }

                    onAccepted: {
                        if (validation.ok)
                            detailsRoot.rootWindow.commitRenameRow(row, text)
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus && visible) {
                            if (validation.ok)
                                detailsRoot.rootWindow.commitRenameRow(row, text)
                        }
                    }

                    Keys.onEscapePressed: detailsRoot.rootWindow.cancelRenameRow()
                }

                Rectangle {
                    visible: column === 0 && detailsRoot.rootWindow.editingFileRow === row && renameField.showValidation
                    z: 300
                    x: 22
                    y: parent.height + 4
                    width: Math.min(360, fileTable.width - 40)
                    height: validationText.implicitHeight + 12
                    radius: 6
                    color: Theme.AppTheme.isDark ? "#2a1618" : "#fff1f1"
                    border.color: "#df5c5c"
                    border.width: 1

                    Text {
                        id: validationText
                        anchors.fill: parent
                        anchors.margins: 6
                        text: renameField.validation.message
                        color: Theme.AppTheme.isDark ? "#ffb3b3" : "#b42318"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }

            DropArea {
                id: rowDropArea

                enabled: column === 0
                x: 0
                y: 0
                width: fileTable.width
                height: parent.height
                z: 100

                onEntered: function(drag) {
                    var ok = rowDelegate.isFolderTarget && !rowDelegate.sameAsDragged
                    drag.accepted = ok
                    if (ok)
                        detailsRoot.rootWindow.detailsDropHoverRow = row
                }

                onExited: function(drag) {
                    if (detailsRoot.rootWindow.detailsDropHoverRow === row)
                        detailsRoot.rootWindow.detailsDropHoverRow = -1
                }

                onDropped: function(drop) {
                    if (rowDelegate.isFolderTarget && !rowDelegate.sameAsDragged) {
                        drop.accepted = true
                        detailsRoot.rootWindow.handleDroppedItem(detailsRoot.rootWindow.fileRowValue(row, "name"), "folder")
                    }

                    if (detailsRoot.rootWindow.detailsDropHoverRow === row)
                        detailsRoot.rootWindow.detailsDropHoverRow = -1
                }
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true

                drag.target: column === 0 ? dragProxy : null
                drag.axis: Drag.XAndYAxis
                drag.smoothed: false

                onClicked: function(mouse) {
                    mouse.accepted = true
                }

                onPressed: function(mouse) {
                    if (detailsRoot.rootWindow.editingFileRow >= 0
                            && detailsRoot.rootWindow.editingFileRow !== row) {
                        detailsRoot.rootWindow.commitRenameRow(
                            detailsRoot.rootWindow.editingFileRow,
                            detailsRoot.rootWindow.editingFileNameDraft
                        )
                    }

                    var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                    var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                    var alreadySelected = detailsRoot.rootWindow.isFileRowSelected(row)

                    if (mouse.button === Qt.RightButton) {
                        if (!alreadySelected)
                            detailsRoot.rootWindow.selectOnlyFileRow(row)

                        detailsRoot.rootWindow.contextFileRow = row

                        if (detailsRoot.rootWindow.selectedFileCount() > 1)
                            detailsRoot.multiSelectionContextMenu.popup()
                        else
                            detailsRoot.rowContextMenu.popup()

                        return
                    }

                    if (mouse.button === Qt.LeftButton) {
                        if (shift) {
                            var anchor = detailsRoot.rootWindow.selectionAnchorRow >= 0
                                    ? detailsRoot.rootWindow.selectionAnchorRow
                                    : row
                            detailsRoot.rootWindow.selectFileRange(anchor, row, true)
                        } else if (ctrl) {
                            detailsRoot.rootWindow.toggleFileRowSelection(row)
                        } else {
                            if (!alreadySelected)
                                detailsRoot.rootWindow.selectOnlyFileRow(row)
                        }

                        if (column === 0) {
                            if (!alreadySelected && !ctrl && !shift)
                                detailsRoot.rootWindow.beginFileDrag(row)
                            else if (alreadySelected && !ctrl && !shift)
                                detailsRoot.rootWindow.beginFileDrag(row)
                            else if (detailsRoot.rootWindow.isFileRowSelected(row))
                                detailsRoot.rootWindow.beginFileDrag(row)
                        }
                    }
                }

                onDoubleClicked: {
                    detailsRoot.rootWindow.applySnapshot(
                        detailsRoot.rootWindow.backend.openItems(
                            detailsRoot.rootWindow.singleItemForBackend(row)
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

                    Drag.active: column === 0 && cellMouse.drag.active
                    Drag.dragType: Drag.Automatic
                    Drag.supportedActions: Qt.MoveAction
                    Drag.source: rowDelegate
                    Drag.hotSpot.x: 18
                    Drag.hotSpot.y: 18
                    Drag.imageSource: detailsRoot.rootWindow.dragPreviewReady
                                      ? detailsRoot.rootWindow.draggedFilePreviewUrl
                                      : ""
                    Drag.mimeData: ({
                        "application/x-fileexplorer-item": JSON.stringify({
                            row: row,
                            rows: detailsRoot.rootWindow.selectedFileRowsArray(),
                            count: detailsRoot.rootWindow.draggedFileCount,
                            name: detailsRoot.rootWindow.draggedFileName,
                            type: detailsRoot.rootWindow.draggedFileType,
                            icon: detailsRoot.rootWindow.draggedFileIcon
                        })
                    })

                    Drag.onDragFinished: function(dropAction) {
                        dragProxy.x = 0
                        dragProxy.y = 0
                        detailsRoot.rootWindow.detailsDropHoverRow = -1
                        detailsRoot.rootWindow.clearFileDrag()
                    }
                }
            }
        }
    }

    FontMetrics {
        id: detailsFontMetrics
        font.pixelSize: 13
    }

    MouseArea {
        id: detailsEmptyAreaMouse
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        property bool bandSelecting: false
        property bool pendingEmptyContextMenu: false

        function rowAtY(yInContent) {
            var step = detailsRoot.rootWindow.detailsRowHeight + fileTable.rowSpacing
            if (step <= 0)
                return -1

            var row = Math.floor(yInContent / step)
            var rows = detailsRoot.rowsArray()

            if (row < 0 || row >= rows.length)
                return -1

            var rowTop = row * step
            var rowBottom = rowTop + detailsRoot.rootWindow.detailsRowHeight
            if (yInContent < rowTop || yInContent > rowBottom)
                return -1

            return row
        }

        function pointHitsRowContent(xInContent, yInContent) {
            var row = rowAtY(yInContent)
            if (row < 0)
                return false

            var firstColumnWidth = detailsRoot.rootWindow.detailsNameWidth
            if (xInContent < 0 || xInContent > firstColumnWidth)
                return false

            var leftInset = 14
            var iconWidth = 16
            var gapAfterIcon = 8
            var rightPadding = 14
            var textAvailableWidth = Math.max(
                        0,
                        firstColumnWidth - leftInset - iconWidth - gapAfterIcon - rightPadding
                    )
            var textWidth = Math.min(
                        textAvailableWidth,
                        detailsFontMetrics.advanceWidth(detailsRoot.rootWindow.fileRowValue(row, "name"))
                    )

            var contentLeft = leftInset
            var contentRight = leftInset + iconWidth + gapAfterIcon + textWidth + 10

            return xInContent >= contentLeft && xInContent <= contentRight
        }

        onPressed: function(mouse) {
            if (detailsRoot.rootWindow.editingFileRow >= 0) {
                detailsRoot.rootWindow.commitRenameRow(
                    detailsRoot.rootWindow.editingFileRow,
                    detailsRoot.rootWindow.editingFileNameDraft
                )
            }

            var xInContent = mouse.x + fileTable.contentX
            var yInContent = mouse.y + fileTable.contentY

            var overRealItemContent = pointHitsRowContent(xInContent, yInContent)
            var row = rowAtY(yInContent)

            var clickedEmptyArea =
                    row < 0
                    || xInContent < 0
                    || xInContent > fileTable.contentWidth
                    || yInContent > fileTable.contentHeight
                    || !overRealItemContent

            var bothButtons =
                    (detailsEmptyAreaMouse.pressedButtons & Qt.LeftButton)
                    && (detailsEmptyAreaMouse.pressedButtons & Qt.RightButton)

            bandSelecting = bothButtons || (mouse.button === Qt.LeftButton && clickedEmptyArea)
            pendingEmptyContextMenu = (mouse.button === Qt.RightButton && clickedEmptyArea && !bothButtons)

            if (bandSelecting) {
                detailsRoot.rootWindow.detailsSelectionActive = true
                detailsRoot.rootWindow.detailsSelectionMoved = false
                detailsRoot.rootWindow.detailsSelectionStartX = detailsRoot.clampX(mouse.x)
                detailsRoot.rootWindow.detailsSelectionStartY = detailsRoot.clampY(mouse.y)
                detailsRoot.rootWindow.detailsSelectionCurrentX = detailsRoot.rootWindow.detailsSelectionStartX
                detailsRoot.rootWindow.detailsSelectionCurrentY = detailsRoot.rootWindow.detailsSelectionStartY
                detailsRoot.rootWindow.clearFileSelection()
                detailsRoot.rootWindow.contextFileRow = -1
                mouse.accepted = true
                return
            }

            if (pendingEmptyContextMenu) {
                detailsRoot.rootWindow.clearFileSelection()
                mouse.accepted = true
                return
            }

            mouse.accepted = false
        }

        onPositionChanged: function(mouse) {
            if (!bandSelecting || !detailsRoot.rootWindow.detailsSelectionActive)
                return

            detailsRoot.rootWindow.detailsSelectionCurrentX = detailsRoot.clampX(mouse.x)
            detailsRoot.rootWindow.detailsSelectionCurrentY = detailsRoot.clampY(mouse.y)

            if (Math.abs(detailsRoot.rootWindow.detailsSelectionCurrentX - detailsRoot.rootWindow.detailsSelectionStartX) > 2
                    || Math.abs(detailsRoot.rootWindow.detailsSelectionCurrentY - detailsRoot.rootWindow.detailsSelectionStartY) > 2) {
                detailsRoot.rootWindow.detailsSelectionMoved = true
            }

            detailsRoot.rootWindow.updateDetailsBandSelection(fileTable)
        }

        onReleased: function(mouse) {
            if (pendingEmptyContextMenu && !detailsRoot.rootWindow.detailsSelectionMoved) {
                detailsRoot.rootWindow.contextFileRow = -1
                detailsRoot.emptyContextMenu.popup()
            }

            bandSelecting = false
            pendingEmptyContextMenu = false
            detailsRoot.rootWindow.detailsSelectionActive = false
            detailsRoot.rootWindow.detailsSelectionMoved = false
        }

        onCanceled: {
            bandSelecting = false
            pendingEmptyContextMenu = false
            detailsRoot.rootWindow.detailsSelectionActive = false
            detailsRoot.rootWindow.detailsSelectionMoved = false
        }
    }

    Rectangle {
        visible: detailsRoot.rootWindow.detailsSelectionActive && detailsRoot.rootWindow.detailsSelectionMoved
        z: 999

        x: Math.min(detailsRoot.rootWindow.detailsSelectionStartX, detailsRoot.rootWindow.detailsSelectionCurrentX)
        y: Math.min(detailsRoot.rootWindow.detailsSelectionStartY, detailsRoot.rootWindow.detailsSelectionCurrentY)
        width: Math.abs(detailsRoot.rootWindow.detailsSelectionCurrentX - detailsRoot.rootWindow.detailsSelectionStartX)
        height: Math.abs(detailsRoot.rootWindow.detailsSelectionCurrentY - detailsRoot.rootWindow.detailsSelectionStartY)

        color: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)
        border.color: Theme.AppTheme.accent
        border.width: 1
    }
}