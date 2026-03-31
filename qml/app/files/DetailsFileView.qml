import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Rectangle {
    id: root
    required property var viewModel

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

                    Text {
                        id: nameHeader
                        x: 0
                        width: root.nameColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Name"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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

                    Text {
                        id: dateHeader
                        x: root.nameColumnWidth + root.columnSpacing
                        width: root.dateColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Date modified"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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

                    Text {
                        id: typeHeader
                        x: root.nameColumnWidth + root.columnSpacing
                           + root.dateColumnWidth + root.columnSpacing
                        width: root.typeColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Type"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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

                    Text {
                        x: root.nameColumnWidth + root.columnSpacing
                           + root.dateColumnWidth + root.columnSpacing
                           + root.typeColumnWidth + root.columnSpacing
                        width: root.sizeColumnWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Size"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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
            interactive: !(viewModel && viewModel.dragSelecting)
            flickableDirection: Flickable.AutoFlickDirection
            contentWidth: root.effectiveContentWidth + root.outerLeftPadding + root.outerRightPadding

            ScrollBar.vertical: ExplorerScrollbarV {
                id: fileVerticalScrollBar
            }

            ScrollBar.horizontal: ExplorerScrollbarH {}

            SelectionBand {
                id: selectionBand
                parent: fileList.contentItem
                active: overlay.dragActive || dragState.dragActive
                startX: overlay.dragActive ? overlay.startX : dragState.startX
                currentX: overlay.dragActive ? overlay.currentX : dragState.currentX
                startY: overlay.dragActive ? overlay.startY : dragState.startY
                currentY: overlay.dragActive ? overlay.currentY : dragState.currentY
            }

            QtObject {
                id: dragState
                property bool dragActive: false
                property real startX: 0
                property real currentX: 0
                property real startY: 0
                property real currentY: 0
            }

            delegate: Item {
                required property int index
                required property string name
                required property string dateModified
                required property string type
                required property string size
                required property string icon

                readonly property bool selectedState: {
                    const rev = viewModel ? viewModel.selectionRevision : 0
                    return viewModel ? viewModel.isRowSelected(index) : false
                }

                width: root.effectiveContentWidth + root.outerLeftPadding + root.outerRightPadding
                height: 38

                Rectangle {
                    x: root.outerLeftPadding + root.selectionHorizontalInset
                    y: root.selectionVerticalInset
                    width: root.effectiveContentWidth - root.selectionHorizontalInset * 2
                    height: parent.height - root.selectionVerticalInset * 2
                    radius: 7
                    color: selectedState
                           ? Theme.AppTheme.selected
                           : mouseArea.containsMouse
                             ? Theme.AppTheme.selectedSoft
                             : "transparent"

                    border.color: selectedState ? Theme.AppTheme.accent : "transparent"
                    border.width: selectedState ? 1 : 0
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
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 16
                        }

                        Text {
                            width: Math.max(0, parent.width - 16 - parent.spacing)
                            anchors.verticalCenter: parent.verticalCenter
                            text: name
                            color: Theme.AppTheme.text
                            font.pixelSize: Theme.Typography.bodyLg
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
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
                        text: size !== "" ? size : "—"
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.bodyLg
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
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
                    property int lastValidTargetIndex: -1

                    onPressed: function(mouse) {
                        if (mouse.button !== Qt.LeftButton)
                            return

                        pressX = mouse.x
                        pressY = mouse.y
                        dragStarted = false
                        lastValidTargetIndex = index

                        var p = mouseArea.mapToItem(fileList.contentItem, mouse.x, mouse.y)
                        dragState.startX = p.x
                        dragState.currentX = p.x
                        dragState.startY = p.y
                        dragState.currentY = p.y
                        dragState.dragActive = false
                    }

                    onPositionChanged: function(mouse) {
                        if (!(mouse.buttons & Qt.LeftButton))
                            return

                        if (mouse.modifiers & Qt.ControlModifier)
                            return

                        var p = mouseArea.mapToItem(fileList.contentItem, mouse.x, mouse.y)
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

                        var probeX = Math.max(1, Math.min(fileList.width - 2, fileList.width * 0.5))
                        var targetIndex = fileList.indexAt(probeX, p.y)

                        if (targetIndex >= 0) {
                            lastValidTargetIndex = targetIndex
                        } else if (p.y < 0) {
                            targetIndex = 0
                            lastValidTargetIndex = targetIndex
                        } else if (p.y > fileList.contentHeight) {
                            targetIndex = Math.max(0, fileList.count - 1)
                            lastValidTargetIndex = targetIndex
                        } else if (lastValidTargetIndex >= 0) {
                            targetIndex = lastValidTargetIndex
                        } else {
                            targetIndex = index
                        }

                        viewModel.updateDragSelection(targetIndex)
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

                property real pressX: 0
                property real pressY: 0
                property real startX: 0
                property real startY: 0
                property real currentX: 0
                property real currentY: 0
                property bool dragActive: false
                property bool pressedInRealEmptyArea: false
                property int anchorIndex: -1
                property int lastValidOverlayIndex: -1

                function isBelowItems(yInView) {
                    return yInView > (fileList.contentHeight - fileList.contentY)
                }

                onPressed: function(mouse) {
                    pressedInRealEmptyArea = isBelowItems(mouse.y)

                    if (!pressedInRealEmptyArea) {
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
                    lastValidOverlayIndex = fileList.count > 0 ? fileList.count - 1 : -1
                }

                onPositionChanged: function(mouse) {
                    if (!pressedInRealEmptyArea) {
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

                    var firstIndex = fileList.count > 0 ? fileList.count - 1 : -1
                    var probeX = Math.max(1, Math.min(fileList.width - 2, fileList.width * 0.5))
                    var lastIndex = fileList.indexAt(probeX, currentY)

                    if (lastIndex >= 0) {
                        lastValidOverlayIndex = lastIndex
                    } else if (currentY < 0) {
                        lastIndex = 0
                        lastValidOverlayIndex = lastIndex
                    } else if (currentY > fileList.contentHeight) {
                        lastIndex = fileList.count > 0 ? fileList.count - 1 : -1
                        lastValidOverlayIndex = lastIndex
                    } else {
                        lastIndex = lastValidOverlayIndex
                    }

                    if (firstIndex < 0 || lastIndex < 0)
                        return

                    if (!dragActive) {
                        dragActive = true
                        anchorIndex = firstIndex
                        viewModel.beginDragSelection(anchorIndex)
                    }

                    viewModel.selectRange(firstIndex, lastIndex)
                }

                onReleased: function(mouse) {
                    if (!pressedInRealEmptyArea) {
                        pressedInRealEmptyArea = false
                        mouse.accepted = false
                        return
                    }

                    if (dragActive)
                        viewModel.endDragSelection()

                    dragActive = false
                    anchorIndex = -1
                    pressedInRealEmptyArea = false
                }

                onCanceled: {
                    if (dragActive)
                        viewModel.endDragSelection()

                    dragActive = false
                    anchorIndex = -1
                    pressedInRealEmptyArea = false
                }
            }
        }
    }
}