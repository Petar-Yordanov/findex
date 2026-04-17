import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root
    required property var viewModel
    required property var fileContextMenu
    required property var dragOverlayHost

    color: "transparent"

    property int outerLeftPadding: 14
    property int outerRightPadding: 8
    property int columnSpacing: 8

    property int rowInnerLeftPadding: 10
    property int rowInnerRightPadding: 8

    property int selectionHorizontalInset: 2
    property int selectionVerticalInset: 1

    property int minNameColumnWidth: 170
    property int minDateColumnWidth: 145
    property int minTypeColumnWidth: 145
    property int minSizeColumnWidth: 90

    property int baseNameColumnWidth: 430
    property int baseDateColumnWidth: 220
    property int baseTypeColumnWidth: 290
    property int baseSizeColumnWidth: 140
    property real preservedContentX: 0
    property real preservedContentY: 0
    property bool restoreScrollAfterReset: false
    property bool directoryChangedSinceLastReset: false

    readonly property int availableViewportWidth: Math.max(
        0,
        fileList.width - outerLeftPadding - outerRightPadding
    )

    readonly property int baseColumnsWidth: baseNameColumnWidth
                                           + baseDateColumnWidth
                                           + baseTypeColumnWidth
                                           + baseSizeColumnWidth

    readonly property int minColumnsWidth: minNameColumnWidth
                                          + minDateColumnWidth
                                          + minTypeColumnWidth
                                          + minSizeColumnWidth

    readonly property int baseTotalWidth: baseColumnsWidth + columnSpacing * 3
    readonly property int minTotalWidth: minColumnsWidth + columnSpacing * 3

    readonly property real shrinkRatio: {
        if (availableViewportWidth >= baseTotalWidth)
            return 1.0
        if (availableViewportWidth <= minTotalWidth)
            return 0.0
        return (availableViewportWidth - minTotalWidth) / (baseTotalWidth - minTotalWidth)
    }

    readonly property int nameColumnWidth: Math.round(
        minNameColumnWidth + (baseNameColumnWidth - minNameColumnWidth) * shrinkRatio
    )

    readonly property int dateColumnWidth: Math.round(
        minDateColumnWidth + (baseDateColumnWidth - minDateColumnWidth) * shrinkRatio
    )

    readonly property int typeColumnWidth: Math.round(
        minTypeColumnWidth + (baseTypeColumnWidth - minTypeColumnWidth) * shrinkRatio
    )

    readonly property int sizeColumnWidth: Math.round(
        minSizeColumnWidth + (baseSizeColumnWidth - minSizeColumnWidth) * shrinkRatio
    )

    readonly property int effectiveColumnsWidth: nameColumnWidth
                                                + dateColumnWidth
                                                + typeColumnWidth
                                                + sizeColumnWidth

    readonly property int effectiveContentWidth: Math.max(
        availableViewportWidth,
        effectiveColumnsWidth + columnSpacing * 3
    )

    function resizeName(delta) {
        baseNameColumnWidth = Math.max(minNameColumnWidth, baseNameColumnWidth + delta)
    }

    function resizeDate(delta) {
        baseDateColumnWidth = Math.max(minDateColumnWidth, baseDateColumnWidth + delta)
    }

    function resizeType(delta) {
        baseTypeColumnWidth = Math.max(minTypeColumnWidth, baseTypeColumnWidth + delta)
    }

    function headerLabel(label, field) {
        return label
    }

    function headerColor(field) {
        if (viewModel && viewModel.sortField === field)
            return Theme.AppTheme.accent
        return Theme.AppTheme.text
    }

    function sortIconName(field) {
        if (!viewModel || viewModel.sortField !== field)
            return ""
        return viewModel.sortDescending ? "keyboard-arrow-down" : "keyboard-arrow-up"
    }

    function toggleSort(field) {
        if (viewModel)
            viewModel.toggleSort(field)
    }

    function restoreFileListScrollPosition() {
        fileList.contentX = Math.max(0, Math.min(preservedContentX, Math.max(0, fileList.contentWidth - fileList.width)))
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
            root.preservedContentX = fileList.contentX
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Theme.AppTheme.surface2
            border.color: Theme.AppTheme.borderSoft
            border.width: Theme.Metrics.borderWidth
            clip: true

            Flickable {
                id: headerFlick
                anchors.fill: parent
                anchors.leftMargin: root.outerLeftPadding
                anchors.rightMargin: root.outerRightPadding + (fileVerticalScrollBar.visible ? fileVerticalScrollBar.width : 0)
                interactive: false
                clip: true
                contentWidth: root.effectiveContentWidth
                contentHeight: height
                contentX: fileList.contentX
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    width: root.effectiveContentWidth
                    height: headerFlick.height

                    Item {
                        id: nameHeader
                        x: 0
                        width: root.nameColumnWidth
                        height: parent.height

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                width: parent.width - (nameSortIcon.visible ? nameSortIcon.width + parent.spacing : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.headerLabel("Name", "name")
                                color: root.headerColor("name")
                                font.pixelSize: Theme.Typography.body
                                font.bold: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }

                            AppIcon {
                                id: nameSortIcon
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.sortIconName("name")
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 16
                                visible: name !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: nameHeader
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleSort("name")
                    }

                    Rectangle {
                        x: nameHeader.x + nameHeader.width + root.columnSpacing / 2 - width / 2
                        width: 6
                        height: parent.height
                        color: nameResizeMouse.pressed
                               ? Theme.AppTheme.accent
                               : nameResizeMouse.containsMouse
                                 ? Theme.AppTheme.border
                                 : "transparent"

                        MouseArea {
                            id: nameResizeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor
                            acceptedButtons: Qt.LeftButton

                            property real lastX: 0

                            onPressed: function(mouse) {
                                lastX = mouse.x
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed)
                                    return
                                root.resizeName(mouse.x - lastX)
                            }
                        }
                    }

                    Item {
                        id: dateHeader
                        x: root.nameColumnWidth + root.columnSpacing
                        width: root.dateColumnWidth
                        height: parent.height

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                width: parent.width - (dateSortIcon.visible ? dateSortIcon.width + parent.spacing : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.headerLabel("Date modified", "dateModified")
                                color: root.headerColor("dateModified")
                                font.pixelSize: Theme.Typography.body
                                font.bold: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }

                            AppIcon {
                                id: dateSortIcon
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.sortIconName("dateModified")
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 16
                                visible: name !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: dateHeader
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleSort("dateModified")
                    }

                    Rectangle {
                        x: dateHeader.x + dateHeader.width + root.columnSpacing / 2 - width / 2
                        width: 6
                        height: parent.height
                        color: dateResizeMouse.pressed
                               ? Theme.AppTheme.accent
                               : dateResizeMouse.containsMouse
                                 ? Theme.AppTheme.border
                                 : "transparent"

                        MouseArea {
                            id: dateResizeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor
                            acceptedButtons: Qt.LeftButton

                            property real lastX: 0

                            onPressed: function(mouse) {
                                lastX = mouse.x
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed)
                                    return
                                root.resizeDate(mouse.x - lastX)
                            }
                        }
                    }

                    Item {
                        id: typeHeader
                        x: root.nameColumnWidth + root.columnSpacing
                           + root.dateColumnWidth + root.columnSpacing
                        width: root.typeColumnWidth
                        height: parent.height

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                width: parent.width - (typeSortIcon.visible ? typeSortIcon.width + parent.spacing : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.headerLabel("Type", "type")
                                color: root.headerColor("type")
                                font.pixelSize: Theme.Typography.body
                                font.bold: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }

                            AppIcon {
                                id: typeSortIcon
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.sortIconName("type")
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 16
                                visible: name !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: typeHeader
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleSort("type")
                    }

                    Rectangle {
                        x: typeHeader.x + typeHeader.width + root.columnSpacing / 2 - width / 2
                        width: 6
                        height: parent.height
                        color: typeResizeMouse.pressed
                               ? Theme.AppTheme.accent
                               : typeResizeMouse.containsMouse
                                 ? Theme.AppTheme.border
                                 : "transparent"

                        MouseArea {
                            id: typeResizeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor
                            acceptedButtons: Qt.LeftButton

                            property real lastX: 0

                            onPressed: function(mouse) {
                                lastX = mouse.x
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed)
                                    return
                                root.resizeType(mouse.x - lastX)
                            }
                        }
                    }

                    Item {
                        id: sizeHeader
                        x: root.nameColumnWidth + root.columnSpacing
                           + root.dateColumnWidth + root.columnSpacing
                           + root.typeColumnWidth + root.columnSpacing
                        width: root.sizeColumnWidth
                        height: parent.height

                        Row {
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                width: parent.width - (sizeSortIcon.visible ? sizeSortIcon.width + parent.spacing : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.headerLabel("Size", "size")
                                color: root.headerColor("size")
                                font.pixelSize: Theme.Typography.body
                                font.bold: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }

                            AppIcon {
                                id: sizeSortIcon
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.sortIconName("size")
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 16
                                visible: name !== ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: sizeHeader
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleSort("size")
                    }
                }
            }
        }

        ListView {
            id: fileList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: viewModel ? viewModel.fileModel : null
            boundsBehavior: Flickable.StopAtBounds
            spacing: 0
            interactive: !(viewModel && viewModel.dragSelecting) && !overlay.pointerArmed
            flickableDirection: Flickable.AutoFlickDirection
            contentWidth: root.effectiveContentWidth + root.outerLeftPadding + root.outerRightPadding

            ScrollBar.vertical: ExplorerScrollbarV {
                id: fileVerticalScrollBar
            }

            ScrollBar.horizontal: ExplorerScrollbarH {}

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
                required property string nativeIconSource
                required property bool isDir

                readonly property bool selectedState: {
                    const rev = viewModel ? viewModel.selectionRevision : 0
                    return viewModel ? viewModel.isRowSelected(index) : false
                }

                readonly property bool editingState: viewModel && viewModel.inlineEditRow === index
                readonly property string editError: editingState && viewModel ? viewModel.inlineEditError : ""

                width: root.effectiveContentWidth + root.outerLeftPadding + root.outerRightPadding
                height: editingState && editError !== "" ? 58 : 38

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
                    x: root.outerLeftPadding + root.selectionHorizontalInset
                    y: root.selectionVerticalInset
                    width: root.effectiveContentWidth - root.selectionHorizontalInset * 2
                    height: parent.height - root.selectionVerticalInset * 2
                    radius: 7
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
                    x: root.outerLeftPadding + root.rowInnerLeftPadding
                    width: root.effectiveContentWidth - root.rowInnerLeftPadding - root.rowInnerRightPadding
                    height: parent.height
                    spacing: root.columnSpacing

                    Row {
                        width: root.nameColumnWidth
                        height: parent.height
                        spacing: 10

                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: icon
                            sourceOverride: nativeIconSource
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 16
                        }

                        Item {
                            width: Math.max(0, parent.width - 16 - parent.spacing)
                            height: parent.height

                            Text {
                                visible: !editingState
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
                                text: name
                                color: Theme.AppTheme.text
                                font.pixelSize: Theme.Typography.bodyLg
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
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

                    Text {
                        width: root.dateColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: dateModified
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.bodyLg
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: root.typeColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: type
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.bodyLg
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: root.sizeColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: size !== "" ? size : "-"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.bodyLg
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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

            Item {
                anchors.fill: parent
                visible: fileList.count === 0
                z: 1

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 48, 320)
                    spacing: Theme.Metrics.spacingMd

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
            }
        }
    }
}