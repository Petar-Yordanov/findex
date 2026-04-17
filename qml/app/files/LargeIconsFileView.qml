import QtQuick
import QtQuick.Controls
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root
    required property var viewModel
    required property var fileContextMenu
    required property var dragOverlayHost
    color: "transparent"
    property real preservedContentY: 0
    property bool restoreScrollAfterReset: false
    property bool directoryChangedSinceLastReset: false

    function restoreFileListScrollPosition() {
        fileList.contentY = Math.max(0, Math.min(preservedContentY, Math.max(0, fileList.contentHeight - fileList.height)))
    }

    Connections {
        target: viewModel

        function onCurrentDirectoryPathChanged() {
            root.directoryChangedSinceLastReset = true
        }
    }

    Connections {
        target: viewModel ? viewModel.fileModel : null

        function onModelAboutToBeReset() {
            root.restoreScrollAfterReset = !root.directoryChangedSinceLastReset
            if (!root.restoreScrollAfterReset)
                return
            root.preservedContentY = fileList.contentY
        }

        function onModelReset() {
            const shouldRestore = root.restoreScrollAfterReset
            root.restoreScrollAfterReset = false
            root.directoryChangedSinceLastReset = false
            if (!shouldRestore)
                return
            Qt.callLater(root.restoreFileListScrollPosition)
        }
    }

    ListView {
        id: fileList
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        spacing: 1
        model: viewModel ? viewModel.fileModel : null
        boundsBehavior: Flickable.StopAtBounds
        interactive: !(viewModel && viewModel.dragSelecting) && !overlay.pointerArmed

        ScrollBar.vertical: ExplorerScrollbarV {}

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
            required property string icon
            required property string nativeIconSource
            required property bool isDir

            readonly property bool selectedState: {
                const rev = viewModel ? viewModel.selectionRevision : 0
                return viewModel ? viewModel.isRowSelected(index) : false
            }

            readonly property bool editingState: viewModel && viewModel.inlineEditRow === index
            readonly property string editError: editingState && viewModel ? viewModel.inlineEditError : ""

            width: ListView.view.width
            height: editingState && editError !== "" ? 52 : 30

            function focusInlineEditor() {
                Qt.callLater(function() {
                    if (inlineField.visible) {
                        inlineField.forceActiveFocus()
                        inlineField.selectAll()
                    }
                })
            }

            Connections {
                target: viewModel
                function onInlineEditFocusTokenChanged() {
                    if (editingState)
                        focusInlineEditor()
                }
            }

            Item {
                id: dragProxy
                visible: false
                width: 1
                height: 1
                x: mouseArea.mouseX
                y: mouseArea.mouseY

                Drag.active: mouseArea.fileDragActive
                Drag.dragType: Drag.Internal
                Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
                Drag.hotSpot.x: 0
                Drag.hotSpot.y: 0
                Drag.mimeData: {
                    "text/plain": viewModel ? viewModel.draggedPathsText : ""
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: folderDropArea.containsDrag
                       ? Theme.AppTheme.selected
                       : selectedState
                         ? Theme.AppTheme.selected
                         : mouseArea.containsMouse
                           ? Theme.AppTheme.selectedSoft
                           : "transparent"

                border.color: folderDropArea.containsDrag
                              ? Theme.AppTheme.accent
                              : editingState
                                ? (editError !== "" ? Theme.AppTheme.danger : Theme.AppTheme.accent)
                                : selectedState ? Theme.AppTheme.accent : "transparent"
                border.width: (folderDropArea.containsDrag || selectedState || editingState) ? 1 : 0
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                AppIcon {
                    name: icon
                    sourceOverride: nativeIconSource
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: parent.width - 24
                    height: parent.height

                    Text {
                        visible: !editingState
                        text: name
                        color: Theme.AppTheme.text
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        visible: editingState
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        InlineRenameField {
                            id: inlineField
                            width: parent.width
                            height: 24
                            darkTheme: Theme.AppTheme.isDark
                            textColor: Theme.AppTheme.text
                            bgColor: Theme.AppTheme.popupBg
                            accentColor: editError !== "" ? Theme.AppTheme.danger : Theme.AppTheme.accent
                            text: editingState && viewModel ? viewModel.inlineEditText : name

                            onVisibleChanged: {
                                if (visible)
                                    focusInlineEditor()
                            }

                            onTextChanged: {
                                if (visible && viewModel)
                                    viewModel.updateInlineEditText(text)
                            }

                            onAccepted: {
                                if (viewModel && !viewModel.commitInlineEdit())
                                    focusInlineEditor()
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && visible && viewModel && !viewModel.commitInlineEdit())
                                    focusInlineEditor()
                            }

                            Keys.onEscapePressed: {
                                if (viewModel)
                                    viewModel.cancelInlineEdit()
                            }
                        }

                        Text {
                            visible: editError !== ""
                            width: parent.width
                            text: editError
                            color: Theme.AppTheme.danger
                            font.pixelSize: 10
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            DropArea {
                id: folderDropArea
                anchors.fill: parent
                enabled: !editingState && isDir && viewModel && viewModel.draggingItems && !viewModel.isOnlyDraggingRow(index)

                onDropped: function(drop) {
                    if (!viewModel || !viewModel.canDropOnRow(index))
                        return
                    const dropAction = drop.proposedAction === Qt.CopyAction ? Qt.CopyAction : Qt.MoveAction
                    viewModel.dropOnRow(index, dropAction === Qt.CopyAction)
                    drop.accept(dropAction)
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: !editingState
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
                    if (!viewModel || !root.dragOverlayHost)
                        return
                    var p = mouseArea.mapToItem(root.dragOverlayHost, mouse.x, mouse.y)
                    if (!viewModel.dragPreviewVisible)
                        viewModel.beginFileDragPreview(p.x, p.y, dragPreviewText(), icon)
                    else
                        viewModel.updateFileDragPreview(p.x, p.y)
                }

                onPressed: function(mouse) {
                    if (viewModel && viewModel.inlineEditRow >= 0) {
                        if (!viewModel.commitInlineEdit()) {
                            mouse.accepted = true
                            return
                        }
                    }

                    if (mouse.button === Qt.RightButton) {
                        if (viewModel && !viewModel.isRowSelected(index))
                            viewModel.selectOnlyRow(index)
                        if (fileContextMenu) {
                            fileContextMenu.rowIndex = index
                            var p = mouseArea.mapToItem(fileContextMenu.parent, mouse.x, mouse.y)
                            fileContextMenu.popupAt(p.x, p.y)
                        }
                        return
                    }

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

                    if (fileDragActive) {
                        dragProxy.x = mouse.x
                        dragProxy.y = mouse.y
                        pushDragPreview(mouse)
                    }
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

                    if (fileDragActive) {
                        var action = dragProxy.Drag.drop()
                        if (viewModel)
                            viewModel.finishFileDrag(action !== Qt.IgnoreAction)
                    }

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

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 320)
        spacing: Theme.Metrics.spacingMd
        visible: fileList.count === 0
        z: 1

        AppIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "folder"
            darkTheme: Theme.AppTheme.isDark
            iconSize: Theme.Metrics.icon3xl
            iconOpacity: 0.5
        }

        Text {
            width: parent.width
            text: "This folder is empty"
            color: Theme.AppTheme.text
            font.pixelSize: Theme.Typography.bodyLg
            font.bold: true
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: "Create something new or copy files here."
            color: Theme.AppTheme.muted
            font.pixelSize: Theme.Typography.body
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
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
                if (viewModel && viewModel.inlineEditRow >= 0) {
                    if (!viewModel.commitInlineEdit()) {
                        mouse.accepted = true
                        return
                    }
                }

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
                    var item = fileList.itemAtIndex(i)
                    if (item) {
                        var itemY = item.y
                        var itemBottom = item.y + item.height
                        if (bottom > itemY && top < itemBottom)
                            rows.push(i)
                    }
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