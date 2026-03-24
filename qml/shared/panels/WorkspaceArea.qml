import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components/foundation"
import "../../components/theme" as Theme

Item {
    id: workspaceArea

    required property var rootWindow
    required property var sidebarModel
    required property var drivesModel
    required property var filesModel
    required property var notificationsModel

    required property var sidebarContextMenu
    required property var fileRowContextMenu
    required property var multiFileContextMenu
    required property var emptyAreaContextMenu
    required property var viewModeMenu
    required property var notificationsPopup

    required property Component detailsViewComponent
    required property Component tilesViewComponent
    required property Component compactViewComponent
    required property Component largeIconsViewComponent

    property int sidebarWidth: 286
    property int sidebarMinWidth: 220
    property int sidebarMaxWidth: Math.max(360, width * 0.45)
    property int splitterWidth: 8

    Rectangle {
        id: sidebarPane
        x: 0
        y: 0
        width: workspaceArea.sidebarWidth
        height: parent.height
        color: Theme.AppTheme.surface2
        border.color: Theme.AppTheme.borderSoft
        border.width: Theme.Metrics.borderWidth

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.Metrics.spacingMd
            spacing: Theme.Metrics.spacingLg

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.Metrics.radiusLg
                color: "transparent"

                TreeView {
                    id: sidebarTree
                    anchors.fill: parent
                    model: workspaceArea.sidebarModel
                    clip: true
                    alternatingRows: false
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    contentWidth: width

                    ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }
                    ScrollBar.horizontal: null

                    delegate: Item {
                        required property TreeView treeView
                        required property bool isTreeNode
                        required property bool expanded
                        required property bool hasChildren
                        required property int depth
                        required property int row
                        required property int column
                        required property bool current
                        required property bool selected

                        readonly property string itemLabel: treeView.model.data(treeView.index(row, 0), Qt.DisplayRole) || ""
                        readonly property string itemIcon: treeView.model.data(treeView.index(row, 1), Qt.DisplayRole) || ""
                        readonly property bool itemSection: (treeView.model.data(treeView.index(row, 2), Qt.DisplayRole) === true)
                        readonly property string itemKind: treeView.model.data(treeView.index(row, 3), Qt.DisplayRole) || ""

                        readonly property bool dropHovered: !itemSection
                                                           && workspaceArea.rootWindow.navDropHoverLabel === itemLabel
                                                           && workspaceArea.rootWindow.navDropHoverKind === itemKind

                        width: sidebarTree.width
                        implicitWidth: sidebarTree.width
                        implicitHeight: itemSection ? 28 : 34

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.Metrics.radiusMd
                            color: itemSection ? "transparent"
                                               : dropHovered
                                                 ? Theme.AppTheme.selectedSoft
                                                 : tapArea.pressed
                                                   ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                                   : (workspaceArea.rootWindow.selectedSidebarLabel === itemLabel
                                                      && workspaceArea.rootWindow.selectedSidebarKind === itemKind)
                                                     ? Theme.AppTheme.selected
                                                     : tapArea.containsMouse
                                                       ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                                       : "transparent"
                            border.color: dropHovered
                                          ? Theme.AppTheme.accent
                                          : tapArea.pressed
                                            ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                            : "transparent"
                            border.width: (dropHovered || tapArea.pressed) ? 1 : 0
                        }

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.Metrics.spacingMd + depth * 14
                            anchors.rightMargin: Theme.Metrics.spacingLg

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: itemSection ? 6 : 8
                                spacing: Theme.Metrics.spacingSm

                                Item {
                                    width: 12
                                    height: 12

                                    Item {
                                        width: 12
                                        height: 12

                                        AppIcon {
                                            anchors.centerIn: parent
                                            visible: hasChildren
                                            name: expanded ? "keyboard-arrow-down" : "chevron-right"
                                            darkTheme: Theme.AppTheme.isDark
                                            iconSize: Theme.Metrics.iconXs
                                            iconOpacity: 0.65
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            visible: hasChildren
                                            acceptedButtons: Qt.LeftButton
                                            onClicked: treeView.toggleExpanded(row)
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        visible: hasChildren
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: treeView.toggleExpanded(row)
                                    }
                                }

                                Item {
                                    visible: !itemSection
                                    width: 16
                                    height: 16

                                    AppIcon {
                                        anchors.centerIn: parent
                                        name: itemIcon
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: 15
                                    }
                                }

                                Text {
                                    text: itemLabel
                                    color: itemSection ? Theme.AppTheme.muted : Theme.AppTheme.text
                                    font.pixelSize: itemSection ? 11 : 13
                                    font.bold: itemSection
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        DropArea {
                            anchors.fill: parent

                            onEntered: function(drag) {
                                var ok = !itemSection && !hasChildren
                                drag.accepted = ok
                                if (ok)
                                    workspaceArea.rootWindow.setNavDropHover(itemLabel, itemKind)
                            }

                            onExited: function(drag) {
                                workspaceArea.rootWindow.clearNavDropHover(itemLabel, itemKind)
                            }

                            onDropped: function(drop) {
                                if (!itemSection) {
                                    drop.accepted = true
                                    workspaceArea.rootWindow.handleDroppedItem(itemLabel, itemKind)
                                    workspaceArea.rootWindow.clearNavDropHover(itemLabel, itemKind)
                                }
                            }
                        }

                        MouseArea {
                            id: tapArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: function(mouse) {
                                if (mouse.button !== Qt.LeftButton)
                                    return

                                if (hasChildren)
                                    treeView.toggleExpanded(row)
                                else
                                    workspaceArea.rootWindow.openLocation(itemLabel, itemIcon, itemKind)
                            }

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.RightButton && !itemSection) {
                                    workspaceArea.rootWindow.contextSidebarLabel = itemLabel
                                    workspaceArea.rootWindow.contextSidebarKind = itemKind
                                    workspaceArea.rootWindow.contextSidebarIcon = itemIcon
                                    workspaceArea.sidebarContextMenu.popup()
                                }
                            }
                        }
                    }

                    Component.onCompleted: expand(0)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 + 22 + (workspaceArea.drivesModel.count * 48) + Math.max(0, workspaceArea.drivesModel.count - 1) * 1 + 20
                Layout.minimumHeight: 120
                radius: Theme.Metrics.radiusXl
                color: Theme.AppTheme.isDark ? "#171d27" : "#fbfcfd"
                border.color: Theme.AppTheme.borderSoft
                border.width: Theme.Metrics.borderWidth

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.Metrics.spacingLg
                    spacing: 1

                    Text {
                        text: "Drives"
                        color: Theme.AppTheme.text
                        font.pixelSize: Theme.Typography.body
                        font.bold: true
                    }

                    Repeater {
                        model: workspaceArea.drivesModel

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            width: parent ? parent.width : 240
                            height: 48
                            radius: Theme.Metrics.radiusMd

                            readonly property real usedPct: modelData.total > 0 ? (modelData.used / modelData.total) : 0
                            readonly property color usedColor: usedPct >= 0.85 ? Theme.AppTheme.driveUsedRed : Theme.AppTheme.driveUsedBlue
                            readonly property bool dropHovered: workspaceArea.rootWindow.navDropHoverLabel === modelData.label
                                                                && workspaceArea.rootWindow.navDropHoverKind === "drive"

                            color: dropHovered
                                   ? Theme.AppTheme.selectedSoft
                                   : driveMouseArea.pressed
                                     ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                     : (workspaceArea.rootWindow.selectedSidebarKind === "drive"
                                        && workspaceArea.rootWindow.selectedSidebarLabel === modelData.label)
                                       ? Theme.AppTheme.selected
                                       : driveMouseArea.containsMouse
                                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                         : "transparent"

                            border.color: dropHovered
                                          ? Theme.AppTheme.accent
                                          : driveMouseArea.pressed
                                            ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                            : "transparent"
                            border.width: (dropHovered || driveMouseArea.pressed) ? 1 : 0

                            Column {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.Metrics.spacingMd
                                anchors.rightMargin: Theme.Metrics.spacingMd
                                anchors.topMargin: Theme.Metrics.spacingXs
                                anchors.bottomMargin: Theme.Metrics.spacingXs
                                spacing: 2

                                Row {
                                    spacing: Theme.Metrics.spacingSm

                                    AppIcon {
                                        name: modelData.icon
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconSm
                                    }

                                    Text {
                                        text: modelData.label
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.body
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 5
                                    radius: Theme.Metrics.radiusXs
                                    color: Theme.AppTheme.driveFree

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, usedPct))
                                        height: parent.height
                                        radius: Theme.Metrics.radiusXs
                                        color: usedColor
                                    }
                                }

                                Text {
                                    text: modelData.usedText
                                    color: Theme.AppTheme.muted
                                    font.pixelSize: 10
                                }
                            }

                            DropArea {
                                anchors.fill: parent

                                onEntered: function(drag) {
                                    drag.accepted = true
                                    workspaceArea.rootWindow.setNavDropHover(modelData.label, "drive")
                                }

                                onExited: function(drag) {
                                    workspaceArea.rootWindow.clearNavDropHover(modelData.label, "drive")
                                }

                                onDropped: function(drop) {
                                    drop.accepted = true
                                    workspaceArea.rootWindow.handleDroppedItem(modelData.label, "drive")
                                }
                            }

                            MouseArea {
                                id: driveMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: workspaceArea.rootWindow.openLocation(modelData.label, modelData.icon, "drive")

                                onPressed: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        workspaceArea.rootWindow.contextSidebarLabel = modelData.label
                                        workspaceArea.rootWindow.contextSidebarKind = "drive"
                                        workspaceArea.rootWindow.contextSidebarIcon = modelData.icon
                                        workspaceArea.sidebarContextMenu.popup()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: sidebarSplitter
        x: sidebarPane.width
        y: 0
        width: workspaceArea.splitterWidth
        height: parent.height
        color: splitterMouse.pressed
               ? (Theme.AppTheme.isDark ? "#2a3342" : "#d7dfeb")
               : splitterMouse.containsMouse
                 ? (Theme.AppTheme.isDark ? "#212938" : "#e3e9f2")
                 : "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: parent.height
            radius: 1
            color: splitterMouse.pressed
                   ? Theme.AppTheme.accent
                   : splitterMouse.containsMouse
                     ? Theme.AppTheme.border
                     : "transparent"
        }

        MouseArea {
            id: splitterMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            acceptedButtons: Qt.LeftButton

            property real pressSceneX: 0
            property int startWidth: 0

            onPressed: function(mouse) {
                var p = splitterMouse.mapToItem(workspaceArea, mouse.x, mouse.y)
                pressSceneX = p.x
                startWidth = workspaceArea.sidebarWidth
            }

            onPositionChanged: function(mouse) {
                if (!pressed)
                    return

                var p = splitterMouse.mapToItem(workspaceArea, mouse.x, mouse.y)
                var dx = p.x - pressSceneX
                var nextWidth = startWidth + dx

                nextWidth = Math.max(
                    workspaceArea.sidebarMinWidth,
                    Math.min(workspaceArea.sidebarMaxWidth, nextWidth)
                )

                workspaceArea.sidebarWidth = nextWidth
            }
        }
    }

    Rectangle {
        id: contentPane
        x: sidebarPane.width + sidebarSplitter.width
        y: 0
        width: parent.width - x
        height: parent.height
        color: Theme.AppTheme.surface3
        border.color: Theme.AppTheme.borderSoft
        border.width: Theme.Metrics.borderWidth

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: workspaceArea.rootWindow.currentViewMode === "Details" ? 40 : 0
                        visible: workspaceArea.rootWindow.currentViewMode === "Details"
                        color: Theme.AppTheme.surface2
                        border.color: Theme.AppTheme.borderSoft
                        border.width: Theme.Metrics.borderWidth

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.Metrics.spacingLg
                            anchors.rightMargin: Theme.Metrics.spacingLg

                            Rectangle {
                                id: nameHeader
                                x: 0
                                y: 0
                                width: workspaceArea.rootWindow.detailsNameWidth
                                height: parent.height
                                color: nameHeaderMouse.pressed
                                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                       : nameHeaderMouse.containsMouse
                                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                         : "transparent"
                                border.color: nameHeaderMouse.pressed
                                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                              : "transparent"
                                border.width: nameHeaderMouse.pressed ? 1 : 0

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Name"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.body
                                        font.bold: true
                                    }

                                    AppIcon {
                                        visible: workspaceArea.rootWindow.sortColumn === 0
                                        name: workspaceArea.rootWindow.sortAscending
                                              ? "keyboard-arrow-up"
                                              : "keyboard-arrow-down"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                    }
                                }

                                MouseArea {
                                    id: nameHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: workspaceArea.rootWindow.sortFiles(0)
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 8
                                    color: resizeNameMouse.pressed
                                           ? Theme.AppTheme.accent
                                           : resizeNameMouse.containsMouse
                                             ? Theme.AppTheme.hover
                                             : "transparent"

                                    MouseArea {
                                        id: resizeNameMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeHorCursor

                                        property real pressSceneX: 0
                                        property int startWidth: 0

                                        onPressed: function(mouse) {
                                            var p = resizeNameMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            pressSceneX = p.x
                                            startWidth = workspaceArea.rootWindow.detailsNameWidth
                                        }

                                        onPositionChanged: function(mouse) {
                                            if (!pressed)
                                                return

                                            var p = resizeNameMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            var dx = p.x - pressSceneX
                                            workspaceArea.rootWindow.detailsNameWidth = Math.max(180, startWidth + dx)

                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                fileViewLoader.item.relayout()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: dateHeader
                                x: workspaceArea.rootWindow.detailsNameWidth
                                y: 0
                                width: workspaceArea.rootWindow.detailsDateWidth
                                height: parent.height
                                color: dateHeaderMouse.pressed
                                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                       : dateHeaderMouse.containsMouse
                                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                         : "transparent"
                                border.color: dateHeaderMouse.pressed
                                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                              : "transparent"
                                border.width: dateHeaderMouse.pressed ? 1 : 0

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Date modified"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.body
                                        font.bold: true
                                    }

                                    AppIcon {
                                        visible: workspaceArea.rootWindow.sortColumn === 1
                                        name: workspaceArea.rootWindow.sortAscending
                                              ? "keyboard-arrow-up"
                                              : "keyboard-arrow-down"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                    }
                                }

                                MouseArea {
                                    id: dateHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: workspaceArea.rootWindow.sortFiles(1)
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 8
                                    color: resizeDateMouse.pressed
                                           ? Theme.AppTheme.accent
                                           : resizeDateMouse.containsMouse
                                             ? Theme.AppTheme.hover
                                             : "transparent"

                                    MouseArea {
                                        id: resizeDateMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeHorCursor

                                        property real pressSceneX: 0
                                        property int startWidth: 0

                                        onPressed: function(mouse) {
                                            var p = resizeDateMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            pressSceneX = p.x
                                            startWidth = workspaceArea.rootWindow.detailsDateWidth
                                        }

                                        onPositionChanged: function(mouse) {
                                            if (!pressed)
                                                return

                                            var p = resizeDateMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            var dx = p.x - pressSceneX
                                            workspaceArea.rootWindow.detailsDateWidth = Math.max(160, startWidth + dx)

                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                fileViewLoader.item.relayout()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: typeHeader
                                x: workspaceArea.rootWindow.detailsNameWidth + workspaceArea.rootWindow.detailsDateWidth
                                y: 0
                                width: workspaceArea.rootWindow.detailsTypeWidth
                                height: parent.height
                                color: typeHeaderMouse.pressed
                                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                       : typeHeaderMouse.containsMouse
                                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                         : "transparent"
                                border.color: typeHeaderMouse.pressed
                                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                              : "transparent"
                                border.width: typeHeaderMouse.pressed ? 1 : 0

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Type"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.body
                                        font.bold: true
                                    }

                                    AppIcon {
                                        visible: workspaceArea.rootWindow.sortColumn === 2
                                        name: workspaceArea.rootWindow.sortAscending
                                              ? "keyboard-arrow-up"
                                              : "keyboard-arrow-down"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                    }
                                }

                                MouseArea {
                                    id: typeHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: workspaceArea.rootWindow.sortFiles(2)
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 8
                                    color: resizeTypeMouse.pressed
                                           ? Theme.AppTheme.accent
                                           : resizeTypeMouse.containsMouse
                                             ? Theme.AppTheme.hover
                                             : "transparent"

                                    MouseArea {
                                        id: resizeTypeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeHorCursor

                                        property real pressSceneX: 0
                                        property int startWidth: 0

                                        onPressed: function(mouse) {
                                            var p = resizeTypeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            pressSceneX = p.x
                                            startWidth = workspaceArea.rootWindow.detailsTypeWidth
                                        }

                                        onPositionChanged: function(mouse) {
                                            if (!pressed)
                                                return

                                            var p = resizeTypeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            var dx = p.x - pressSceneX
                                            workspaceArea.rootWindow.detailsTypeWidth = Math.max(140, startWidth + dx)

                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                fileViewLoader.item.relayout()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: sizeHeader
                                x: workspaceArea.rootWindow.detailsNameWidth
                                   + workspaceArea.rootWindow.detailsDateWidth
                                   + workspaceArea.rootWindow.detailsTypeWidth
                                y: 0
                                width: parent.width - x
                                height: parent.height
                                color: sizeHeaderMouse.pressed
                                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                       : sizeHeaderMouse.containsMouse
                                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                                         : "transparent"
                                border.color: sizeHeaderMouse.pressed
                                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                                              : "transparent"
                                border.width: sizeHeaderMouse.pressed ? 1 : 0

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Size"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.body
                                        font.bold: true
                                    }

                                    AppIcon {
                                        visible: workspaceArea.rootWindow.sortColumn === 3
                                        name: workspaceArea.rootWindow.sortAscending
                                              ? "keyboard-arrow-up"
                                              : "keyboard-arrow-down"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.iconXs
                                    }
                                }

                                MouseArea {
                                    id: sizeHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: workspaceArea.rootWindow.sortFiles(3)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        color: "transparent"

                        Loader {
                            id: fileViewLoader
                            anchors.fill: parent
                            sourceComponent: {
                                if (workspaceArea.rootWindow.currentViewMode === "Details")
                                    return workspaceArea.detailsViewComponent
                                if (workspaceArea.rootWindow.currentViewMode === "Tiles")
                                    return workspaceArea.tilesViewComponent
                                if (workspaceArea.rootWindow.currentViewMode === "Compact")
                                    return workspaceArea.compactViewComponent
                                if (workspaceArea.rootWindow.currentViewMode === "Large icons")
                                    return workspaceArea.largeIconsViewComponent
                                return workspaceArea.detailsViewComponent
                            }
                        }
                    }
                }

                Rectangle {
                    id: previewSplitter
                    visible: workspaceArea.rootWindow.previewEnabled
                    Layout.preferredWidth: workspaceArea.rootWindow.previewEnabled ? 8 : 0
                    Layout.minimumWidth: workspaceArea.rootWindow.previewEnabled ? 8 : 0
                    Layout.maximumWidth: workspaceArea.rootWindow.previewEnabled ? 8 : 0
                    Layout.fillHeight: true
                    color: previewResizeMouse.pressed
                           ? (Theme.AppTheme.isDark ? "#2a3342" : "#d7dfeb")
                           : previewResizeMouse.containsMouse
                             ? (Theme.AppTheme.isDark ? "#212938" : "#e3e9f2")
                             : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        radius: 1
                        color: previewResizeMouse.pressed
                               ? Theme.AppTheme.accent
                               : previewResizeMouse.containsMouse
                                 ? Theme.AppTheme.border
                                 : "transparent"
                    }

                    MouseArea {
                        id: previewResizeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        acceptedButtons: Qt.LeftButton

                        property real pressSceneX: 0
                        property int startWidth: 0

                        onPressed: function(mouse) {
                            var p = previewResizeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                            pressSceneX = p.x
                            startWidth = workspaceArea.rootWindow.previewPaneWidth
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed)
                                return

                            var p = previewResizeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                            var dx = p.x - pressSceneX

                            var maxAllowed = Math.max(
                                workspaceArea.rootWindow.previewPaneMinWidth,
                                Math.min(workspaceArea.rootWindow.previewPaneMaxWidth, contentPane.width - 220)
                            )

                            workspaceArea.rootWindow.previewPaneWidth = Math.max(
                                workspaceArea.rootWindow.previewPaneMinWidth,
                                Math.min(maxAllowed, startWidth - dx)
                            )
                        }
                    }
                }

                Rectangle {
                    visible: workspaceArea.rootWindow.previewEnabled
                    Layout.preferredWidth: workspaceArea.rootWindow.previewEnabled
                                           ? workspaceArea.rootWindow.previewPaneWidth : 0
                    Layout.minimumWidth: workspaceArea.rootWindow.previewEnabled
                                         ? workspaceArea.rootWindow.previewPaneWidth : 0
                    Layout.maximumWidth: workspaceArea.rootWindow.previewEnabled
                                         ? workspaceArea.rootWindow.previewPaneWidth : 0
                    Layout.fillHeight: true
                    color: Theme.AppTheme.isDark ? "#141920" : "#fbfcfd"
                    border.color: Theme.AppTheme.borderSoft
                    border.width: Theme.Metrics.borderWidth

                    Flickable {
                        id: previewFlick
                        anchors.fill: parent
                        anchors.leftMargin: Theme.Metrics.spacingXl
                        anchors.topMargin: Theme.Metrics.spacingXl
                        anchors.bottomMargin: Theme.Metrics.spacingXl
                        anchors.rightMargin: Theme.Metrics.spacingSm
                        clip: true
                        contentWidth: width
                        contentHeight: previewColumn.implicitHeight

                        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }

                        Column {
                            id: previewColumn
                            width: Math.max(0, previewFlick.width - 20)
                            spacing: Theme.Metrics.spacingXl

                            Text {
                                text: "Preview"
                                color: Theme.AppTheme.text
                                font.pixelSize: Theme.Typography.bodyLg
                                font.bold: true
                            }

                            Rectangle {
                                width: parent.width
                                height: 180
                                radius: Theme.Metrics.radiusXl
                                color: Theme.AppTheme.isDark ? "#1b2230" : "#f4f7fb"
                                border.color: Theme.AppTheme.borderSoft
                                border.width: Theme.Metrics.borderWidth

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.Metrics.spacingMd
                                    visible: !workspaceArea.rootWindow.previewData.visible

                                    AppIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        name: "preview"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.icon3xl
                                        iconOpacity: 0.55
                                    }

                                    Text {
                                        text: "Select an item to preview"
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: Theme.Typography.body
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.Metrics.spacingMd
                                    visible: workspaceArea.rootWindow.previewData.visible

                                    AppIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        name: workspaceArea.rootWindow.previewData.icon || "insert-drive-file"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: Theme.Metrics.icon4xl
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: workspaceArea.rootWindow.previewData.previewType === "multi"
                                              ? "Multiple items"
                                              : workspaceArea.rootWindow.previewData.previewType === "image"
                                                ? "Mock image preview"
                                                : workspaceArea.rootWindow.previewData.previewType === "text"
                                                  ? "Mock text preview"
                                                  : workspaceArea.rootWindow.previewData.previewType === "document"
                                                    ? "Mock document preview"
                                                    : workspaceArea.rootWindow.previewData.previewType === "audio"
                                                      ? "Mock audio preview"
                                                      : workspaceArea.rootWindow.previewData.previewType === "video"
                                                        ? "Mock video preview"
                                                        : workspaceArea.rootWindow.previewData.previewType === "archive"
                                                          ? "Mock archive preview"
                                                          : workspaceArea.rootWindow.previewData.previewType === "folder"
                                                            ? "Mock folder preview"
                                                            : "Mock file preview"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.bodyLg
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Backend-driven placeholder"
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: Theme.Typography.caption
                                    }
                                }
                            }

                            Text {
                                visible: workspaceArea.rootWindow.previewData.visible
                                width: parent.width
                                text: workspaceArea.rootWindow.previewData.name || ""
                                color: Theme.AppTheme.text
                                font.pixelSize: Theme.Typography.subtitle
                                font.bold: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: workspaceArea.rootWindow.previewData.visible
                                width: parent.width
                                text: workspaceArea.rootWindow.previewData.type || ""
                                color: Theme.AppTheme.muted
                                font.pixelSize: Theme.Typography.body
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: workspaceArea.rootWindow.previewData.visible
                                         && workspaceArea.rootWindow.previewData.summary !== ""
                                width: parent.width
                                text: workspaceArea.rootWindow.previewData.summary || ""
                                color: Theme.AppTheme.text
                                font.pixelSize: Theme.Typography.body
                                wrapMode: Text.Wrap
                            }

                            Rectangle {
                                visible: workspaceArea.rootWindow.previewData.visible
                                width: parent.width
                                height: 1
                                color: Theme.AppTheme.borderSoft
                            }

                            Column {
                                visible: workspaceArea.rootWindow.previewData.visible
                                width: parent.width
                                spacing: Theme.Metrics.spacingSm

                                Text {
                                    text: "Details"
                                    color: Theme.AppTheme.text
                                    font.pixelSize: Theme.Typography.body
                                    font.bold: true
                                }

                                Row {
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Modified:"
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: Theme.Typography.caption
                                        font.bold: true
                                    }

                                    Text {
                                        text: workspaceArea.rootWindow.previewData.dateModified || "—"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.caption
                                    }
                                }

                                Row {
                                    spacing: Theme.Metrics.spacingSm

                                    Text {
                                        text: "Size:"
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: Theme.Typography.caption
                                        font.bold: true
                                    }

                                    Text {
                                        text: workspaceArea.rootWindow.previewData.size || "—"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: Theme.Typography.caption
                                    }
                                }
                            }

                            Column {
                                visible: workspaceArea.rootWindow.previewData.visible
                                width: parent.width
                                spacing: Theme.Metrics.spacingSm

                                Text {
                                    text: "Mock content"
                                    color: Theme.AppTheme.text
                                    font.pixelSize: Theme.Typography.body
                                    font.bold: true
                                }

                                Repeater {
                                    model: workspaceArea.rootWindow.previewData.lines
                                           ? workspaceArea.rootWindow.previewData.lines : []

                                    delegate: Text {
                                        required property var modelData
                                        width: previewColumn.width
                                        text: "• " + modelData
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: Theme.Typography.caption
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: Theme.AppTheme.isDark ? "#141920" : "#f6f7f9"
                border.color: Theme.AppTheme.borderSoft
                border.width: Theme.Metrics.borderWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.Metrics.spacingXl
                    anchors.rightMargin: Theme.Metrics.spacingXl

                    Text {
                        text: workspaceArea.rootWindow.selectedFileCount() > 0
                              ? (workspaceArea.filesModel.rowCount + " items   "
                                 + workspaceArea.rootWindow.selectedFileCount() + " selected")
                              : (workspaceArea.filesModel.rowCount + " items")
                        color: Theme.AppTheme.muted
                        font.pixelSize: Theme.Typography.caption
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: bottomViewButton
                        width: 24
                        height: 24
                        radius: 7
                        color: bottomViewMouse.pressed
                            ? Theme.AppTheme.pressed
                            : bottomViewMouse.containsMouse
                                ? Theme.AppTheme.hover
                                : (Theme.AppTheme.isDark ? "#1a1f27" : "#ffffff")
                        border.color: bottomViewMouse.containsMouse || bottomViewMouse.pressed
                                    ? Theme.AppTheme.border
                                    : Theme.AppTheme.borderSoft
                        border.width: Theme.Metrics.borderWidth

                        AppIcon {
                            anchors.centerIn: parent
                            name: workspaceArea.rootWindow.currentViewMode === "Large icons"
                                  ? "grid-view"
                                  : workspaceArea.rootWindow.currentViewMode === "Tiles"
                                    ? "tile-view"
                                    : workspaceArea.rootWindow.currentViewMode === "Details"
                                      ? "detailed-view"
                                      : "list-view"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 13
                            iconOpacity: 0.75
                        }

                        MouseArea {
                            id: bottomViewMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: workspaceArea.viewModeMenu.popup()

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.RightButton)
                                    workspaceArea.viewModeMenu.popup()
                            }
                        }
                    }

                    Rectangle {
                        id: notificationsButton
                        width: 24
                        height: 24
                        radius: 7
                        color: notificationsMouse.pressed
                            ? Theme.AppTheme.pressed
                            : notificationsMouse.containsMouse
                                ? Theme.AppTheme.hover
                                : (Theme.AppTheme.isDark ? "#1a1f27" : "#ffffff")
                        border.color: notificationsMouse.containsMouse || notificationsMouse.pressed
                                    ? Theme.AppTheme.border
                                    : Theme.AppTheme.borderSoft
                        border.width: Theme.Metrics.borderWidth

                        AppIcon {
                            anchors.centerIn: parent
                            name: "notifications"
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 13
                            iconOpacity: 0.8
                        }

                        Rectangle {
                            visible: workspaceArea.notificationsModel.count > 0
                            width: 8
                            height: 8
                            radius: 4
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 2
                            anchors.rightMargin: 2
                            color: Theme.AppTheme.accent
                            z: 2
                        }

                        MouseArea {
                            id: notificationsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: {
                                var p = notificationsButton.mapToItem(
                                    workspaceArea.rootWindow.contentItem,
                                    notificationsButton.width - workspaceArea.notificationsPopup.width,
                                    -workspaceArea.notificationsPopup.height - 8
                                )
                                workspaceArea.notificationsPopup.x = p.x
                                workspaceArea.notificationsPopup.y = p.y
                                workspaceArea.notificationsPopup.open()
                            }
                        }
                    }
                }
            }
        }
    }
}