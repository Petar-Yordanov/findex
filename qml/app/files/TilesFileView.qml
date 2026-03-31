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
        interactive: !(viewModel && viewModel.dragSelecting)

        ScrollBar.vertical: ExplorerScrollbarV {
            id: fileScrollBar
        }

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

            width: ListView.view.width
            height: 82

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: selectedState
                       ? Theme.AppTheme.selected
                       : mouseArea.containsMouse
                         ? Theme.AppTheme.selectedSoft
                         : "transparent"

                border.color: selectedState ? Theme.AppTheme.accent : "transparent"
                border.width: selectedState ? 1 : 0
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