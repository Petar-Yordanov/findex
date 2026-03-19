import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml.Models
import Qt.labs.qmlmodels as Labs
import "components/foundation"
import "components/theme" as Theme
import "features/files"

Window {
    id: root
    width: 1400
    height: 860
    visible: true
    title: "Findex"
    color: Theme.AppTheme.bg
    flags: Qt.Window
         | Qt.FramelessWindowHint
         | Qt.WindowMinMaxButtonsHint
         | Qt.WindowCloseButtonHint
    minimumWidth: 640
    minimumHeight: 480

    property string themeMode: "Light" // Dark | Light | System
    property var backend: fileManagerBridge

    onThemeModeChanged: Theme.AppTheme.mode = themeMode

    property int notificationOverlayBottomOffset: notificationsPopup.visible ? (notificationsPopup.height + 52) : 40
    property var tabAutoScrollTimerRef: tabAutoScrollTimer

    property bool tabDragActive: false
    property bool tabPressActive: false

    property int currentTab: 1
    property int currentFileRow: 0
    property bool editingPath: false
    property string currentSearch: ""
    property string currentViewMode: "Details"
    property string searchScope: "folder" // folder | global

    property int contextTabIndex: -1
    property int contextFileRow: -1
    property string contextSidebarLabel: ""
    property string contextSidebarKind: ""
    property string contextSidebarIcon: ""
    property string selectedSidebarLabel: "Local Disk (C:)"
    property string selectedSidebarKind: "drive"

    property int resizeMargin: visibility === Window.Maximized ? 0 : 6

    property int detailsNameWidth: 430
    property int detailsDateWidth: 220
    property int detailsTypeWidth: 210
    property int detailsSizeWidth: 140

    property int sortColumn: 0 // 0=name, 1=date, 2=type, 3=size
    property bool sortAscending: true
    property int nextNotificationId: 1

    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property string confirmDialogAction: ""
    property int confirmDialogRow: -1

    property string tooltipText: ""
    property int tooltipDelay: 450

    ListModel {
        id: notificationsModel
    }
    property int contextBreadcrumbIndex: -1

    property int tabWidth: 210
    property int tabSpacing: 6
    property int tabAutoScrollDirection: 0 // -1 left, 1 right, 0 none
    property int draggedTabIndex: -1
    property real draggedTabOffset: 0
    property int draggedTabStartIndex: -1

    property int draggedFileRow: -1
    property var draggedFileRows: ({})
    property int draggedFileCount: 0
    property string draggedFileName: ""
    property string draggedFileType: ""
    property string draggedFileIcon: ""
    property string pendingSortOrderForMenu: "Ascending"
    property int detailsDropHoverRow: -1
    property url draggedFilePreviewUrl: ""
    property bool dragPreviewReady: false
    property string navDropHoverLabel: ""
    property string navDropHoverKind: ""
    property int breadcrumbDropHoverIndex: -1
    property bool showHiddenFiles: false

    property int detailsRowHeight: 34

    property var selectedFileRows: ({})
    property int selectionAnchorRow: -1
    property real draggedTabStartContentX: 0

    property bool detailsSelectionActive: false
    property bool detailsSelectionMoved: false
    property real detailsSelectionStartX: 0
    property real detailsSelectionStartY: 0
    property real detailsSelectionCurrentX: 0
    property real detailsSelectionCurrentY: 0

    property int editingFileRow: -1
    property string editingFileNameDraft: ""

    property bool windowMoveActive: false
    property bool hoverFxEnabled: !windowMoveActive

    property int editingTabIndex: -1
    property string editingTabTitleDraft: ""

    property bool previewEnabled: false
    property int previewPaneWidth: 320
    property int previewPaneMinWidth: 220
    property int previewPaneMaxWidth: Math.max(420, Math.floor(width * 0.45))
    property int previewPaneLastExpandedWidth: 320

    property var previewData: ({
        visible: false,
        name: "",
        type: "",
        icon: "insert-drive-file",
        previewType: "none",
        size: "",
        dateModified: "",
        summary: "",
        lines: []
    })

    onCurrentFileRowChanged: refreshPreviewSelection()
    onSelectedFileRowsChanged: refreshPreviewSelection()
    onPreviewEnabledChanged: refreshPreviewSelection()
    onPreviewPaneWidthChanged: {
        if (root.previewEnabled && root.previewPaneWidth >= root.previewPaneMinWidth)
            root.previewPaneLastExpandedWidth = root.previewPaneWidth
    }

    function copyPathsForItems(items, relativeToCurrentDir, recursive) {
        applySnapshot(backend.copyItemPaths(items,
                                            relativeToCurrentDir === true,
                                            recursive === true))
    }

    function copySelectedOrCurrentPaths(relativeToCurrentDir, recursive) {
        var items = []

        if (root.selectedFileCount() > 0)
            items = root.selectedItemsForBackend()
        else if (root.currentFileRow >= 0)
            items = root.singleItemForBackend(root.currentFileRow)

        root.copyPathsForItems(items, relativeToCurrentDir, recursive)
    }

    function copySidebarContextPath() {
        if (root.contextSidebarLabel !== "")
            applySnapshot(backend.copySidebarPath(root.contextSidebarLabel,
                                                  root.contextSidebarKind))
    }

    function copyBreadcrumbPathAt(index) {
        if (index >= 0)
            applySnapshot(backend.copyBreadcrumbPath(index))
    }

    function replaceListModel(model, rows) {
        model.clear()
        for (var i = 0; i < rows.length; ++i)
            model.append(rows[i])
    }

    function formatBytes(bytes) {
        if (bytes < 0 || isNaN(bytes))
            return ""

        var units = ["B", "KB", "MB", "GB", "TB"]
        var value = bytes
        var unitIndex = 0

        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024
            ++unitIndex
        }

        var decimals = value >= 100 || unitIndex === 0 ? 0 : value >= 10 ? 1 : 2
        return value.toFixed(decimals) + " " + units[unitIndex]
    }

    function showPreviewData(data) {
        if (!root.previewEnabled || !data) {
            root.previewData = root.emptyPreviewData()
            return
        }

        root.previewData = {
            visible: data.visible === undefined ? true : !!data.visible,
            name: data.name || "",
            type: data.type || "",
            icon: data.icon || "insert-drive-file",
            previewType: data.previewType || "none",
            size: data.size || "",
            dateModified: data.dateModified || "",
            summary: data.summary || "",
            lines: root.toJsArray(data.lines)
        }
    }

    function togglePreviewEnabled() {
        applySnapshot(backend.setPreviewEnabled(!root.previewEnabled))
    }

    function openSidebarContextInNewTab() {
        if (root.contextSidebarLabel === "")
            return

        applySnapshot(
            backend.openSidebarLocationInNewTab(
                root.contextSidebarLabel,
                root.contextSidebarIcon,
                root.contextSidebarKind || ""
            )
        )

        Qt.callLater(function() {
            root.ensureTabVisible(root.currentTab)
        })
    }

    function addTab(titleText) {
        applySnapshot(backend.addTab(titleText))
        Qt.callLater(function() {
            ensureTabVisible(currentTab)
        })
    }

    function activateTabLocal(index) {
        if (index < 0 || index >= tabsModel.count)
            return

        currentTab = index

        if (backend && backend.activateTab)
            applySnapshot(backend.activateTab(index))
    }

    function emptyPreviewData() {
        return {
            visible: false,
            name: "",
            type: "",
            icon: "insert-drive-file",
            previewType: "none",
            size: "",
            dateModified: "",
            summary: "",
            lines: []
        }
    }

    function multiSelectionPreviewData(rows) {
        if (!rows || rows.length === 0)
            return root.emptyPreviewData()

        var totalCount = rows.length
        var folderCount = 0
        var fileCount = 0
        var knownSizeBytes = 0
        var knownSizeCount = 0
        var latestModified = 0
        var typeCounts = {}
        var extensions = {}

        for (var i = 0; i < rows.length; ++i) {
            var row = rows[i]
            var item = filesModel.rows[row]
            if (!item)
                continue

            var typeText = item.type || ""
            var nameText = item.name || ""

            if (typeText === "File folder")
                ++folderCount
            else
                ++fileCount

            if (typeText !== "") {
                if (!typeCounts[typeText])
                    typeCounts[typeText] = 0
                ++typeCounts[typeText]
            }

            var sizeBytes = parseSizeToBytes(item.size)
            if (sizeBytes >= 0) {
                knownSizeBytes += sizeBytes
                ++knownSizeCount
            }

            var dt = parseDateTimeValue(item.dateModified)
            if (dt > latestModified)
                latestModified = dt

            var dot = nameText.lastIndexOf(".")
            if (dot > 0 && dot < nameText.length - 1) {
                var ext = nameText.slice(dot + 1).toLowerCase()
                if (!extensions[ext])
                    extensions[ext] = 0
                ++extensions[ext]
            }
        }

        var dominantType = ""
        var dominantTypeCount = 0
        for (var t in typeCounts) {
            if (typeCounts[t] > dominantTypeCount) {
                dominantType = t
                dominantTypeCount = typeCounts[t]
            }
        }

        var extensionList = []
        for (var extKey in extensions)
            extensionList.push(extKey)
        extensionList.sort()

        var lines = []
        lines.push(totalCount + " selected")
        lines.push(folderCount + " folder" + (folderCount === 1 ? "" : "s"))
        lines.push(fileCount + " file" + (fileCount === 1 ? "" : "s"))

        if (knownSizeCount > 0)
            lines.push("Combined file size: " + formatBytes(knownSizeBytes))

        if (extensionList.length > 0)
            lines.push("Extensions: " + extensionList.slice(0, 6).join(", ") + (extensionList.length > 6 ? " ..." : ""))

        return {
            visible: true,
            name: totalCount + " items selected",
            type: folderCount > 0 && fileCount > 0
                  ? "Multiple item types"
                  : folderCount > 0
                    ? "Folders"
                    : (dominantType !== "" && dominantTypeCount === totalCount ? dominantType : "Files"),
            icon: totalCount > 1 ? "content-copy" : "insert-drive-file",
            previewType: "multi",
            size: knownSizeCount > 0 ? formatBytes(knownSizeBytes) : "—",
            dateModified: latestModified > 0 ? new Date(latestModified).toLocaleString(Qt.locale(), "dd/MM/yyyy HH:mm") : "—",
            summary: folderCount > 0 && fileCount > 0
                     ? "Selection contains both files and folders."
                     : folderCount === totalCount
                       ? "Selection contains folders only."
                       : "Selection contains multiple files.",
            lines: lines
        }
    }

    function refreshPreviewSelection() {
        if (!root.previewEnabled) {
            root.showPreviewData(null)
            return
        }

        var rows = root.selectedFileRowsArray()

        if (rows.length > 1) {
            root.showPreviewData(root.multiSelectionPreviewData(rows))
            return
        }

        if (rows.length === 1) {
            root.currentFileRow = rows[0]
            applySnapshot(backend.previewItemByRow(rows[0]))
            return
        }

        if (root.currentFileRow >= 0 && root.currentFileRow < filesModel.rows.length)
            applySnapshot(backend.previewItemByRow(root.currentFileRow))
        else if (backend && backend.clearPreview)
            applySnapshot(backend.clearPreview())
        else
            root.showPreviewData(null)
    }

    function finishPathEditing(acceptTypedPath) {
        if (!editingPath)
            return

        if (acceptTypedPath) {
            editingPath = false
            applySnapshot(backend.navigateToPathString(pathField.text))
        } else {
            editingPath = false
            syncPathField()
        }
    }

    function updateTabsPreservingOrder(newTabs) {
        var incoming = toJsArray(newTabs)
        if (incoming.length === 0) {
            tabsModel.clear()
            return
        }

        var current = []
        for (var i = 0; i < tabsModel.count; ++i)
            current.push(tabsModel.get(i))

        function tabKey(tab) {
            return (tab.title || "") + "|" + (tab.icon || "")
        }

        function bucketTake(buckets, key) {
            var arr = buckets[key]
            if (!arr || arr.length === 0)
                return null
            return arr.shift()
        }

        var incomingBuckets = {}
        for (var j = 0; j < incoming.length; ++j) {
            var k = tabKey(incoming[j])
            if (!incomingBuckets[k])
                incomingBuckets[k] = []
            incomingBuckets[k].push(incoming[j])
        }

        var merged = []

        for (var a = 0; a < current.length; ++a) {
            var ck = tabKey(current[a])
            var match = bucketTake(incomingBuckets, ck)
            if (match)
                merged.push(match)
        }

        for (var b = 0; b < incoming.length; ++b) {
            var ik = tabKey(incoming[b])
            var bucket = incomingBuckets[ik]
            if (bucket && bucket.length > 0)
                merged.push(bucket.shift())
        }

        replaceListModel(tabsModel, merged)
    }

    function applySnapshot(snapshot, options) {
        if (!snapshot)
            return

        var preserveTabsOrder = options && options.preserveTabsOrder === true

        if (snapshot.tabs !== undefined) {
            if (preserveTabsOrder)
                updateTabsPreservingOrder(snapshot.tabs)
            else
                replaceListModel(tabsModel, toJsArray(snapshot.tabs))
        }

        if (snapshot.beginRenameRow !== undefined) {
            Qt.callLater(function() {
                beginRenameRow(snapshot.beginRenameRow)
            })
        }

        if (snapshot.path !== undefined)
            replaceListModel(pathModel, toJsArray(snapshot.path))

        if (snapshot.drives !== undefined)
            replaceListModel(drivesModel, toJsArray(snapshot.drives))

        //if (snapshot.sidebar !== undefined)
        //    sidebarModel.rows = toJsArray(snapshot.sidebar)

        if (snapshot.files !== undefined)
            filesModel.rows = toJsArray(snapshot.files)

        if (snapshot.currentTab !== undefined)
            currentTab = snapshot.currentTab

        if (snapshot.pathText !== undefined && pathField)
            pathField.text = snapshot.pathText

        if (snapshot.previewEnabled !== undefined) {
            var nextPreviewEnabled = !!snapshot.previewEnabled

            if (root.previewEnabled && !nextPreviewEnabled
                    && root.previewPaneWidth >= root.previewPaneMinWidth) {
                root.previewPaneLastExpandedWidth = root.previewPaneWidth
            }

            root.previewEnabled = nextPreviewEnabled

            if (root.previewEnabled) {
                root.previewPaneWidth = Math.max(
                    root.previewPaneMinWidth,
                    root.previewPaneLastExpandedWidth
                )
            }
        }

        if (snapshot.showHiddenFiles !== undefined)
            root.showHiddenFiles = !!snapshot.showHiddenFiles

        if (snapshot.preview !== undefined)
            root.showPreviewData(snapshot.preview)
        else if (!root.previewEnabled)
            root.showPreviewData(null)

        if (snapshot.message)
            addToastNotification(snapshot.message, snapshot.messageKind || "info")
    }

    function toJsArray(value) {
        if (value === undefined || value === null)
            return []

        if (Array.isArray(value))
            return value

        var out = []
        var len = value.length !== undefined ? value.length : 0
        for (var i = 0; i < len; ++i)
            out.push(value[i])
        return out
    }

    function selectedItemsForBackend() {
        var rows = selectedFileRowsArray()
        var out = []
        for (var i = 0; i < rows.length; ++i) {
            var row = rows[i]
            out.push({
                row: row,
                name: fileRowValue(row, "name"),
                type: fileRowValue(row, "type"),
                icon: fileRowValue(row, "icon")
            })
        }
        return out
    }

    function singleItemForBackend(row) {
        if (row < 0)
            return []

        return [{
            row: row,
            name: fileRowValue(row, "name"),
            type: fileRowValue(row, "type"),
            icon: fileRowValue(row, "icon")
        }]
    }

    function beginSystemMove() {
        windowMoveActive = true
        moveSettleTimer.restart()
        startSystemMove()
    }

    onXChanged: {
        if (windowMoveActive)
            moveSettleTimer.restart()
    }

    onYChanged: {
        if (windowMoveActive)
            moveSettleTimer.restart()
    }

    Timer {
        id: moveSettleTimer
        interval: 120
        repeat: false
        onTriggered: root.windowMoveActive = false
    }

    Timer {
        id: tooltipTimer
        interval: root.tooltipDelay
        repeat: false
        onTriggered: {
            if (hoverArea.containsMouse && root.enabled && root.tooltipText !== "")
                buttonTooltip.shown = true
        }
    }

    BaseTooltip {
        id: buttonTooltip
        text: root.tooltipText
        darkTheme: root.darkTheme
        shown: false
    }

    function currentDateTimeString() {
        var d = new Date()
        function pad(n) { return n < 10 ? "0" + n : "" + n }

        return pad(d.getDate()) + "/"
             + pad(d.getMonth() + 1) + "/"
             + d.getFullYear() + " "
             + pad(d.getHours()) + ":"
             + pad(d.getMinutes())
    }

    function uniqueName(baseName, extension) {
        var ext = extension || ""
        var candidate = baseName + ext
        var suffix = 2

        function exists(name) {
            for (var i = 0; i < filesModel.rows.length; ++i) {
                if ((filesModel.rows[i].name || "").toLowerCase() === name.toLowerCase())
                    return true
            }
            return false
        }

        while (exists(candidate)) {
            candidate = baseName + " (" + suffix + ")" + ext
            ++suffix
        }

        return candidate
    }

    function beginRenameRow(row) {
        if (row < 0 || row >= filesModel.rows.length)
            return

        editingFileRow = row
        editingFileNameDraft = fileRowValue(row, "name")
        currentFileRow = row
        selectOnlyFileRow(row)
    }

    function commitRenameRow(row, newName) {
        if (row < 0 || row >= filesModel.rows.length) {
            editingFileRow = -1
            editingFileNameDraft = ""
            return
        }

        var trimmed = (newName || "").trim()
        if (trimmed === "") {
            editingFileRow = -1
            editingFileNameDraft = ""
            return
        }

        applySnapshot(backend.renameItems(singleItemForBackend(row), trimmed))
        editingFileRow = -1
        editingFileNameDraft = ""
    }

    function cancelRenameRow() {
        editingFileRow = -1
        editingFileNameDraft = ""
    }

    function beginRenameTab(index) {
        if (index < 0 || index >= tabsModel.count)
            return

        editingTabIndex = index
        editingTabTitleDraft = tabsModel.get(index).title || ""
        currentTab = index
    }

    function filterInvalidNameCharacters(value) {
        var s = value || ""

        if (backend && backend.currentPlatform) {
            var platform = backend.currentPlatform()

            s = s.replace(/\u0000/g, "")

            if (platform === "windows") {
                s = s.replace(/[\\\/:*?"<>|]/g, "")
            } else if (platform === "macos" || platform === "linux") {
                s = s.replace(/\//g, "")
            } else {
                s = s.replace(/[\\\/:*?"<>|]/g, "")
            }
        }

        return s
    }

    function commitRenameTab(index, newTitle) {
        if (index < 0 || index >= tabsModel.count) {
            editingTabIndex = -1
            editingTabTitleDraft = ""
            return
        }

        var trimmed = (newTitle || "").trim()
        if (trimmed === "") {
            editingTabIndex = -1
            editingTabTitleDraft = ""
            return
        }

        renameTab(index, trimmed)
        editingTabIndex = -1
        editingTabTitleDraft = ""
    }

    function cancelRenameTab() {
        editingTabIndex = -1
        editingTabTitleDraft = ""
    }

    function addNewFolder() {
        applySnapshot(backend.createFolder())
        Qt.callLater(function() {
            beginRenameRow(0)
        })
    }

    function addNewFile() {
        applySnapshot(backend.createFile())
        Qt.callLater(function() {
            beginRenameRow(0)
        })
    }

    function setNavDropHover(label, kind) {
        navDropHoverLabel = label
        navDropHoverKind = kind || ""
    }

    function cloneSelectedFileRows() {
        var out = {}
        for (var k in selectedFileRows)
            out[k] = true
        return out
    }

    function isFileRowSelected(row) {
        return !!selectedFileRows[row]
    }

    function selectedFileCount() {
        var count = 0
        for (var k in selectedFileRows)
            ++count
        return count
    }

    function selectedFileRowsArray() {
        var rows = []
        for (var k in selectedFileRows)
            rows.push(parseInt(k, 10))
        rows.sort(function(a, b) { return a - b })
        return rows
    }

    function askDeleteSelection() {
        var count = selectedFileCount()
        if (count <= 0)
            return

        confirmDialogTitle = count === 1 ? "Delete item" : "Delete items"
        confirmDialogMessage = count === 1
                ? ("Are you sure you want to delete \"" + fileRowValue(currentFileRow, "name") + "\"?")
                : ("Are you sure you want to delete " + count + " selected items?")
        confirmDialogAction = "deleteSelection"
        confirmDialogRow = -1
        confirmDialog.open()
    }

    function isDraggedRow(row) {
        return !!draggedFileRows[row]
    }

    function clearFileSelection() {
        selectedFileRows = ({})
        currentFileRow = -1
    }

    function selectOnlyFileRow(row) {
        var next = {}
        if (row >= 0)
            next[row] = true

        selectedFileRows = next
        currentFileRow = row
        selectionAnchorRow = row
    }

    function addFileRowToSelection(row) {
        var next = cloneSelectedFileRows()
        next[row] = true
        selectedFileRows = next
        currentFileRow = row

        if (selectionAnchorRow < 0)
            selectionAnchorRow = row
    }

    function removeFileRowFromSelection(row) {
        var next = cloneSelectedFileRows()
        delete next[row]
        selectedFileRows = next

        if (currentFileRow === row)
            currentFileRow = -1
    }

    function showTabContextMenu(index) {
        contextTabIndex = index
        tabContextMenu.popup()
    }

    function toggleFileRowSelection(row) {
        if (isFileRowSelected(row))
            removeFileRowFromSelection(row)
        else
            addFileRowToSelection(row)
    }

    function selectFileRange(anchorRow, row, replaceSelection) {
        if (anchorRow < 0)
            anchorRow = row

        var start = Math.min(anchorRow, row)
        var end = Math.max(anchorRow, row)

        var next = replaceSelection ? {} : cloneSelectedFileRows()

        for (var i = start; i <= end; ++i)
            next[i] = true

        selectedFileRows = next
        currentFileRow = row

        if (selectionAnchorRow < 0)
            selectionAnchorRow = anchorRow
    }

    function selectAllFiles() {
        var next = {}
        for (var i = 0; i < filesModel.rows.length; ++i)
            next[i] = true

        selectedFileRows = next

        if (filesModel.rows.length > 0) {
            currentFileRow = 0
            if (selectionAnchorRow < 0)
                selectionAnchorRow = 0
        }
    }

    function updateDetailsBandSelection(tableView) {
        if (!tableView)
            return

        var left = Math.min(detailsSelectionStartX, detailsSelectionCurrentX) + tableView.contentX
        var right = Math.max(detailsSelectionStartX, detailsSelectionCurrentX) + tableView.contentX
        var top = Math.min(detailsSelectionStartY, detailsSelectionCurrentY) + tableView.contentY
        var bottom = Math.max(detailsSelectionStartY, detailsSelectionCurrentY) + tableView.contentY

        var next = {}

        if (!(right < 0 || left > tableView.contentWidth)) {
            var step = detailsRowHeight + tableView.rowSpacing

            for (var row = 0; row < filesModel.rows.length; ++row) {
                var rowTop = row * step
                var rowBottom = rowTop + detailsRowHeight

                if (bottom >= rowTop && top <= rowBottom)
                    next[row] = true
            }
        }

        selectedFileRows = next

        var first = -1
        for (var k in next) {
            first = parseInt(k, 10)
            break
        }
        currentFileRow = first
    }

    function clearNavDropHover(label, kind) {
        var k = kind || ""
        if (navDropHoverLabel === label && navDropHoverKind === k) {
            navDropHoverLabel = ""
            navDropHoverKind = ""
        }
    }

    function beginFileDrag(row) {
        if (row < 0)
            return

        var dragRows = {}
        var rows = []

        if (isFileRowSelected(row) && selectedFileCount() > 1) {
            rows = selectedFileRowsArray()
            for (var i = 0; i < rows.length; ++i)
                dragRows[rows[i]] = true
        } else {
            dragRows[row] = true
            rows = [row]
        }

        draggedFileRows = dragRows
        draggedFileCount = rows.length
        draggedFileRow = rows.length > 0 ? rows[0] : -1
        draggedFileName = rows.length > 1 ? (rows.length + " items") : fileRowValue(row, "name")
        draggedFileType = rows.length > 1 ? "Multiple items" : fileRowValue(row, "type")
        draggedFileIcon = fileRowValue(row, "icon")
        dragPreviewReady = false

        fileDragPreview.grabToImage(function(result) {
            draggedFilePreviewUrl = result.url
            dragPreviewReady = true
        })
    }

    function clearFileDrag() {
        draggedFileRow = -1
        draggedFileRows = ({})
        draggedFileCount = 0
        draggedFileName = ""
        draggedFileType = ""
        draggedFileIcon = ""
        draggedFilePreviewUrl = ""
        dragPreviewReady = false
        navDropHoverLabel = ""
        navDropHoverKind = ""
        breadcrumbDropHoverIndex = -1
    }

    function sortFilesExplicit(column, ascending) {
        sortColumn = column
        sortAscending = ascending

        var arr = filesModel.rows.slice(0)

        arr.sort(function(a, b) {
            var av, bv

            if (column === 0) {
                av = (a.name || "").toLowerCase()
                bv = (b.name || "").toLowerCase()
            } else if (column === 1) {
                av = parseDateTimeValue(a.dateModified)
                bv = parseDateTimeValue(b.dateModified)
            } else if (column === 2) {
                av = (a.type || "").toLowerCase()
                bv = (b.type || "").toLowerCase()
            } else {
                av = parseSizeToBytes(a.size)
                bv = parseSizeToBytes(b.size)
            }

            if (av < bv) return ascending ? -1 : 1
            if (av > bv) return ascending ? 1 : -1
            return 0
        })

        filesModel.rows = arr
        clearFileSelection()
        selectionAnchorRow = -1
    }

    function handleDroppedItem(targetLabel, targetKind) {
        if (draggedFileCount <= 0)
            return

        applySnapshot(backend.moveItems(selectedItemsForBackend(), targetLabel, targetKind))
        clearFileDrag()
    }

    function scrollTabsBy(delta) {
        if (!tabFlick)
            return
        var maxX = Math.max(0, tabFlick.contentWidth - tabFlick.width)
        tabFlick.contentX = Math.max(0, Math.min(maxX, tabFlick.contentX + delta))
    }

    function ensureTabVisible(index) {
        if (!tabFlick || index < 0 || index >= tabsModel.count)
            return

        var left = index * (tabWidth + tabSpacing)
        var right = left + tabWidth
        var viewLeft = tabFlick.contentX
        var viewRight = tabFlick.contentX + tabFlick.width

        if (left < viewLeft)
            tabFlick.contentX = left
        else if (right > viewRight)
            tabFlick.contentX = right - tabFlick.width
    }

    function addToastNotification(message, kind) {
        var id = nextNotificationId++
        notificationsModel.append({
            notificationId: id,
            title: message,
            kind: kind || "info",
            progress: -1,
            autoClose: true,
            done: true
        })

        var item = toastRepeater.itemAt(notificationsModel.count - 1)
        if (item)
            item.restartTimer()

        return id
    }

    function askDeleteRow(row) {
        confirmDialogTitle = "Delete item"
        confirmDialogMessage = "Are you sure you want to delete \"" + fileRowValue(row, "name") + "\"?"
        confirmDialogAction = "deleteRow"
        confirmDialogRow = row
        confirmDialog.open()
    }

    function addProgressNotification(title, initialProgress) {
        var id = nextNotificationId++
        notificationsModel.append({
            notificationId: id,
            title: title,
            kind: "progress",
            progress: initialProgress === undefined ? 0 : initialProgress,
            autoClose: false,
            done: false
        })
        return id
    }

    function updateNotificationProgress(notificationId, value, doneTitle) {
        for (var i = 0; i < notificationsModel.count; ++i) {
            var n = notificationsModel.get(i)
            if (n.notificationId === notificationId) {
                notificationsModel.setProperty(i, "progress", value)
                if (value >= 100) {
                    notificationsModel.setProperty(i, "done", true)
                    notificationsModel.setProperty(i, "kind", "success")
                    notificationsModel.setProperty(i, "autoClose", true)
                    if (doneTitle)
                        notificationsModel.setProperty(i, "title", doneTitle)

                    var item = toastRepeater.itemAt(i)
                    if (item)
                        item.restartTimer()
                }
                return
            }
        }
    }

    function removeNotification(notificationId) {
        for (var i = 0; i < notificationsModel.count; ++i) {
            if (notificationsModel.get(i).notificationId === notificationId) {
                notificationsModel.remove(i)
                return
            }
        }
    }

    function parseSizeToBytes(s) {
        if (!s || s === "")
            return -1

        var m = String(s).trim().match(/^([\d.]+)\s*(B|KB|MB|GB|TB)$/i)
        if (!m)
            return -1

        var n = parseFloat(m[1])
        var unit = m[2].toUpperCase()

        if (unit === "B") return n
        if (unit === "KB") return n * 1024
        if (unit === "MB") return n * 1024 * 1024
        if (unit === "GB") return n * 1024 * 1024 * 1024
        if (unit === "TB") return n * 1024 * 1024 * 1024 * 1024

        return -1
    }

    function parseDateTimeValue(s) {
        if (!s || s === "")
            return 0

        var m = String(s).match(/^(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}):(\d{2})$/)
        if (!m)
            return 0

        var day = parseInt(m[1], 10)
        var month = parseInt(m[2], 10) - 1
        var year = parseInt(m[3], 10)
        var hour = parseInt(m[4], 10)
        var minute = parseInt(m[5], 10)

        return new Date(year, month, day, hour, minute).getTime()
    }

    function sortFiles(column) {
        if (sortColumn === column)
            sortAscending = !sortAscending
        else {
            sortColumn = column
            sortAscending = true
        }

        var arr = filesModel.rows.slice(0)

        arr.sort(function(a, b) {
            var av, bv

            if (column === 0) {
                av = (a.name || "").toLowerCase()
                bv = (b.name || "").toLowerCase()
            } else if (column === 1) {
                av = parseDateTimeValue(a.dateModified)
                bv = parseDateTimeValue(b.dateModified)
            } else if (column === 2) {
                av = (a.type || "").toLowerCase()
                bv = (b.type || "").toLowerCase()
            } else {
                av = parseSizeToBytes(a.size)
                bv = parseSizeToBytes(b.size)
            }

            if (av < bv) return sortAscending ? -1 : 1
            if (av > bv) return sortAscending ? 1 : -1
            return 0
        })

        filesModel.rows = arr
        clearFileSelection()
        selectionAnchorRow = -1
    }

    function toggleMaximize() {
        if (root.visibility === Window.Maximized)
            root.showNormal()
        else
            root.showMaximized()
    }

    function navigateToPath(parts) {
        applySnapshot(backend.navigateToPathParts(parts))
        editingPath = false
    }

    function setPathFromIndex(index) {
        if (index < 0 || index >= pathModel.count)
            return

        var parts = []
        for (var i = 0; i <= index; ++i)
            parts.push({
                label: pathModel.get(i).label,
                icon: pathModel.get(i).icon
            })

        navigateToPath(parts)
    }

    function syncPathField() {
        var parts = []
        for (var i = 0; i < pathModel.count; ++i)
            parts.push(pathModel.get(i).label)

        if (parts.length === 0) {
            pathField.text = ""
            return
        }

        var first = parts[0]

        if (/^[A-Z]:$/.test(first))
            pathField.text = first + "/" + parts.slice(1).join("/")
        else
            pathField.text = parts.join("/")
    }

    function closeTab(index) {
        applySnapshot(backend.closeTab(index))
    }

    function renameTab(index, newTitle) {
        applySnapshot(backend.renameTab(index, newTitle))
    }

    function selectedOrCurrentItemsForBackend() {
        if (root.selectedFileCount() > 0)
            return root.selectedItemsForBackend()

        if (root.currentFileRow >= 0)
            return root.singleItemForBackend(root.currentFileRow)

        return []
    }

    function hasSelectedOrCurrentItems() {
        return root.selectedOrCurrentItemsForBackend().length > 0
    }

    function cutSelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.cutItems(items))
    }

    function copySelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.copyItems(items))
    }

    function duplicateSelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.duplicateItems(items))
    }

    function compressSelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.compressItems(items))
    }

    function extractSelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.extractItems(items))
    }

    function openSelectedOrCurrentWith(appName) {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.openItemsWith(items, appName))
    }

    function chooseOpenWithForSelectedOrCurrent() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.chooseOpenWithApp(items))
    }

    function openSelectedOrCurrentInTerminal() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.openItemsInTerminal(items))
    }

    function showPropertiesForSelectedOrCurrentOrLocation() {
        var items = root.selectedOrCurrentItemsForBackend()
        if (items.length > 0)
            applySnapshot(backend.showItemProperties(items))
        else
            applySnapshot(backend.showCurrentLocationProperties())
    }

    function moveTab(from, to) {
        if (from === to || from < 0 || to < 0 || from >= tabsModel.count || to >= tabsModel.count)
            return

        tabsModel.move(from, to, 1)

        if (currentTab === from)
            currentTab = to
        else if (currentTab > from && currentTab <= to)
            currentTab -= 1
        else if (currentTab < from && currentTab >= to)
            currentTab += 1
    }

    function invalidCharactersForCurrentPlatform() {
        if (!backend || !backend.currentPlatform)
            return "\\/:*?\"<>|"

        var platform = backend.currentPlatform()
        if (platform === "windows")
            return "\\/:*?\"<>|"
        if (platform === "macos" || platform === "linux")
            return "/"

        return "\\/:*?\"<>|"
    }

    function validateNameDraft(value) {
        var s = value || ""
        var trimmed = s.trim()

        if (trimmed.length === 0) {
            return {
                ok: false,
                message: "Name cannot be empty"
            }
        }

        if (trimmed === "." || trimmed === "..") {
            return {
                ok: false,
                message: "This name is not valid."
            }
        }

        if (s.indexOf("\u0000") >= 0) {
            return {
                ok: false,
                message: "Name contains invalid characters."
            }
        }

        var platform = backend && backend.currentPlatform ? backend.currentPlatform() : "windows"

        if (platform === "windows") {
            if (/[\\\/:*?"<>|]/.test(s)) {
                return {
                    ok: false,
                    message: "A file name can't contain any of the following characters: \\ / : * ? \" < > |"
                }
            }

            if (/[. ]$/.test(s)) {
                return {
                    ok: false,
                    message: "A file name can't end with a space or a dot."
                }
            }

            var upperBase = trimmed.toUpperCase().split(".")[0]
            var reserved = {
                "CON": true, "PRN": true, "AUX": true, "NUL": true,
                "COM1": true, "COM2": true, "COM3": true, "COM4": true, "COM5": true,
                "COM6": true, "COM7": true, "COM8": true, "COM9": true,
                "LPT1": true, "LPT2": true, "LPT3": true, "LPT4": true, "LPT5": true,
                "LPT6": true, "LPT7": true, "LPT8": true, "LPT9": true
            }

            if (reserved[upperBase]) {
                return {
                    ok: false,
                    message: "This name is reserved by Windows."
                }
            }
        } else {
            if (/\//.test(s)) {
                return {
                    ok: false,
                    message: "A file name can't contain /"
                }
            }
        }

        if (trimmed.length > 255) {
            return {
                ok: false,
                message: "Name is too long."
            }
        }

        return {
            ok: true,
            message: ""
        }
    }

    function moveTabLocally(from, to) {
        if (from === to || from < 0 || to < 0 || from >= tabsModel.count || to >= tabsModel.count)
            return

        tabsModel.move(from, to, 1)

        if (currentTab === from)
            currentTab = to
        else if (from < currentTab && to >= currentTab)
            currentTab -= 1
        else if (from > currentTab && to <= currentTab)
            currentTab += 1
    }

    function openLocation(label, iconText, kind) {
        selectedSidebarLabel = label
        selectedSidebarKind = kind || ""
        applySnapshot(backend.openSidebarLocation(label, iconText, kind || ""))
        editingPath = false
    }

    function enterFolder(folderName) {
        for (var i = 0; i < filesModel.rows.length; ++i) {
            if (fileRowValue(i, "name") === folderName && fileRowValue(i, "type") === "File folder") {
                applySnapshot(backend.openItems(root.singleItemForBackend(i)))
                return
            }
        }
    }

    function fileRowValue(row, key) {
        var r = filesModel.rows[row]
        return r && r[key] !== undefined ? r[key] : ""
    }

    function viewModeIcon(mode) {
        if (mode === "Details")
            return "detailed-view"
        if (mode === "Tiles")
            return "tile-view"
        if (mode === "Compact")
            return "list-view"
        if (mode === "Large icons")
            return "grid-view"
        return "list-view"
    }

    ListModel {
        id: tabsModel
        ListElement { title: "Home"; icon: "home" }
        ListElement { title: "Local Disk (C:)"; icon: "hard-drive" }
    }

    ListModel {
        id: pathModel
        ListElement { label: "C:"; icon: "hard-drive" }
        ListElement { label: "Projects"; icon: "folder" }
        ListElement { label: "Qt"; icon: "folder" }
    }

    Labs.TreeModel {
        id: sidebarModel

        Labs.TableModelColumn { display: "label" }
        Labs.TableModelColumn { display: "icon" }
        Labs.TableModelColumn { display: "section" }
        Labs.TableModelColumn { display: "kind" }

        rows: [
            {
                label: "Quick Access",
                icon: "",
                section: true,
                kind: "section",
                rows: [
                    { label: "Recent", icon: "history", kind: "quick", section: false },
                    { label: "Home", icon: "home", kind: "quick", section: false },
                    { label: "Desktop", icon: "desktop-windows", kind: "quick", section: false },
                    { label: "Downloads", icon: "download", kind: "quick", section: false },
                    { label: "Documents", icon: "description", kind: "quick", section: false },
                    { label: "Pictures", icon: "image", kind: "quick", section: false },
                    { label: "Music", icon: "music-note", kind: "quick", section: false },
                    { label: "Videos", icon: "movie", kind: "quick", section: false }
                ]
            }
        ]
    }

    ListModel {
        id: drivesModel

        ListElement {
            label: "Local Disk (C:)"
            icon: "hard-drive"
            used: 0.5
            total: 1.0
            usedText: "0.5 TB used of 1 TB"
        }

        ListElement {
            label: "Data (D:)"
            icon: "storage"
            used: 0.37
            total: 1.0
            usedText: "0.37 TB used of 1 TB"
        }

        ListElement {
            label: "Backup (E:)"
            icon: "save"
            used: 0.91
            total: 1.0
            usedText: "0.91 TB used of 1 TB"
        }

        ListElement {
            label: "USB Drive (F:)"
            icon: "usb"
            used: 0.18
            total: 1.0
            usedText: "0.18 TB used of 1 TB"
        }
    }

    Labs.TableModel {
        id: filesModel

        Labs.TableModelColumn { display: "name" }
        Labs.TableModelColumn { display: "dateModified" }
        Labs.TableModelColumn { display: "type" }
        Labs.TableModelColumn { display: "size" }
        Labs.TableModelColumn { display: "icon" }

        rows: [
            { "name": "Backup", "dateModified": "13/02/2026 12:01", "type": "File folder", "size": "", "icon": "folder" },
            { "name": "Games", "dateModified": "06/03/2026 21:58", "type": "File folder", "size": "", "icon": "folder" },
            { "name": "inetpub", "dateModified": "07/02/2026 22:34", "type": "File folder", "size": "", "icon": "folder" },
            { "name": "Program Files", "dateModified": "06/03/2026 22:07", "type": "File folder", "size": "", "icon": "folder" },
            { "name": "appverifUI.dll", "dateModified": "12/11/2025 15:27", "type": "Application extension", "size": "110 KB", "icon": "insert-drive-file" },
            { "name": "chrome.exe", "dateModified": "03/03/2026 09:14", "type": "Application", "size": "248 MB", "icon": "insert-drive-file" },
            { "name": "readme.txt", "dateModified": "28/02/2026 18:42", "type": "Text Document", "size": "4 KB", "icon": "description" },
            { "name": "meeting-notes.docx", "dateModified": "10/03/2026 11:05", "type": "Microsoft Word Document", "size": "86 KB", "icon": "description" },
            { "name": "budget-2026.xlsx", "dateModified": "14/03/2026 08:51", "type": "Microsoft Excel Worksheet", "size": "214 KB", "icon": "description" },
            { "name": "presentation-q1.pptx", "dateModified": "07/03/2026 16:23", "type": "Microsoft PowerPoint Presentation", "size": "3.8 MB", "icon": "description" },
            { "name": "invoice-1482.pdf", "dateModified": "01/03/2026 13:37", "type": "PDF Document", "size": "512 KB", "icon": "picture-as-pdf" },
            { "name": "hero-banner.png", "dateModified": "11/03/2026 20:16", "type": "PNG File", "size": "1.9 MB", "icon": "image" },
            { "name": "vacation-photo.jpg", "dateModified": "22/02/2026 17:08", "type": "JPEG Image", "size": "4.6 MB", "icon": "image" },
            { "name": "logo-final.svg", "dateModified": "09/03/2026 10:44", "type": "SVG Document", "size": "72 KB", "icon": "image" },
            { "name": "theme-song.mp3", "dateModified": "18/01/2026 21:55", "type": "MP3 File", "size": "8.7 MB", "icon": "music-note" },
            { "name": "launch-trailer.mp4", "dateModified": "13/03/2026 22:11", "type": "MP4 Video", "size": "148 MB", "icon": "movie" },
            { "name": "archive-backup.zip", "dateModified": "05/03/2026 07:30", "type": "Compressed (zipped) Folder", "size": "640 MB", "icon": "zip" },
            { "name": "logs.7z", "dateModified": "27/02/2026 23:03", "type": "7-Zip Archive", "size": "92 MB", "icon": "zip" },
            { "name": "installer.msi", "dateModified": "16/02/2026 14:29", "type": "Windows Installer Package", "size": "27 MB", "icon": "insert-drive-file" },
            { "name": "config.json", "dateModified": "12/03/2026 09:57", "type": "JSON Source File", "size": "12 KB", "icon": "code" },
            { "name": "settings.yaml", "dateModified": "11/03/2026 08:40", "type": "YAML Document", "size": "6 KB", "icon": "code" },
            { "name": "main.cpp", "dateModified": "14/03/2026 10:32", "type": "C++ Source File", "size": "34 KB", "icon": "code" },
            { "name": "mainwindow.qml", "dateModified": "14/03/2026 10:48", "type": "QML File", "size": "58 KB", "icon": "code" },
            { "name": "script.ps1", "dateModified": "06/03/2026 12:19", "type": "PowerShell Script", "size": "9 KB", "icon": "terminal" },
            { "name": "run.bat", "dateModified": "20/02/2026 19:11", "type": "Windows Batch File", "size": "2 KB", "icon": "terminal" },
            { "name": "package-lock.json", "dateModified": "14/03/2026 10:49", "type": "JSON Source File", "size": "418 KB", "icon": "code" },
            { "name": "database.db", "dateModified": "08/03/2026 15:02", "type": "Database File", "size": "19 MB", "icon": "storage" },
            { "name": "font-regular.ttf", "dateModified": "25/01/2026 13:13", "type": "TrueType Font File", "size": "164 KB", "icon": "insert-drive-file" },
            { "name": "shortcut.lnk", "dateModified": "02/03/2026 08:12", "type": "Shortcut", "size": "1 KB", "icon": "launch" },
            { "name": "DumpStack.log", "dateModified": "12/03/2026 12:21", "type": "Log File", "size": "12 KB", "icon": "description" },
            { "name": "notes.md", "dateModified": "14/03/2026 09:26", "type": "Markdown File", "size": "18 KB", "icon": "description" },
            { "name": "design.fig", "dateModified": "04/03/2026 17:46", "type": "FIG File", "size": "28 MB", "icon": "insert-drive-file" },
            { "name": "virtual-disk.vhdx", "dateModified": "21/02/2026 23:58", "type": "Virtual Hard Disk", "size": "18 GB", "icon": "storage" },
            { "name": "certificate.pem", "dateModified": "15/02/2026 06:44", "type": "PEM File", "size": "3 KB", "icon": "lock" }
        ]
    }


    StyledMenu {
        id: createMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "New folder"
            onTriggered: root.addNewFolder()
            darkTheme: Theme.AppTheme.isDark
        }

        StyledMenuItem {
            text: "New file"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.addNewFile()
        }
    }

    StyledMenu {
        id: moreActionsMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: "Compress"
            enabled: root.hasSelectedOrCurrentItems()
            onTriggered: root.compressSelectedOrCurrent()
        }

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: "Extract here"
            enabled: root.hasSelectedOrCurrentItems()
            onTriggered: root.extractSelectedOrCurrent()
        }

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: "Duplicate"
            enabled: root.hasSelectedOrCurrentItems()
            onTriggered: root.duplicateSelectedOrCurrent()
        }

        StyledMenuSeparator {}

        StyledMenu {
            title: "Open with..."
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                darkTheme: Theme.AppTheme.isDark
                text: "Notepad"
                enabled: root.hasSelectedOrCurrentItems()
                onTriggered: root.openSelectedOrCurrentWith("Notepad")
            }

            StyledMenuItem {
                darkTheme: Theme.AppTheme.isDark
                text: "Visual Studio Code"
                enabled: root.hasSelectedOrCurrentItems()
                onTriggered: root.openSelectedOrCurrentWith("Visual Studio Code")
            }

            StyledMenuItem {
                darkTheme: Theme.AppTheme.isDark
                text: "Qt Creator"
                enabled: root.hasSelectedOrCurrentItems()
                onTriggered: root.openSelectedOrCurrentWith("Qt Creator")
            }

            StyledMenuItem {
                darkTheme: Theme.AppTheme.isDark
                text: "Windows Media Player"
                enabled: root.hasSelectedOrCurrentItems()
                onTriggered: root.openSelectedOrCurrentWith("Windows Media Player")
            }

            StyledMenuSeparator {}

            StyledMenuItem {
                darkTheme: Theme.AppTheme.isDark
                text: "Choose another app..."
                enabled: root.hasSelectedOrCurrentItems()
                onTriggered: root.chooseOpenWithForSelectedOrCurrent()
            }
        }

        StyledMenu {
            title: "Copy paths"
            darkTheme: Theme.AppTheme.isDark

            StyledMenuItem {
                text: "Full path"
                enabled: root.selectedFileCount() > 0 || root.currentFileRow >= 0
                darkTheme: Theme.AppTheme.isDark
                onTriggered: root.copySelectedOrCurrentPaths(false, false)
            }

            StyledMenuItem {
                text: "Relative path"
                enabled: root.selectedFileCount() > 0 || root.currentFileRow >= 0
                darkTheme: Theme.AppTheme.isDark
                onTriggered: root.copySelectedOrCurrentPaths(true, false)
            }

            StyledMenuSeparator {}

            StyledMenuItem {
                text: "Full paths recursively"
                enabled: root.selectedFileCount() > 0 || root.currentFileRow >= 0
                darkTheme: Theme.AppTheme.isDark
                onTriggered: root.copySelectedOrCurrentPaths(false, true)
            }

            StyledMenuItem {
                text: "Relative paths recursively"
                enabled: root.selectedFileCount() > 0 || root.currentFileRow >= 0
                darkTheme: Theme.AppTheme.isDark
                onTriggered: root.copySelectedOrCurrentPaths(true, true)
            }
        }

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: "Open in terminal"
            enabled: root.hasSelectedOrCurrentItems()
            onTriggered: root.openSelectedOrCurrentInTerminal()
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Select all"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: root.selectAllFiles()
        }

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: root.showHiddenFiles ? "Hide hidden files" : "Show hidden files"
            onTriggered: applySnapshot(backend.setShowHiddenFiles(!root.showHiddenFiles))
        }

        StyledMenuItem {
            darkTheme: Theme.AppTheme.isDark
            text: "Properties"
            onTriggered: root.showPropertiesForSelectedOrCurrentOrLocation()
        }
    }

    Dialog {
        id: confirmDialog
        modal: true
        focus: true
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: 340
        padding: 0
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            radius: 14
            color: Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
            border.color: Theme.AppTheme.border
            border.width: 1
        }

        contentItem: Column {
            spacing: 0

            Rectangle {
                width: parent ? parent.width : 360
                height: 46
                radius: 14
                color: "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    text: root.confirmDialogTitle
                    color: Theme.AppTheme.text
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            Rectangle {
                width: parent ? parent.width : 360
                height: 1
                color: Theme.AppTheme.borderSoft
            }

            Item {
                width: parent ? parent.width : 360
                height: 68

                Text {
                    anchors.fill: parent
                    anchors.margins: 18
                    text: root.confirmDialogMessage
                    color: Theme.AppTheme.text
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: parent ? parent.width : 360
                height: 1
                color: Theme.AppTheme.borderSoft
            }

            Row {
                width: parent ? parent.width : 340
                height: 48
                spacing: 10

                Item { width: 18; height: 1 }

                Rectangle {
                    width: 92
                    height: 32
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: yesMouse.pressed
                           ? "#c94c4c"
                           : yesMouse.containsMouse
                             ? "#d85b5b"
                             : "#cf5a5a"

                    Text {
                        anchors.centerIn: parent
                        text: "Yes"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: yesMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.confirmDialogAction === "deleteRow" && root.confirmDialogRow >= 0) {
                                applySnapshot(backend.deleteItems(root.singleItemForBackend(root.confirmDialogRow)))
                                root.clearFileSelection()
                            } else if (root.confirmDialogAction === "deleteSelection") {
                                applySnapshot(backend.deleteItems(root.selectedItemsForBackend()))
                                root.clearFileSelection()
                            }
                            confirmDialog.close()
                        }
                    }
                }

                Rectangle {
                    width: 92
                    height: 32
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    color: noMouse.pressed
                           ? (Theme.AppTheme.isDark ? "#384355" : "#dce4ef")
                           : noMouse.containsMouse
                             ? Theme.AppTheme.hover
                             : "transparent"
                    border.color: Theme.AppTheme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "No"
                        color: Theme.AppTheme.text
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: noMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: confirmDialog.close()
                    }
                }

                Item { width: 18; height: 1 }
            }
        }
    }

    Popup {
        id: notificationsPopup
        width: 340
        height: 320
        padding: 8
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            implicitWidth: notificationsPopup.width
            implicitHeight: notificationsPopup.height
            radius: 12
            color: Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
            border.color: Theme.AppTheme.border
            border.width: 1
        }

        Column {
            anchors.fill: parent
            spacing: 8

            Text {
                text: "Notifications"
                color: Theme.AppTheme.text
                font.pixelSize: 13
                font.bold: true
                leftPadding: 4
            }

            Flickable {
                width: parent.width
                height: parent.height - 28
                contentWidth: width
                contentHeight: trayColumn.height
                clip: true

                Column {
                    id: trayColumn
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: notificationsModel

                        delegate: Rectangle {
                            required property var modelData
                            width: notificationsPopup.width - 16
                            height: modelData.progress >= 0 ? 78 : 54
                            radius: 10
                            color: Theme.AppTheme.isDark ? "#232c3a" : "#f8fafc"
                            border.color: Theme.AppTheme.borderSoft
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        width: parent.width - 30
                                        text: modelData.title
                                        color: Theme.AppTheme.text
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: trayCloseMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

                                        AppIcon {
                                            name: "close"
                                            darkTheme: Theme.AppTheme.isDark
                                            iconSize: 12
                                            iconOpacity: 0.75
                                        }

                                        MouseArea {
                                            id: trayCloseMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.removeNotification(modelData.notificationId)
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: modelData.progress >= 0
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Theme.AppTheme.driveFree

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, modelData.progress / 100))
                                        height: parent.height
                                        radius: 3
                                        color: modelData.done ? Theme.AppTheme.driveUsedBlue : Theme.AppTheme.accent
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: searchScopeMenu
        width: 56
        height: 96
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: Theme.AppTheme.isDark ? "#1b2230" : "#fcfcfd"
            border.color: Theme.AppTheme.border
            border.width: 1
        }

        Column {
            anchors.fill: parent
            spacing: 4

            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: folderMouse.pressed
                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                       : folderMouse.containsMouse
                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                         : "transparent"
                border.color: folderMouse.pressed
                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                              : "transparent"
                border.width: folderMouse.pressed ? 1 : 0

                AppIcon {
                    anchors.centerIn: parent
                    name: "folder"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 16
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.searchScope = "folder"
                        applySnapshot(backend.setSearchScope("folder"))
                        searchScopeMenu.close()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: driveMouse.pressed
                       ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                       : driveMouse.containsMouse
                         ? (Theme.AppTheme.isDark ? "#2a3444" : "#e6eefb")
                         : "transparent"
                border.color: driveMouse.pressed
                              ? (Theme.AppTheme.isDark ? "#4a5a72" : "#b7caf0")
                              : "transparent"
                border.width: driveMouse.pressed ? 1 : 0

                AppIcon {
                    anchors.centerIn: parent
                    name: "hard-drive"
                    darkTheme: Theme.AppTheme.isDark
                    iconSize: 16
                }

                MouseArea {
                    id: driveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.searchScope = "global"
                        applySnapshot(backend.setSearchScope("global"))
                        searchScopeMenu.close()
                    }
                }
            }
        }
    }


    BreadcrumbContextMenu {
        id: breadcrumbContextMenu
        rootWindow: root
    }

    EmptyAreaContextMenu {
        id: emptyAreaContextMenu
        rootWindow: root
    }

    TabContextMenu {
        id: tabContextMenu
        rootWindow: root
        tabsCount: tabsModel.count
    }

    SidebarContextMenu {
        id: sidebarContextMenu
        rootWindow: root
    }

    FileContextMenu {
        id: fileRowContextMenu
        rootWindow: root
    }

    MultiFileContextMenu {
        id: multiFileContextMenu
        rootWindow: root
    }

    StyledMenu {
        id: fileAreaContextMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "New folder"
            onTriggered: root.addNewFolder()
            darkTheme: Theme.AppTheme.isDark
        }

        StyledMenuItem {
            text: "New file"
            onTriggered: root.addNewFile()
            darkTheme: Theme.AppTheme.isDark
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Paste"
            onTriggered: applySnapshot(backend.pasteItems())
            darkTheme: Theme.AppTheme.isDark
        }

        StyledMenuSeparator {}

        StyledMenuItem {
            text: "Refresh"
            onTriggered: applySnapshot(backend.refresh())
            darkTheme: Theme.AppTheme.isDark
        }

        StyledMenuItem {
            text: "Properties"
            onTriggered: applySnapshot(backend.showCurrentLocationProperties())
            darkTheme: Theme.AppTheme.isDark
        }
    }

    StyledMenu {
        id: viewModeMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Details"
            onTriggered: {
                root.currentViewMode = "Details"
                applySnapshot(backend.setViewMode("Details"))
            }
            darkTheme: Theme.AppTheme.isDark
        }
        StyledMenuItem {
            text: "Tiles"
            onTriggered: {
                root.currentViewMode = "Tiles"
                applySnapshot(backend.setViewMode("Tiles"))
            }
            darkTheme: Theme.AppTheme.isDark
        }
        StyledMenuItem {
            text: "Compact"
            onTriggered: {
                root.currentViewMode = "Compact"
                applySnapshot(backend.setViewMode("Compact"))
            }
            darkTheme: Theme.AppTheme.isDark
        }
        StyledMenuItem {
            text: "Large icons"
            onTriggered: {
                root.currentViewMode = "Large icons"
                applySnapshot(backend.setViewMode("Large icons"))
            }
            darkTheme: Theme.AppTheme.isDark
        }
    }

    StyledMenu {
        id: themeMenu
        darkTheme: Theme.AppTheme.isDark

        StyledMenuItem {
            text: "Dark"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                root.themeMode = "Dark"
                applySnapshot(backend.setTheme("Dark"))
            }
        }
        StyledMenuItem {
            text: "Light"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                root.themeMode = "Light"
                applySnapshot(backend.setTheme("Light"))
            }
        }
        StyledMenuItem {
            text: "System"
            darkTheme: Theme.AppTheme.isDark
            onTriggered: {
                root.themeMode = "System"
                applySnapshot(backend.setTheme("System"))
            }
        }
    }

    Component {
        id: detailsViewComponent

        Item {
            id: detailsRoot
            anchors.margins: 10
            clip: true

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
                model: filesModel

                onWidthChanged: forceLayout()
                Component.onCompleted: forceLayout()

                columnWidthProvider: function(column) {
                    switch (column) {
                    case 0: return root.detailsNameWidth
                    case 1: return root.detailsDateWidth
                    case 2: return root.detailsTypeWidth
                    case 3: return Math.max(
                                root.detailsSizeWidth,
                                fileTable.width - (root.detailsNameWidth + root.detailsDateWidth + root.detailsTypeWidth)
                            )
                    case 4: return 0
                    default: return 120
                    }
                }

                rowHeightProvider: function(row) {
                    return root.detailsRowHeight
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

                    readonly property bool isFolderTarget: root.fileRowValue(row, "type") === "File folder"
                    readonly property bool sameAsDragged: root.isDraggedRow(row)

                    clip: false
                    z: column === 0 ? 50 : 1

                    color: root.detailsDropHoverRow === row && isFolderTarget && !sameAsDragged
                           ? Theme.AppTheme.selectedSoft
                           : root.isFileRowSelected(row)
                             ? Theme.AppTheme.selected
                             : cellMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 8

                        AppIcon {
                            visible: column === 0
                            name: root.fileRowValue(row, "icon")
                            darkTheme: Theme.AppTheme.isDark
                            iconSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: !(column === 0 && root.editingFileRow === row)
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (column === 0) return root.fileRowValue(row, "name")
                                if (column === 1) return root.fileRowValue(row, "dateModified")
                                if (column === 2) return root.fileRowValue(row, "type")
                                if (column === 3) return root.fileRowValue(row, "size")
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
                            visible: column === 0 && root.editingFileRow === row
                            width: parent.width - 28
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.editingFileNameDraft
                            color: Theme.AppTheme.text
                            font.pixelSize: 13
                            selectByMouse: true
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 0
                            bottomPadding: 0

                            property var validation: root.validateNameDraft(text)
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
                                    root.editingFileNameDraft = text
                            }

                            onAccepted: {
                                if (validation.ok)
                                    root.commitRenameRow(row, text)
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && visible) {
                                    if (validation.ok)
                                        root.commitRenameRow(row, text)
                                }
                            }

                            Keys.onEscapePressed: root.cancelRenameRow()
                        }

                        Rectangle {
                            visible: column === 0 && root.editingFileRow === row && renameField.showValidation
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
                                root.detailsDropHoverRow = row
                        }

                        onExited: function(drag) {
                            if (root.detailsDropHoverRow === row)
                                root.detailsDropHoverRow = -1
                        }

                        onDropped: function(drop) {
                            if (rowDelegate.isFolderTarget && !rowDelegate.sameAsDragged) {
                                drop.accepted = true
                                root.handleDroppedItem(root.fileRowValue(row, "name"), "folder")
                            }

                            if (root.detailsDropHoverRow === row)
                                root.detailsDropHoverRow = -1
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
                            if (root.editingFileRow >= 0 && root.editingFileRow !== row) {
                                root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)
                            }

                            var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                            var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                            var alreadySelected = root.isFileRowSelected(row)

                            if (mouse.button === Qt.RightButton) {
                                if (!alreadySelected)
                                    root.selectOnlyFileRow(row)

                                root.contextFileRow = row

                                if (root.selectedFileCount() > 1)
                                    multiFileContextMenu.popup()
                                else
                                    fileRowContextMenu.popup()

                                return
                            }

                            if (mouse.button === Qt.LeftButton) {
                                if (shift) {
                                    var anchor = root.selectionAnchorRow >= 0 ? root.selectionAnchorRow : row
                                    root.selectFileRange(anchor, row, true)
                                } else if (ctrl) {
                                    root.toggleFileRowSelection(row)
                                } else {
                                    if (!alreadySelected)
                                        root.selectOnlyFileRow(row)
                                }

                                if (column === 0) {
                                    if (!alreadySelected && !ctrl && !shift)
                                        root.beginFileDrag(row)
                                    else if (alreadySelected && !ctrl && !shift)
                                        root.beginFileDrag(row)
                                    else if (root.isFileRowSelected(row))
                                        root.beginFileDrag(row)
                                }
                            }
                        }

                        onDoubleClicked: {
                            applySnapshot(backend.openItems(root.singleItemForBackend(row)))
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
                            Drag.imageSource: root.dragPreviewReady ? root.draggedFilePreviewUrl : ""
                            Drag.mimeData: ({
                                "application/x-fileexplorer-item": JSON.stringify({
                                    row: row,
                                    rows: root.selectedFileRowsArray(),
                                    count: root.draggedFileCount,
                                    name: root.draggedFileName,
                                    type: root.draggedFileType,
                                    icon: root.draggedFileIcon
                                })
                            })

                            Drag.onDragFinished: function(dropAction) {
                                dragProxy.x = 0
                                dragProxy.y = 0
                                root.detailsDropHoverRow = -1
                                root.clearFileDrag()
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
                    var step = root.detailsRowHeight + fileTable.rowSpacing
                    if (step <= 0)
                        return -1

                    var row = Math.floor(yInContent / step)
                    if (row < 0 || row >= filesModel.rows.length)
                        return -1

                    var rowTop = row * step
                    var rowBottom = rowTop + root.detailsRowHeight
                    if (yInContent < rowTop || yInContent > rowBottom)
                        return -1

                    return row
                }

                function pointHitsRowContent(xInContent, yInContent) {
                    var row = rowAtY(yInContent)
                    if (row < 0)
                        return false

                    var firstColumnWidth = root.detailsNameWidth
                    if (xInContent < 0 || xInContent > firstColumnWidth)
                        return false

                    var leftInset = 14
                    var iconWidth = 16
                    var gapAfterIcon = 8
                    var rightPadding = 14
                    var textAvailableWidth = Math.max(0, firstColumnWidth - leftInset - iconWidth - gapAfterIcon - rightPadding)
                    var textWidth = Math.min(
                        textAvailableWidth,
                        detailsFontMetrics.advanceWidth(root.fileRowValue(row, "name"))
                    )

                    var contentLeft = leftInset
                    var contentRight = leftInset + iconWidth + gapAfterIcon + textWidth + 10

                    return xInContent >= contentLeft && xInContent <= contentRight
                }

                onPressed: function(mouse) {
                    if (root.editingFileRow >= 0) {
                        root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)
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
                        root.detailsSelectionActive = true
                        root.detailsSelectionMoved = false
                        root.detailsSelectionStartX = detailsRoot.clampX(mouse.x)
                        root.detailsSelectionStartY = detailsRoot.clampY(mouse.y)
                        root.detailsSelectionCurrentX = root.detailsSelectionStartX
                        root.detailsSelectionCurrentY = root.detailsSelectionStartY
                        root.clearFileSelection()
                        root.contextFileRow = -1
                        mouse.accepted = true
                        return
                    }

                    if (pendingEmptyContextMenu) {
                        root.clearFileSelection()
                        mouse.accepted = true
                        return
                    }

                    mouse.accepted = false
                }

                onPositionChanged: function(mouse) {
                    if (!bandSelecting || !root.detailsSelectionActive)
                        return

                    root.detailsSelectionCurrentX = detailsRoot.clampX(mouse.x)
                    root.detailsSelectionCurrentY = detailsRoot.clampY(mouse.y)

                    if (Math.abs(root.detailsSelectionCurrentX - root.detailsSelectionStartX) > 2
                            || Math.abs(root.detailsSelectionCurrentY - root.detailsSelectionStartY) > 2) {
                        root.detailsSelectionMoved = true
                    }

                    root.updateDetailsBandSelection(fileTable)
                }

                onReleased: function(mouse) {
                    if (pendingEmptyContextMenu && !root.detailsSelectionMoved) {
                        root.contextFileRow = -1
                        emptyAreaContextMenu.popup()
                    }

                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    root.detailsSelectionActive = false
                    root.detailsSelectionMoved = false
                }

                onCanceled: {
                    bandSelecting = false
                    pendingEmptyContextMenu = false
                    root.detailsSelectionActive = false
                    root.detailsSelectionMoved = false
                }
            }

            Rectangle {
                visible: root.detailsSelectionActive && root.detailsSelectionMoved
                z: 999

                x: Math.min(root.detailsSelectionStartX, root.detailsSelectionCurrentX)
                y: Math.min(root.detailsSelectionStartY, root.detailsSelectionCurrentY)
                width: Math.abs(root.detailsSelectionCurrentX - root.detailsSelectionStartX)
                height: Math.abs(root.detailsSelectionCurrentY - root.detailsSelectionStartY)

                color: Qt.rgba(76 / 255, 130 / 255, 247 / 255, 0.18)
                border.color: Theme.AppTheme.accent
                border.width: 1
            }
        }
    }

    Component {
        id: tilesViewComponent

        Item {
            id: tilesRoot

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

            function tileHitWidthForName(name) {
                return Math.min(
                    Math.max(220, tilesFontMetrics.advanceWidth(name || "") + 110),
                    360
                )
            }

            function tileHitRectForRow(row) {
                return {
                    x: 14,
                    y: row * (82 + tilesView.spacing) + 10,
                    w: tileHitWidthForName(filesModel.rows[row].name),
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

                for (var i = 0; i < filesModel.rows.length; ++i) {
                    var r = tileSelectionRectForRow(i)

                    if (right >= r.x && left <= (r.x + r.w)
                            && bottom >= r.y && top <= (r.y + r.h)) {
                        next[i] = true
                    }
                }

                root.selectedFileRows = next

                var first = -1
                for (var k in next) {
                    first = parseInt(k, 10)
                    break
                }
                root.currentFileRow = first
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
                    model: filesModel.rows
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
                        readonly property bool sameAsDragged: root.isDraggedRow(index)

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: root.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                                   ? Theme.AppTheme.selectedSoft
                                   : root.isFileRowSelected(index)
                                     ? Theme.AppTheme.selected
                                     : tileMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
                            border.color: root.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                                          ? Theme.AppTheme.accent
                                          : "transparent"
                            border.width: root.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged ? 1 : 0
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
                                    visible: root.editingFileRow !== index
                                    text: modelData.name
                                    color: Theme.AppTheme.text
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                TextField {
                                    visible: root.editingFileRow === index
                                    width: parent.width
                                    height: 26
                                    text: root.editingFileNameDraft
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
                                            root.editingFileNameDraft = text
                                    }

                                    onAccepted: root.commitRenameRow(index, root.editingFileNameDraft)

                                    onActiveFocusChanged: {
                                        if (!activeFocus && visible)
                                            root.commitRenameRow(index, root.editingFileNameDraft)
                                    }

                                    Keys.onEscapePressed: root.cancelRenameRow()
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
                                    root.detailsDropHoverRow = index
                            }

                            onExited: function(drag) {
                                if (root.detailsDropHoverRow === index)
                                    root.detailsDropHoverRow = -1
                            }

                            onDropped: function(drop) {
                                if (tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged) {
                                    drop.accepted = true
                                    root.handleDroppedItem(modelData.name, "folder")
                                }

                                if (root.detailsDropHoverRow === index)
                                    root.detailsDropHoverRow = -1
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
                                if (root.editingFileRow >= 0 && root.editingFileRow !== index)
                                    root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

                                var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                                var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                                var alreadySelected = root.isFileRowSelected(index)

                                if (mouse.button === Qt.RightButton) {
                                    if (!alreadySelected)
                                        root.selectOnlyFileRow(index)

                                    root.contextFileRow = index

                                    if (root.selectedFileCount() > 1)
                                        multiFileContextMenu.popup()
                                    else
                                        fileRowContextMenu.popup()

                                    return
                                }

                                if (mouse.button === Qt.LeftButton) {
                                    if (shift) {
                                        var anchor = root.selectionAnchorRow >= 0 ? root.selectionAnchorRow : index
                                        root.selectFileRange(anchor, index, true)
                                    } else if (ctrl) {
                                        root.toggleFileRowSelection(index)
                                    } else {
                                        if (!alreadySelected)
                                            root.selectOnlyFileRow(index)
                                    }

                                    if (!ctrl && !shift && root.isFileRowSelected(index))
                                        root.beginFileDrag(index)
                                }
                            }

                            onDoubleClicked: {
                                applySnapshot(backend.openItems(root.singleItemForBackend(index)))
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
                                Drag.imageSource: root.dragPreviewReady ? root.draggedFilePreviewUrl : ""
                                Drag.mimeData: ({
                                    "application/x-fileexplorer-item": JSON.stringify({
                                        row: index,
                                        rows: root.selectedFileRowsArray(),
                                        count: root.draggedFileCount,
                                        name: root.draggedFileName,
                                        type: root.draggedFileType,
                                        icon: root.draggedFileIcon
                                    })
                                })

                                Drag.onDragFinished: function(dropAction) {
                                    dragProxy.x = 0
                                    dragProxy.y = 0
                                    root.detailsDropHoverRow = -1
                                    root.clearFileDrag()
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

                            if (row < 0 || row >= filesModel.rows.length)
                                return false

                            var r = tilesRoot.tileHitRectForRow(row)

                            return xInView >= r.x
                                && xInView <= (r.x + r.w)
                                && yInContent >= r.y
                                && yInContent <= (r.y + r.h)
                        }

                        onPressed: function(mouse) {
                            if (root.editingFileRow >= 0)
                                root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

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
                                root.clearFileSelection()
                                root.contextFileRow = -1
                                mouse.accepted = true
                                return
                            }

                            if (pendingEmptyContextMenu) {
                                root.clearFileSelection()
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
                                root.contextFileRow = -1
                                emptyAreaContextMenu.popup()
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
    }

    Component {
        id: compactViewComponent

        Item {
            id: compactRoot

            property bool selectionActive: false
            property bool selectionMoved: false
            property real selectionStartX: 0
            property real selectionStartY: 0
            property real selectionCurrentX: 0
            property real selectionCurrentY: 0

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
                return {
                    x: 12,
                    y: row * (30 + compactView.spacing) + 4,
                    w: compactContentWidthForName(filesModel.rows[row].name),
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

                for (var i = 0; i < filesModel.rows.length; ++i) {
                    var r = compactSelectionRectForRow(i)

                    var horizontallyHit = right >= r.x && left <= (r.x + r.w)
                    var verticallyHit = bottom >= r.y && top <= (r.y + r.h)

                    if (horizontallyHit && verticallyHit)
                        next[i] = true
                }

                root.selectedFileRows = next

                var first = -1
                for (var k in next) {
                    first = parseInt(k, 10)
                    break
                }
                root.currentFileRow = first
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
                    model: filesModel.rows
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
                        readonly property bool sameAsDragged: root.isDraggedRow(index)

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: root.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                   ? Theme.AppTheme.selectedSoft
                                   : root.isFileRowSelected(index)
                                     ? Theme.AppTheme.selected
                                     : compactMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
                            border.color: root.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                          ? Theme.AppTheme.accent
                                          : "transparent"
                            border.width: root.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged ? 1 : 0
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
                                visible: root.editingFileRow !== index
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: Theme.AppTheme.text
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: parent.width - 24
                            }

                            TextField {
                                visible: root.editingFileRow === index
                                width: parent.width - 24
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.editingFileNameDraft
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
                                        root.editingFileNameDraft = text
                                }

                                onAccepted: root.commitRenameRow(index, root.editingFileNameDraft)

                                onActiveFocusChanged: {
                                    if (!activeFocus && visible)
                                        root.commitRenameRow(index, root.editingFileNameDraft)
                                }

                                Keys.onEscapePressed: root.cancelRenameRow()
                            }
                        }

                        DropArea {
                            anchors.fill: parent

                            onEntered: function(drag) {
                                var ok = compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                drag.accepted = ok
                                if (ok)
                                    root.detailsDropHoverRow = index
                            }

                            onExited: function(drag) {
                                if (root.detailsDropHoverRow === index)
                                    root.detailsDropHoverRow = -1
                            }

                            onDropped: function(drop) {
                                if (compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged) {
                                    drop.accepted = true
                                    root.handleDroppedItem(modelData.name, "folder")
                                }

                                if (root.detailsDropHoverRow === index)
                                    root.detailsDropHoverRow = -1
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
                                if (root.editingFileRow >= 0 && root.editingFileRow !== index)
                                    root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

                                var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                                var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                                var alreadySelected = root.isFileRowSelected(index)

                                if (mouse.button === Qt.RightButton) {
                                    if (!alreadySelected)
                                        root.selectOnlyFileRow(index)

                                    root.contextFileRow = index

                                    if (root.selectedFileCount() > 1)
                                        multiFileContextMenu.popup()
                                    else
                                        fileRowContextMenu.popup()

                                    return
                                }

                                if (mouse.button === Qt.LeftButton) {
                                    if (shift) {
                                        var anchor = root.selectionAnchorRow >= 0 ? root.selectionAnchorRow : index
                                        root.selectFileRange(anchor, index, true)
                                    } else if (ctrl) {
                                        root.toggleFileRowSelection(index)
                                    } else {
                                        if (!alreadySelected)
                                            root.selectOnlyFileRow(index)
                                    }

                                    if (root.isFileRowSelected(index))
                                        root.beginFileDrag(index)
                                }
                            }

                            onDoubleClicked: {
                                applySnapshot(backend.openItems(root.singleItemForBackend(index)))
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
                                Drag.imageSource: root.dragPreviewReady ? root.draggedFilePreviewUrl : ""
                                Drag.mimeData: ({
                                    "application/x-fileexplorer-item": JSON.stringify({
                                        row: index,
                                        rows: root.selectedFileRowsArray(),
                                        count: root.draggedFileCount,
                                        name: root.draggedFileName,
                                        type: root.draggedFileType,
                                        icon: root.draggedFileIcon
                                    })
                                })

                                Drag.onDragFinished: function(dropAction) {
                                    dragProxy.x = 0
                                    dragProxy.y = 0
                                    root.detailsDropHoverRow = -1
                                    root.clearFileDrag()
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

                            if (row < 0 || row >= filesModel.rows.length)
                                return false

                            var r = compactRoot.compactHitRectForRow(row)

                            return xInView >= r.x
                                && xInView <= (r.x + r.w)
                                && yInContent >= r.y
                                && yInContent <= (r.y + r.h)
                        }

                        onPressed: function(mouse) {
                            if (root.editingFileRow >= 0)
                                root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

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
                                root.clearFileSelection()
                                root.contextFileRow = -1
                                mouse.accepted = true
                                return
                            }

                            if (pendingEmptyContextMenu) {
                                root.clearFileSelection()
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
                                root.contextFileRow = -1
                                emptyAreaContextMenu.popup()
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
    }

    Component {
        id: largeIconsViewComponent

        Item {
            id: largeIconsRoot

            property bool selectionActive: false
            property bool selectionMoved: false
            property real selectionStartX: 0
            property real selectionStartY: 0
            property real selectionCurrentX: 0
            property real selectionCurrentY: 0

            readonly property int delegateWidth: 104
            readonly property int delegateHeight: 92

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

                for (var i = 0; i < filesModel.rows.length; ++i) {
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

                root.selectedFileRows = next

                var first = -1
                for (var k in next) {
                    first = parseInt(k, 10)
                    break
                }
                root.currentFileRow = first
            }

            GridView {
                id: gridView
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                clip: true
                model: filesModel.rows
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

                        for (var i = 0; i < filesModel.rows.length; ++i) {
                            var r = largeIconsRoot.contentHitRectFor(i)
                            if (xInContent >= r.x && xInContent <= (r.x + r.w)
                                    && yInContent >= r.y && yInContent <= (r.y + r.h)) {
                                return true
                            }
                        }

                        return false
                    }

                    onPressed: function(mouse) {
                        if (root.editingFileRow >= 0)
                            root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

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
                            root.clearFileSelection()
                            root.contextFileRow = -1
                            mouse.accepted = true
                            return
                        }

                        if (pendingEmptyContextMenu) {
                            root.clearFileSelection()
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
                            root.contextFileRow = -1
                            emptyAreaContextMenu.popup()
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
                    readonly property bool sameAsDragged: root.isDraggedRow(index)

                    color: root.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                           ? Theme.AppTheme.selectedSoft
                           : root.isFileRowSelected(index)
                             ? Theme.AppTheme.selected
                             : gridMouse.containsMouse ? Theme.AppTheme.selectedSoft : "transparent"
                    border.color: root.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                                  ? Theme.AppTheme.accent
                                  : "transparent"
                    border.width: root.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged ? 1 : 0

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
                            visible: root.editingFileRow !== index
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
                            visible: root.editingFileRow === index
                            width: 88
                            height: 24
                            text: root.editingFileNameDraft
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
                                    root.editingFileNameDraft = text
                            }

                            onAccepted: root.commitRenameRow(index, root.editingFileNameDraft)

                            onActiveFocusChanged: {
                                if (!activeFocus && visible)
                                    root.commitRenameRow(index, root.editingFileNameDraft)
                            }

                            Keys.onEscapePressed: root.cancelRenameRow()
                        }
                    }

                    DropArea {
                        anchors.fill: parent

                        onEntered: function(drag) {
                            var ok = gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                            drag.accepted = ok
                            if (ok)
                                root.detailsDropHoverRow = index
                        }

                        onExited: function(drag) {
                            if (root.detailsDropHoverRow === index)
                                root.detailsDropHoverRow = -1
                        }

                        onDropped: function(drop) {
                            if (gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged) {
                                drop.accepted = true
                                root.handleDroppedItem(modelData.name, "folder")
                            }

                            if (root.detailsDropHoverRow === index)
                                root.detailsDropHoverRow = -1
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
                            if (root.editingFileRow >= 0 && root.editingFileRow !== index)
                                root.commitRenameRow(root.editingFileRow, root.editingFileNameDraft)

                            var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0
                            var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0
                            var alreadySelected = root.isFileRowSelected(index)

                            if (mouse.button === Qt.RightButton) {
                                if (!alreadySelected)
                                    root.selectOnlyFileRow(index)

                                root.contextFileRow = index

                                if (root.selectedFileCount() > 1)
                                    multiFileContextMenu.popup()
                                else
                                    fileRowContextMenu.popup()

                                return
                            }

                            if (mouse.button === Qt.LeftButton) {
                                if (shift) {
                                    var anchor = root.selectionAnchorRow >= 0 ? root.selectionAnchorRow : index
                                    root.selectFileRange(anchor, index, true)
                                } else if (ctrl) {
                                    root.toggleFileRowSelection(index)
                                } else {
                                    if (!alreadySelected)
                                        root.selectOnlyFileRow(index)
                                }

                                if (!ctrl && !shift && root.isFileRowSelected(index))
                                    root.beginFileDrag(index)
                            }
                        }

                        onDoubleClicked: {
                            applySnapshot(backend.openItems(root.singleItemForBackend(index)))
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
                            Drag.imageSource: root.dragPreviewReady ? root.draggedFilePreviewUrl : ""
                            Drag.mimeData: ({
                                "application/x-fileexplorer-item": JSON.stringify({
                                    row: index,
                                    rows: root.selectedFileRowsArray(),
                                    count: root.draggedFileCount,
                                    name: root.draggedFileName,
                                    type: root.draggedFileType,
                                    icon: root.draggedFileIcon
                                })
                            })

                            Drag.onDragFinished: function(dropAction) {
                                dragProxy.x = 0
                                dragProxy.y = 0
                                root.detailsDropHoverRow = -1
                                root.clearFileDrag()
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
    }

    Rectangle {
        anchors.fill: parent
        radius: (root.visibility === Window.Maximized || root.windowMoveActive) ? 0 : 14
        color: Theme.AppTheme.bg
        border.color: (root.visibility === Window.Maximized || root.windowMoveActive) ? "transparent" : Theme.AppTheme.border
        border.width: (root.visibility === Window.Maximized || root.windowMoveActive) ? 0 : 1
        clip: !root.windowMoveActive

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: Theme.AppTheme.titleBg
                border.color: Theme.AppTheme.borderSoft
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8

                    Item {
                        id: tabsArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            id: tabsCaptionArea
                            anchors.fill: parent
                            z: 0
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: false

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    root.startSystemMove()
                            }

                            onDoubleClicked: root.toggleMaximize()
                        }

                        Row {
                            id: tabsRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 34
                            spacing: 6
                            z: 2
                            readonly property bool overflowing: tabsContent.width > Math.max(0, tabsRow.width - addTabButton.width - tabsRow.spacing)

                            Rectangle {
                                id: scrollLeftButton
                                width: 26
                                height: 26
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tabsRow.overflowing
                                color: leftScrollMouse.pressed
                                       ? Theme.AppTheme.pressed
                                       : leftScrollMouse.containsMouse
                                         ? Theme.AppTheme.hover
                                         : "transparent"
                                opacity: tabFlick.contentX > 0 ? 1.0 : 0.45

                                AppIcon {
                                    anchors.centerIn: parent
                                    name: "chevron-left"
                                    darkTheme: Theme.AppTheme.isDark
                                    iconSize: 14
                                }

                                MouseArea {
                                    id: leftScrollMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: tabFlick.contentX > 0
                                    onClicked: root.scrollTabsBy(-240)
                                }
                            }

                            Item {
                                id: tabCluster
                                height: parent.height
                                width: Math.max(
                                           0,
                                           tabsRow.width
                                           - (tabsRow.overflowing ? scrollLeftButton.width : 0)
                                           - (tabsRow.overflowing ? scrollRightButton.width : 0)
                                           - (tabsRow.overflowing ? tabsRow.spacing * 2 : 0)
                                       )

                                Item {
                                    id: addTabDock
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    x: Math.min(
                                           Math.max(0, tabsContent.width + root.tabSpacing),
                                           Math.max(0, tabCluster.width - addTabButton.width)
                                       )
                                    width: addTabButton.width
                                    z: 6

                                    Rectangle {
                                        id: addTabButton
                                        width: 28
                                        height: 28
                                        radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: addTabMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "add"
                                            darkTheme: Theme.AppTheme.isDark
                                            iconSize: 16
                                        }

                                        MouseArea {
                                            id: addTabMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                root.addTab("New Tab")
                                                Qt.callLater(function() {
                                                    root.ensureTabVisible(tabsModel.count - 1)
                                                })
                                            }
                                        }
                                    }
                                }

                                Item {
                                    id: tabViewport
                                    x: 0
                                    y: 0
                                    width: addTabDock.x
                                    height: parent.height
                                    clip: true

                                    Flickable {
                                        id: tabFlick
                                        anchors.fill: parent
                                        contentWidth: tabsContent.width
                                        contentHeight: height
                                        boundsBehavior: Flickable.StopAtBounds
                                        flickableDirection: Flickable.HorizontalFlick

                                        interactive: contentWidth > width
                                        acceptedButtons: Qt.NoButton

                                        clip: true

                                        Item {
                                            id: tabsContent
                                            width: tabsModel.count > 0
                                                   ? tabsModel.count * root.tabWidth + (tabsModel.count - 1) * root.tabSpacing
                                                   : 0
                                            height: parent.height

                                            Repeater {
                                                id: tabsRepeater
                                                model: tabsModel

                                                delegate: Rectangle {
                                                    id: tabDelegate
                                                    property var rootWindow: root
                                                    required property int index
                                                    required property string title
                                                    required property string icon

                                                    property bool movedEnough: false

                                                    x: tabDelegate.index * (rootWindow.tabWidth + rootWindow.tabSpacing)
                                                    y: 1
                                                    width: rootWindow.tabWidth
                                                    height: 32
                                                    radius: 9
                                                    z: rootWindow.draggedTabIndex === tabDelegate.index ? 100 : 1

                                                    transform: Translate {
                                                        x: rootWindow.draggedTabIndex === tabDelegate.index ? rootWindow.draggedTabOffset : 0
                                                    }

                                                    color: tabDelegate.index === rootWindow.currentTab
                                                           ? (tabMouse.pressed
                                                                ? (Theme.AppTheme.isDark ? "#2a3342" : "#e7edf8")
                                                                : tabMouse.containsMouse
                                                                  ? (Theme.AppTheme.isDark ? "#242c3a" : "#f4f7fc")
                                                                  : (Theme.AppTheme.isDark ? "#202633" : "#ffffff"))
                                                           : (tabMouse.pressed
                                                                ? Theme.AppTheme.pressed
                                                                : tabMouse.containsMouse
                                                                  ? Theme.AppTheme.hover
                                                                  : "transparent")

                                                    border.color: tabDelegate.index === rootWindow.currentTab ? Theme.AppTheme.border : "transparent"
                                                    border.width: 1

                                                    DropArea {
                                                        anchors.fill: parent
                                                        z: 2

                                                        function maybeActivate() {
                                                            if (tabDelegate.rootWindow.draggedFileCount > 0
                                                                    && tabDelegate.rootWindow.currentTab !== tabDelegate.index) {
                                                                tabDelegate.rootWindow.activateTabLocal(tabDelegate.index)
                                                                tabDelegate.rootWindow.ensureTabVisible(tabDelegate.index)
                                                            }
                                                        }

                                                        onEntered: function(drag) {
                                                            if (tabDelegate.rootWindow.draggedFileCount > 0) {
                                                                drag.accepted = true
                                                                maybeActivate()
                                                            }
                                                        }

                                                        onPositionChanged: function(drag) {
                                                            if (tabDelegate.rootWindow.draggedFileCount > 0) {
                                                                drag.accepted = true
                                                                maybeActivate()
                                                            }
                                                        }

                                                        onDropped: function(drop) {
                                                            if (tabDelegate.rootWindow.draggedFileCount > 0) {
                                                                drop.accepted = true
                                                                maybeActivate()
                                                            }
                                                        }
                                                    }

                                                    Row {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 12
                                                        spacing: 8
                                                        visible: tabDelegate.rootWindow.editingTabIndex !== tabDelegate.index

                                                        AppIcon {
                                                            name: tabDelegate.icon || ""
                                                            darkTheme: tabDelegate.Theme.AppTheme.isDark
                                                            iconSize: 15
                                                        }

                                                        Text {
                                                            text: tabDelegate.title || ""
                                                            color: Theme.AppTheme.text
                                                            font.pixelSize: 13
                                                            font.bold: tabDelegate.index === tabDelegate.rootWindow.currentTab
                                                            elide: Text.ElideRight
                                                            width: 140
                                                        }
                                                    }

                                                    TextField {
                                                        visible: tabDelegate.rootWindow.editingTabIndex === tabDelegate.index
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 12
                                                        anchors.right: closeButton.left
                                                        anchors.rightMargin: 8
                                                        height: 24

                                                        text: tabDelegate.rootWindow.editingTabTitleDraft || ""
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 13
                                                        selectByMouse: true
                                                        leftPadding: 8
                                                        rightPadding: 8
                                                        topPadding: 0
                                                        bottomPadding: 0

                                                        background: Rectangle {
                                                            radius: 6
                                                            color: tabDelegate.Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
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
                                                                tabDelegate.rootWindow.editingTabTitleDraft = text
                                                        }

                                                        onAccepted: tabDelegate.rootWindow.commitRenameTab(tabDelegate.index, text || "")

                                                        onActiveFocusChanged: {
                                                            if (!activeFocus && visible)
                                                                tabDelegate.rootWindow.commitRenameTab(tabDelegate.index, text || "")
                                                        }

                                                        Keys.onEscapePressed: tabDelegate.rootWindow.cancelRenameTab()
                                                    }

                                                    Rectangle {
                                                        id: closeButton
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 6
                                                        width: 18
                                                        height: 18
                                                        radius: 9
                                                        color: closeMouse.containsMouse ? tabDelegate.Theme.AppTheme.hover : "transparent"
                                                        z: 3
                                                        visible: tabDelegate.rootWindow.editingTabIndex !== tabDelegate.index

                                                        AppIcon {
                                                            anchors.centerIn: parent
                                                            name: "close"
                                                            darkTheme: tabDelegate.Theme.AppTheme.isDark
                                                            iconSize: 12
                                                            iconOpacity: 0.75
                                                        }

                                                        MouseArea {
                                                            id: closeMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            acceptedButtons: Qt.LeftButton
                                                            preventStealing: true

                                                            onClicked: function(mouse) {
                                                                tabDelegate.rootWindow.closeTab(tabDelegate.index)
                                                                mouse.accepted = true
                                                            }
                                                        }
                                                    }

                                                    DragHandler {
                                                        id: dragHandler
                                                        target: null
                                                        acceptedButtons: Qt.LeftButton
                                                        enabled: tabDelegate.rootWindow.editingTabIndex !== tabDelegate.index
                                                        xAxis.enabled: true
                                                        yAxis.enabled: false
                                                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                                                        onActiveChanged: {
                                                            tabDelegate.rootWindow.tabDragActive = active

                                                            if (active) {
                                                                tabDelegate.rootWindow.tabPressActive = true
                                                                tabDelegate.rootWindow.currentTab = tabDelegate.index
                                                                tabDelegate.rootWindow.draggedTabIndex = tabDelegate.index
                                                                tabDelegate.rootWindow.draggedTabStartIndex = tabDelegate.index
                                                                tabDelegate.rootWindow.draggedTabStartContentX = tabFlick.contentX
                                                                tabDelegate.rootWindow.draggedTabOffset = 0
                                                                tabDelegate.movedEnough = false
                                                                tabDelegate.rootWindow.tabAutoScrollDirection = 0
                                                                tabDelegate.rootWindow.tabAutoScrollTimerRef.start()
                                                            } else {
                                                                var rw = tabDelegate.rootWindow
                                                                var startIndex = rw.draggedTabStartIndex
                                                                var endIndex = rw.draggedTabIndex

                                                                rw.tabAutoScrollDirection = 0
                                                                rw.tabAutoScrollTimerRef.stop()

                                                                if (startIndex >= 0 && endIndex >= 0 && startIndex !== endIndex) {
                                                                    var finalIndex = endIndex

                                                                    rw.applySnapshot(
                                                                        rw.backend.moveTab(startIndex, finalIndex),
                                                                        { preserveTabsOrder: true }
                                                                    )

                                                                    rw.currentTab = finalIndex

                                                                    if (rw.backend && rw.backend.activateTab) {
                                                                        rw.applySnapshot(
                                                                            rw.backend.activateTab(finalIndex),
                                                                            { preserveTabsOrder: true }
                                                                        )
                                                                    }

                                                                    Qt.callLater(function() {
                                                                        rw.ensureTabVisible(finalIndex)
                                                                    })
                                                                }

                                                                rw.draggedTabIndex = -1
                                                                rw.draggedTabStartIndex = -1
                                                                rw.draggedTabStartContentX = 0
                                                                rw.draggedTabOffset = 0
                                                                rw.tabPressActive = false
                                                                tabDelegate.movedEnough = false
                                                            }
                                                        }

                                                        onTranslationChanged: {
                                                            if (tabDelegate.rootWindow.draggedTabIndex < 0)
                                                                return

                                                            if (Math.abs(translation.x) > 8)
                                                                tabDelegate.movedEnough = true

                                                            var slotSize = tabDelegate.rootWindow.tabWidth + tabDelegate.rootWindow.tabSpacing
                                                            var currentIndex = tabDelegate.rootWindow.draggedTabIndex
                                                            var startIndex = tabDelegate.rootWindow.draggedTabStartIndex
                                                            var scrollDelta = tabFlick.contentX - tabDelegate.rootWindow.draggedTabStartContentX

                                                            var draggedLeftX = startIndex * slotSize + translation.x + scrollDelta
                                                            var draggedCenterX = draggedLeftX + tabDelegate.rootWindow.tabWidth / 2

                                                            var targetIndex = Math.floor(draggedCenterX / slotSize)
                                                            targetIndex = Math.max(0, Math.min(tabsModel.count - 1, targetIndex))

                                                            tabDelegate.rootWindow.draggedTabOffset =
                                                                    draggedLeftX - currentIndex * slotSize

                                                            if (targetIndex !== currentIndex) {
                                                                tabDelegate.rootWindow.moveTabLocally(currentIndex, targetIndex)
                                                                tabDelegate.rootWindow.draggedTabIndex = targetIndex
                                                            }

                                                            var draggedCenterInViewport = draggedCenterX - tabFlick.contentX

                                                            if (draggedCenterInViewport < 36)
                                                                tabDelegate.rootWindow.tabAutoScrollDirection = -1
                                                            else if (draggedCenterInViewport > tabViewport.width - 36)
                                                                tabDelegate.rootWindow.tabAutoScrollDirection = 1
                                                            else
                                                                tabDelegate.rootWindow.tabAutoScrollDirection = 0
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: tabMouse
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: tabDelegate.rootWindow.editingTabIndex === tabDelegate.index ? 6 : 30
                                                        hoverEnabled: true
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                        enabled: tabDelegate.rootWindow.editingTabIndex !== tabDelegate.index
                                                        preventStealing: false

                                                        onPressed: function(mouse) {
                                                            tabDelegate.rootWindow.tabPressActive = true

                                                            if (tabDelegate.rootWindow.editingTabIndex >= 0
                                                                    && tabDelegate.rootWindow.editingTabIndex !== tabDelegate.index) {
                                                                tabDelegate.rootWindow.commitRenameTab(
                                                                    tabDelegate.rootWindow.editingTabIndex,
                                                                    tabDelegate.rootWindow.editingTabTitleDraft
                                                                )
                                                            }

                                                            if (mouse.button === Qt.RightButton) {
                                                                tabDelegate.rootWindow.showTabContextMenu(tabDelegate.index)
                                                                return
                                                            }

                                                            if (mouse.button === Qt.LeftButton)
                                                                tabDelegate.rootWindow.currentTab = tabDelegate.index
                                                        }

                                                        onReleased: {
                                                            if (!dragHandler.active)
                                                                tabDelegate.rootWindow.tabPressActive = false
                                                        }

                                                        onCanceled: {
                                                            tabDelegate.rootWindow.tabPressActive = false
                                                        }

                                                        onClicked: function(mouse) {
                                                            if (mouse.button === Qt.LeftButton && !tabDelegate.movedEnough) {
                                                                tabDelegate.rootWindow.activateTabLocal(tabDelegate.index)
                                                                tabDelegate.rootWindow.ensureTabVisible(tabDelegate.index)
                                                            }

                                                            if (!dragHandler.active)
                                                                tabDelegate.rootWindow.tabPressActive = false
                                                        }

                                                        onDoubleClicked: {
                                                            if (!tabDelegate.movedEnough)
                                                                tabDelegate.rootWindow.beginRenameTab(tabDelegate.index)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 26
                                        visible: tabsRow.overflowing && tabFlick.contentX > 0
                                        z: 5

                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Theme.AppTheme.isDark ? "#000000" : "#cfd5dd" }
                                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                                        }
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 26
                                        visible: tabsRow.overflowing
                                                 && tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1)
                                        z: 5

                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                                            GradientStop { position: 1.0; color: Theme.AppTheme.isDark ? "#000000" : "#cfd5dd" }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: scrollRightButton
                                width: 26
                                height: 26
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tabsRow.overflowing
                                color: rightScrollMouse.pressed
                                       ? Theme.AppTheme.pressed
                                       : rightScrollMouse.containsMouse
                                         ? Theme.AppTheme.hover
                                         : "transparent"
                                opacity: tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1) ? 1.0 : 0.45

                                AppIcon {
                                    anchors.centerIn: parent
                                    name: "chevron-right"
                                    darkTheme: Theme.AppTheme.isDark
                                    iconSize: 14
                                }

                                MouseArea {
                                    id: rightScrollMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1)
                                    onClicked: root.scrollTabsBy(240)
                                }
                            }
                        }

                        MouseArea {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: tabsRow.right
                            anchors.right: parent.right
                            z: 1
                            acceptedButtons: Qt.LeftButton

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    root.startSystemMove()
                            }

                            onDoubleClicked: root.toggleMaximize()
                        }
                    }

                    Item {
                        id: dragStrip
                        Layout.fillHeight: true
                        Layout.preferredWidth: 140

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    root.startSystemMove()
                            }

                            onDoubleClicked: root.toggleMaximize()
                        }
                    }

                    RowLayout {
                        id: windowButtons
                        spacing: 2

                        WindowButton {
                            iconName: "minimize"
                            darkTheme: Theme.AppTheme.isDark
                            onClicked: root.showMinimized()
                        }

                        WindowButton {
                            iconName: root.visibility === Window.Maximized
                                      ? "filter-none"
                                      : "check-box-outline-blank"
                            darkTheme: Theme.AppTheme.isDark
                            onClicked: root.toggleMaximize()
                        }

                        WindowButton {
                            iconName: "close"
                            darkTheme: Theme.AppTheme.isDark
                            hoverColor: "#d85b5b"
                            pressedColor: "#c94c4c"
                            onClicked: Qt.quit()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: Theme.AppTheme.surface
                border.color: Theme.AppTheme.borderSoft
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    IconButton {
                        iconName: "arrow-back"
                        tooltipText: "Back"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: applySnapshot(backend.goBack())
                    }

                    IconButton {
                        iconName: "arrow-forward"
                        tooltipText: "Forward"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: applySnapshot(backend.goForward())
                    }

                    IconButton {
                        iconName: "arrow-upward"
                        tooltipText: "Up"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: applySnapshot(backend.goUp())
                    }

                    IconButton {
                        iconName: "refresh"
                        tooltipText: "Refresh"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: applySnapshot(backend.refresh())
                    }

                    Rectangle {
                        id: pathBar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 10
                        color: Theme.AppTheme.isDark ? "#1b2230" : "#fcfcfd"
                        border.color: root.editingPath ? Theme.AppTheme.accent : Theme.AppTheme.border
                        border.width: 1

                        StackLayout {
                            anchors.fill: parent
                            currentIndex: root.editingPath ? 1 : 0

                            Item {
                                clip: true

                                Flickable {
                                    id: breadcrumbFlick
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    contentWidth: Math.max(width, breadcrumbRow.width)
                                    contentHeight: height
                                    clip: true
                                    interactive: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Row {
                                        id: breadcrumbRow
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Repeater {
                                            model: pathModel

                                            delegate: Row {
                                                id: breadcrumbDelegate
                                                required property int index
                                                required property var modelData
                                                spacing: 6

                                                readonly property bool dropHovered: root.breadcrumbDropHoverIndex === index

                                                Rectangle {
                                                    id: crumbPill
                                                    height: 28
                                                    radius: 8
                                                    color: dropHovered
                                                           ? Theme.AppTheme.selectedSoft
                                                           : crumbMouse.pressed
                                                             ? Theme.AppTheme.pressed
                                                             : crumbMouse.containsMouse
                                                               ? (Theme.AppTheme.isDark ? "#344055" : "#dfe9f8")
                                                               : "transparent"
                                                    border.color: dropHovered ? Theme.AppTheme.accent : "transparent"
                                                    border.width: dropHovered ? 1 : 0
                                                    width: Math.min(crumbContent.implicitWidth + 16, 190)
                                                    clip: true
                                                    property var rootWindow: root

                                                    DropArea {
                                                        anchors.fill: parent

                                                        onEntered: function(drag) {
                                                            drag.accepted = crumbPill.rootWindow.draggedFileCount > 0
                                                            if (drag.accepted)
                                                                crumbPill.rootWindow.breadcrumbDropHoverIndex = breadcrumbDelegate.index
                                                        }

                                                        onExited: function(drag) {
                                                            if (crumbPill.rootWindow.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                                crumbPill.rootWindow.breadcrumbDropHoverIndex = -1
                                                        }

                                                        onDropped: function(drop) {
                                                            if (crumbPill.rootWindow.draggedFileCount > 0) {
                                                                drop.accepted = true
                                                                crumbPill.rootWindow.handleDroppedItem(breadcrumbDelegate.modelData.label, "breadcrumb")
                                                            }

                                                            if (crumbPill.rootWindow.breadcrumbDropHoverIndex === breadcrumbDelegate.index)
                                                                crumbPill.rootWindow.breadcrumbDropHoverIndex = -1
                                                        }
                                                    }

                                                    Row {
                                                        id: crumbContent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 8
                                                        spacing: 6

                                                        AppIcon {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            name: modelData.icon
                                                            darkTheme: Theme.AppTheme.isDark
                                                            iconSize: 13
                                                            visible: modelData.icon !== ""
                                                        }

                                                        Text {
                                                            id: crumbText
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.label
                                                            color: Theme.AppTheme.text
                                                            font.pixelSize: 13
                                                            elide: Text.ElideRight
                                                            width: Math.min(140, implicitWidth)
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: crumbMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                        z: 1

                                                        onPressed: function(mouse) {
                                                            if (mouse.button === Qt.RightButton) {
                                                                root.contextBreadcrumbIndex = index
                                                                breadcrumbContextMenu.popup()
                                                                mouse.accepted = true
                                                            }
                                                        }

                                                        onClicked: function(mouse) {
                                                            if (mouse.button === Qt.LeftButton)
                                                                root.setPathFromIndex(index)
                                                        }

                                                        onDoubleClicked: {
                                                            root.editingPath = true
                                                            pathField.forceActiveFocus()
                                                            pathField.selectAll()
                                                        }
                                                    }
                                                }

                                                AppIcon {
                                                    visible: index < pathModel.count - 1
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    name: "chevron-right"
                                                    darkTheme: Theme.AppTheme.isDark
                                                    iconSize: 12
                                                    iconOpacity: 0.65
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        x: breadcrumbRow.width
                                        width: Math.max(0, parent.width - breadcrumbRow.width)
                                        acceptedButtons: Qt.LeftButton

                                        onDoubleClicked: {
                                            root.editingPath = true
                                            pathField.forceActiveFocus()
                                            pathField.selectAll()
                                        }
                                    }

                                    onContentWidthChanged: contentX = Math.max(0, contentWidth - width)
                                }
                            }

                            TextField {
                                id: pathField
                                color: Theme.AppTheme.text
                                font.pixelSize: 13
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 0
                                bottomPadding: 0
                                verticalAlignment: TextInput.AlignVCenter
                                background: Rectangle { color: "transparent" }

                                onAccepted: root.finishPathEditing(true)
                                onActiveFocusChanged: {
                                    if (!activeFocus && root.editingPath)
                                        root.finishPathEditing(false)
                                }
                                Keys.onEscapePressed: root.finishPathEditing(false)
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 38
                        radius: 10
                        color: Theme.AppTheme.isDark ? "#1b2230" : "#fcfcfd"
                        border.color: searchField.activeFocus ? Theme.AppTheme.accent : Theme.AppTheme.border
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 8

                            Rectangle {
                                id: searchScopeButton
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 28
                                radius: 8
                                color: searchScopeMouse.pressed
                                       ? Theme.AppTheme.pressed
                                       : searchScopeMouse.containsMouse
                                         ? Theme.AppTheme.hover
                                         : "transparent"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    AppIcon {
                                        name: root.searchScope === "global" ? "hard-drive" : "folder"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: 14
                                    }

                                    AppIcon {
                                        name: searchScopeMenu.visible ? "keyboard-arrow-up" : "keyboard-arrow-down"
                                        darkTheme: Theme.AppTheme.isDark
                                        iconSize: 10
                                        iconOpacity: 0.6
                                    }
                                }

                                MouseArea {
                                    id: searchScopeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: {
                                        var p = searchScopeButton.mapToItem(root.contentItem, 0, searchScopeButton.height + 6)
                                        searchScopeMenu.x = p.x
                                        searchScopeMenu.y = p.y
                                        searchScopeMenu.open()
                                    }
                                }
                            }

                            AppIcon {
                                name: "search"
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 14
                                iconOpacity: 0.65
                            }

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: root.searchScope === "global"
                                                 ? "Search everywhere"
                                                 : "Search in folder"
                                placeholderTextColor: Theme.AppTheme.muted
                                text: root.currentSearch
                                color: Theme.AppTheme.text
                                font.pixelSize: 13
                                topPadding: 0
                                bottomPadding: 0
                                leftPadding: 0
                                rightPadding: 0
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                background: Rectangle { color: "transparent" }

                                onTextChanged: root.currentSearch = text
                                onAccepted: applySnapshot(backend.search(text, root.searchScope))
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: Theme.AppTheme.surface2
                border.color: Theme.AppTheme.borderSoft
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    IconButton {
                        id: createButton
                        iconName: "add"
                        tooltipText: "Create"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: createMenu.popup()
                    }

                    IconButton {
                        iconName: "content-cut"
                        tooltipText: "Cut"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: root.cutSelectedOrCurrent()
                    }

                    IconButton {
                        iconName: "content-copy"
                        tooltipText: "Copy"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: root.copySelectedOrCurrent()
                    }

                    IconButton {
                        iconName: "content-paste"
                        tooltipText: "Paste"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: applySnapshot(backend.pasteItems())
                    }

                    IconButton {
                        iconName: "edit"
                        tooltipText: "Rename"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: {
                            if (root.currentFileRow >= 0)
                                root.beginRenameRow(root.currentFileRow)
                        }
                    }

                    IconButton {
                        iconName: "delete"
                        tooltipText: "Delete"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: {
                            if (root.selectedFileCount() > 1)
                                root.askDeleteSelection()
                            else if (root.currentFileRow >= 0)
                                root.askDeleteRow(root.currentFileRow)
                        }
                    }

                    IconButton {
                        iconName: "sync"
                        tooltipText: "Test progress notification"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: {
                            deleteProgressTimer.stop()
                            deleteProgressTimer.progressValue = 0
                            deleteProgressTimer.notificationId = root.addProgressNotification("Moving files...", 0)
                            deleteProgressTimer.start()
                        }
                    }

                    IconButton {
                        id: toolbarViewButton
                        iconName: root.viewModeIcon(root.currentViewMode)
                        tooltipText: "View"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: viewModeMenu.popup()
                    }

                    IconButton {
                        id: moreButton
                        iconName: "more-horiz"
                        tooltipText: "More"
                        darkTheme: Theme.AppTheme.isDark
                        onClicked: moreActionsMenu.popup()
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            hoverEnabled: false

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    moreActionsMenu.popup()
                                    mouse.accepted = true
                                }
                            }
                        }
                    }


                    Rectangle {
                        id: previewToggleButton
                        width: 108
                        height: 32
                        radius: 9
                        color: root.previewEnabled
                               ? (Theme.AppTheme.isDark ? "#243249" : "#e3edff")
                               : (previewToolbarMouse.pressed
                                    ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                    : previewToolbarMouse.containsMouse
                                      ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                                      : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc"))
                        border.color: root.previewEnabled ? Theme.AppTheme.accent : Theme.AppTheme.border
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            AppIcon {
                                name: "preview"
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 14
                            }

                            Text {
                                text: "Preview"
                                color: Theme.AppTheme.text
                                font.pixelSize: 12
                                font.bold: root.previewEnabled
                            }
                        }

                        MouseArea {
                            id: previewToolbarMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onClicked: root.togglePreviewEnabled()
                        }
                    }

                    Rectangle {
                        id: themeButton
                        width: 116
                        height: 32
                        radius: 9
                        color: themeMouse.pressed
                               ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                               : themeMouse.containsMouse
                                 ? (Theme.AppTheme.isDark ? "#2d3748" : "#dce8fb")
                                 : (Theme.AppTheme.isDark ? "#1d2431" : "#fafbfc")
                        border.color: Theme.AppTheme.border
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            AppIcon {
                                name: root.themeMode === "Dark"
                                      ? "moon"
                                      : root.themeMode === "Light"
                                        ? "sun"
                                        : "computer"
                                darkTheme: Theme.AppTheme.isDark
                                iconSize: 14
                            }

                            Text {
                                text: root.themeMode
                                color: Theme.AppTheme.text
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: themeMenu.popup()
                            onPressed: function(mouse) {
                                if (mouse.button === Qt.RightButton)
                                    themeMenu.popup()
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item {
                    id: splitViewHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property int sidebarWidth: 286
                    property int sidebarMinWidth: 220
                    property int sidebarMaxWidth: Math.max(360, width * 0.45)
                    property int splitterWidth: 8

                    Rectangle {
                        id: sidebarPane
                        x: 0
                        y: 0
                        width: splitViewHost.sidebarWidth
                        height: parent.height
                        color: Theme.AppTheme.isDark ? "#121820" : "#f4f6f8"
                        border.color: Theme.AppTheme.borderSoft
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: "transparent"

                                TreeView {
                                    id: sidebarTree
                                    anchors.fill: parent
                                    model: sidebarModel
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
                                                                           && root.navDropHoverLabel === itemLabel
                                                                           && root.navDropHoverKind === itemKind

                                        width: sidebarTree.width
                                        implicitWidth: sidebarTree.width
                                        implicitHeight: itemSection ? 28 : 34

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: itemSection ? "transparent"
                                                               : dropHovered
                                                                 ? Theme.AppTheme.selectedSoft
                                                                 : tapArea.pressed
                                                                   ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                                                   : (root.selectedSidebarLabel === itemLabel && root.selectedSidebarKind === itemKind)
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
                                            anchors.leftMargin: 8 + depth * 14
                                            anchors.rightMargin: 10

                                            Row {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.topMargin: itemSection ? 6 : 8
                                                spacing: 6

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
                                                            iconSize: 12
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
                                                    root.setNavDropHover(itemLabel, itemKind)
                                            }

                                            onExited: function(drag) {
                                                root.clearNavDropHover(itemLabel, itemKind)
                                            }

                                            onDropped: function(drop) {
                                                if (!itemSection) {
                                                    drop.accepted = true
                                                    root.handleDroppedItem(itemLabel, itemKind)
                                                    root.clearNavDropHover(itemLabel, itemKind)
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
                                                    root.openLocation(itemLabel, itemIcon, itemKind)
                                            }

                                            onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton && !itemSection) {
                                                    root.contextSidebarLabel = itemLabel
                                                    root.contextSidebarKind = itemKind
                                                    root.contextSidebarIcon = itemIcon
                                                    sidebarContextMenu.popup()
                                                }
                                            }
                                        }
                                    }

                                    Component.onCompleted: expand(0)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20 + 22 + (drivesModel.count * 48) + Math.max(0, drivesModel.count - 1) * 1 + 20
                                Layout.minimumHeight: 120
                                radius: 12
                                color: Theme.AppTheme.isDark ? "#171d27" : "#fbfcfd"
                                border.color: Theme.AppTheme.borderSoft
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 1

                                    Text {
                                        text: "Drives"
                                        color: Theme.AppTheme.text
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    Repeater {
                                        model: drivesModel

                                        delegate: Rectangle {
                                            required property var modelData
                                            property var rootWindow: root

                                            Layout.fillWidth: true
                                            width: parent ? parent.width : 240
                                            height: 48
                                            radius: 8

                                            readonly property real usedPct: modelData.total > 0 ? (modelData.used / modelData.total) : 0
                                            readonly property color usedColor: usedPct >= 0.85 ? Theme.AppTheme.driveUsedRed : Theme.AppTheme.driveUsedBlue
                                            readonly property bool dropHovered: root.navDropHoverLabel === modelData.label
                                                                                && root.navDropHoverKind === "drive"

                                            color: dropHovered
                                                   ? Theme.AppTheme.selectedSoft
                                                   : driveMouseArea.pressed
                                                     ? (Theme.AppTheme.isDark ? "#3a475d" : "#cadbf8")
                                                     : (root.selectedSidebarKind === "drive" && root.selectedSidebarLabel === modelData.label)
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
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                anchors.topMargin: 4
                                                anchors.bottomMargin: 4
                                                spacing: 2

                                                Row {
                                                    spacing: 6

                                                    AppIcon {
                                                        name: modelData.icon
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 14
                                                    }

                                                    Text {
                                                        text: modelData.label
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: 5
                                                    radius: 3
                                                    color: Theme.AppTheme.driveFree

                                                    Rectangle {
                                                        width: parent.width * Math.max(0, Math.min(1, usedPct))
                                                        height: parent.height
                                                        radius: 3
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
                                                    rootWindow.setNavDropHover(modelData.label, "drive")
                                                }

                                                onExited: function(drag) {
                                                    rootWindow.clearNavDropHover(modelData.label, "drive")
                                                }

                                                onDropped: function(drop) {
                                                    drop.accepted = true
                                                    rootWindow.handleDroppedItem(modelData.label, "drive")
                                                }
                                            }

                                            MouseArea {
                                                id: driveMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                                onClicked: root.openLocation(modelData.label, modelData.icon, "drive")

                                                onPressed: function(mouse) {
                                                    if (mouse.button === Qt.RightButton) {
                                                        root.contextSidebarLabel = modelData.label
                                                        root.contextSidebarKind = "drive"
                                                        root.contextSidebarIcon = modelData.icon
                                                        sidebarContextMenu.popup()
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
                        width: splitViewHost.splitterWidth
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
                                var p = splitterMouse.mapToItem(splitViewHost, mouse.x, mouse.y)
                                pressSceneX = p.x
                                startWidth = splitViewHost.sidebarWidth
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed)
                                    return

                                var p = splitterMouse.mapToItem(splitViewHost, mouse.x, mouse.y)
                                var dx = p.x - pressSceneX
                                var nextWidth = startWidth + dx

                                nextWidth = Math.max(splitViewHost.sidebarMinWidth,
                                                     Math.min(splitViewHost.sidebarMaxWidth, nextWidth))

                                splitViewHost.sidebarWidth = nextWidth
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
                        border.width: 1

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
                                        Layout.preferredHeight: root.currentViewMode === "Details" ? 40 : 0
                                        visible: root.currentViewMode === "Details"
                                        color: Theme.AppTheme.isDark ? "#171d27" : "#f6f7f9"
                                        border.color: Theme.AppTheme.borderSoft
                                        border.width: 1

                                        Item {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10

                                            Rectangle {
                                                id: nameHeader
                                                x: 0
                                                y: 0
                                                width: root.detailsNameWidth
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
                                                    spacing: 6

                                                    Text {
                                                        text: "Name"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }

                                                    AppIcon {
                                                        visible: root.sortColumn === 0
                                                        name: root.sortAscending ? "keyboard-arrow-up" : "keyboard-arrow-down"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 12
                                                    }
                                                }

                                                MouseArea {
                                                    id: nameHeaderMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.sortFiles(0)
                                                }

                                                Rectangle {
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: 8
                                                    color: resizeNameMouse.pressed ? Theme.AppTheme.accent : resizeNameMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

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
                                                            startWidth = root.detailsNameWidth
                                                        }

                                                        onPositionChanged: function(mouse) {
                                                            if (!pressed)
                                                                return

                                                            var p = resizeNameMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                                            var dx = p.x - pressSceneX
                                                            root.detailsNameWidth = Math.max(180, startWidth + dx)

                                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                                fileViewLoader.item.relayout()
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: dateHeader
                                                x: root.detailsNameWidth
                                                y: 0
                                                width: root.detailsDateWidth
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
                                                    spacing: 6

                                                    Text {
                                                        text: "Date modified"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }

                                                    AppIcon {
                                                        visible: root.sortColumn === 1
                                                        name: root.sortAscending ? "keyboard-arrow-up" : "keyboard-arrow-down"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 12
                                                    }
                                                }

                                                MouseArea {
                                                    id: dateHeaderMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.sortFiles(1)
                                                }

                                                Rectangle {
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: 8
                                                    color: resizeDateMouse.pressed ? Theme.AppTheme.accent : resizeDateMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

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
                                                            startWidth = root.detailsDateWidth
                                                        }

                                                        onPositionChanged: function(mouse) {
                                                            if (!pressed)
                                                                return

                                                            var p = resizeDateMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                                            var dx = p.x - pressSceneX
                                                            root.detailsDateWidth = Math.max(160, startWidth + dx)

                                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                                fileViewLoader.item.relayout()
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: typeHeader
                                                x: root.detailsNameWidth + root.detailsDateWidth
                                                y: 0
                                                width: root.detailsTypeWidth
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
                                                    spacing: 6

                                                    Text {
                                                        text: "Type"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }

                                                    AppIcon {
                                                        visible: root.sortColumn === 2
                                                        name: root.sortAscending ? "keyboard-arrow-up" : "keyboard-arrow-down"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 12
                                                    }
                                                }

                                                MouseArea {
                                                    id: typeHeaderMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.sortFiles(2)
                                                }

                                                Rectangle {
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: 8
                                                    color: resizeTypeMouse.pressed ? Theme.AppTheme.accent : resizeTypeMouse.containsMouse ? Theme.AppTheme.hover : "transparent"

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
                                                            startWidth = root.detailsTypeWidth
                                                        }

                                                        onPositionChanged: function(mouse) {
                                                            if (!pressed)
                                                                return

                                                            var p = resizeTypeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                                            var dx = p.x - pressSceneX
                                                            root.detailsTypeWidth = Math.max(140, startWidth + dx)

                                                            if (fileViewLoader.item && fileViewLoader.item.relayout)
                                                                fileViewLoader.item.relayout()
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: sizeHeader
                                                x: root.detailsNameWidth + root.detailsDateWidth + root.detailsTypeWidth
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
                                                    spacing: 6

                                                    Text {
                                                        text: "Size"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }

                                                    AppIcon {
                                                        visible: root.sortColumn === 3
                                                        name: root.sortAscending ? "keyboard-arrow-up" : "keyboard-arrow-down"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 12
                                                    }
                                                }

                                                MouseArea {
                                                    id: sizeHeaderMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: root.sortFiles(3)
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
                                                if (root.currentViewMode === "Details")
                                                    return detailsViewComponent
                                                if (root.currentViewMode === "Tiles")
                                                    return tilesViewComponent
                                                if (root.currentViewMode === "Compact")
                                                    return compactViewComponent
                                                if (root.currentViewMode === "Large icons")
                                                    return largeIconsViewComponent
                                                return detailsViewComponent
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: previewSplitter
                                    visible: root.previewEnabled
                                    Layout.preferredWidth: root.previewEnabled ? 8 : 0
                                    Layout.minimumWidth: root.previewEnabled ? 8 : 0
                                    Layout.maximumWidth: root.previewEnabled ? 8 : 0
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
                                            startWidth = root.previewPaneWidth
                                        }

                                        onPositionChanged: function(mouse) {
                                            if (!pressed)
                                                return

                                            var p = previewResizeMouse.mapToItem(contentPane, mouse.x, mouse.y)
                                            var dx = p.x - pressSceneX

                                            var maxAllowed = Math.max(
                                                root.previewPaneMinWidth,
                                                Math.min(root.previewPaneMaxWidth, contentPane.width - 220)
                                            )

                                            root.previewPaneWidth = Math.max(
                                                root.previewPaneMinWidth,
                                                Math.min(maxAllowed, startWidth - dx)
                                            )
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: root.previewEnabled
                                    Layout.preferredWidth: root.previewEnabled ? root.previewPaneWidth : 0
                                    Layout.minimumWidth: root.previewEnabled ? root.previewPaneWidth : 0
                                    Layout.maximumWidth: root.previewEnabled ? root.previewPaneWidth : 0
                                    Layout.fillHeight: true
                                    color: Theme.AppTheme.isDark ? "#141920" : "#fbfcfd"
                                    border.color: Theme.AppTheme.borderSoft
                                    border.width: 1

                                    Flickable {
                                        id: previewFlick
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.topMargin: 12
                                        anchors.bottomMargin: 12
                                        anchors.rightMargin: 6
                                        clip: true
                                        contentWidth: width
                                        contentHeight: previewColumn.implicitHeight

                                        ScrollBar.vertical: ExplorerScrollbarV { darkTheme: Theme.AppTheme.isDark }

                                        Column {
                                            id: previewColumn
                                            width: Math.max(0, previewFlick.width - 20)
                                            spacing: 12

                                            Text {
                                                text: "Preview"
                                                color: Theme.AppTheme.text
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 180
                                                radius: 12
                                                color: Theme.AppTheme.isDark ? "#1b2230" : "#f4f7fb"
                                                border.color: Theme.AppTheme.borderSoft
                                                border.width: 1

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    visible: !root.previewData.visible

                                                    AppIcon {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        name: "preview"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 42
                                                        iconOpacity: 0.55
                                                    }

                                                    Text {
                                                        text: "Select an item to preview"
                                                        color: Theme.AppTheme.muted
                                                        font.pixelSize: 12
                                                    }
                                                }

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    visible: root.previewData.visible

                                                    AppIcon {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        name: root.previewData.icon || "insert-drive-file"
                                                        darkTheme: Theme.AppTheme.isDark
                                                        iconSize: 52
                                                    }

                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: root.previewData.previewType === "multi"
                                                              ? "Multiple items"
                                                              : root.previewData.previewType === "image"
                                                                ? "Mock image preview"
                                                                : root.previewData.previewType === "text"
                                                                  ? "Mock text preview"
                                                                  : root.previewData.previewType === "document"
                                                                    ? "Mock document preview"
                                                                    : root.previewData.previewType === "audio"
                                                                      ? "Mock audio preview"
                                                                      : root.previewData.previewType === "video"
                                                                        ? "Mock video preview"
                                                                        : root.previewData.previewType === "archive"
                                                                          ? "Mock archive preview"
                                                                          : root.previewData.previewType === "folder"
                                                                            ? "Mock folder preview"
                                                                            : "Mock file preview"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                    }

                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: "Backend-driven placeholder"
                                                        color: Theme.AppTheme.muted
                                                        font.pixelSize: 11
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: root.previewData.visible
                                                width: parent.width
                                                text: root.previewData.name || ""
                                                color: Theme.AppTheme.text
                                                font.pixelSize: 14
                                                font.bold: true
                                                wrapMode: Text.Wrap
                                            }

                                            Text {
                                                visible: root.previewData.visible
                                                width: parent.width
                                                text: root.previewData.type || ""
                                                color: Theme.AppTheme.muted
                                                font.pixelSize: 12
                                                wrapMode: Text.Wrap
                                            }

                                            Text {
                                                visible: root.previewData.visible && root.previewData.summary !== ""
                                                width: parent.width
                                                text: root.previewData.summary || ""
                                                color: Theme.AppTheme.text
                                                font.pixelSize: 12
                                                wrapMode: Text.Wrap
                                            }

                                            Rectangle {
                                                visible: root.previewData.visible
                                                width: parent.width
                                                height: 1
                                                color: Theme.AppTheme.borderSoft
                                            }

                                            Column {
                                                visible: root.previewData.visible
                                                width: parent.width
                                                spacing: 6

                                                Text {
                                                    text: "Details"
                                                    color: Theme.AppTheme.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }

                                                Row {
                                                    spacing: 6

                                                    Text {
                                                        text: "Modified:"
                                                        color: Theme.AppTheme.muted
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }

                                                    Text {
                                                        text: root.previewData.dateModified || "—"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                Row {
                                                    spacing: 6

                                                    Text {
                                                        text: "Size:"
                                                        color: Theme.AppTheme.muted
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }

                                                    Text {
                                                        text: root.previewData.size || "—"
                                                        color: Theme.AppTheme.text
                                                        font.pixelSize: 11
                                                    }
                                                }
                                            }

                                            Column {
                                                visible: root.previewData.visible
                                                width: parent.width
                                                spacing: 6

                                                Text {
                                                    text: "Mock content"
                                                    color: Theme.AppTheme.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }

                                                Repeater {
                                                    model: root.previewData.lines ? root.previewData.lines : []

                                                    delegate: Text {
                                                        required property var modelData
                                                        width: previewColumn.width
                                                        text: "• " + modelData
                                                        color: Theme.AppTheme.muted
                                                        font.pixelSize: 11
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
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        text: root.selectedFileCount() > 0
                                              ? (filesModel.rowCount + " items   " + root.selectedFileCount() + " selected")
                                              : (filesModel.rowCount + " items")
                                        color: Theme.AppTheme.muted
                                        font.pixelSize: 11
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
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: root.currentViewMode === "Large icons"
                                                  ? "grid-view"
                                                  : root.currentViewMode === "Tiles"
                                                    ? "tile-view"
                                                    : root.currentViewMode === "Details"
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

                                            onClicked: viewModeMenu.popup()

                                            onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton)
                                                    viewModeMenu.popup()
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
                                        border.width: 1

                                        AppIcon {
                                            anchors.centerIn: parent
                                            name: "notifications"
                                            darkTheme: Theme.AppTheme.isDark
                                            iconSize: 13
                                            iconOpacity: 0.8
                                        }

                                        Rectangle {
                                            visible: notificationsModel.count > 0
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
                                                    root.contentItem,
                                                    notificationsButton.width - notificationsPopup.width,
                                                    -notificationsPopup.height - 8
                                                )
                                                notificationsPopup.x = p.x
                                                notificationsPopup.y = p.y
                                                notificationsPopup.open()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 16
            anchors.bottomMargin: root.notificationOverlayBottomOffset
            width: 340
            height: parent.height
            z: 999

            Column {
                id: toastColumn
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 10

                Repeater {
                    id: toastRepeater
                    model: notificationsModel

                    delegate: NotificationCard {
                        required property var modelData
                        required property int index

                        darkTheme: Theme.AppTheme.isDark
                        notificationId: modelData.notificationId
                        title: modelData.title
                        kind: modelData.kind
                        progress: modelData.progress
                        autoClose: modelData.autoClose
                        done: modelData.done

                        onCloseRequested: function(notificationId) {
                            root.removeNotification(notificationId)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.resizeMargin
        cursorShape: Qt.SizeVerCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.TopEdge)
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.resizeMargin
        cursorShape: Qt.SizeVerCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.BottomEdge)
    }

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.resizeMargin
        cursorShape: Qt.SizeHorCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.LeftEdge)
    }

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.resizeMargin
        cursorShape: Qt.SizeHorCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.RightEdge)
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        width: root.resizeMargin
        height: root.resizeMargin
        cursorShape: Qt.SizeFDiagCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
    }

    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        width: root.resizeMargin
        height: root.resizeMargin
        cursorShape: Qt.SizeBDiagCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.TopEdge | Qt.RightEdge)
    }

    MouseArea {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.resizeMargin
        height: root.resizeMargin
        cursorShape: Qt.SizeBDiagCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
    }

    MouseArea {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.resizeMargin
        height: root.resizeMargin
        cursorShape: Qt.SizeFDiagCursor
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }

    Item {
        id: fileDragPreview
        x: -10000
        y: -10000
        width: Math.min(260, previewContent.implicitWidth + 20)
        height: 42
        visible: true
        opacity: 0.01

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Theme.AppTheme.isDark ? "#1b2230" : "#ffffff"
            border.color: Theme.AppTheme.border
            border.width: 1
        }

        Row {
            id: previewContent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 8

            AppIcon {
                name: root.draggedFileIcon !== "" ? root.draggedFileIcon : "insert-drive-file"
                darkTheme: Theme.AppTheme.isDark
                iconSize: 20
            }

            Text {
                text: root.draggedFileCount > 1
                      ? (root.draggedFileCount + " items")
                      : root.draggedFileName
                color: Theme.AppTheme.text
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                width: 210
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Timer {
        id: tabAutoScrollTimer
        interval: 24
        repeat: true
        onTriggered: {
            if (root.tabAutoScrollDirection === 0 || !root.tabDragActive)
                return

            root.scrollTabsBy(root.tabAutoScrollDirection * 8)
        }
    }

    Timer {
        id: deleteProgressTimer
        property int notificationId: -1
        property int progressValue: 0
        interval: 250
        repeat: true

        onTriggered: {
            progressValue += 10
            root.updateNotificationProgress(notificationId, progressValue, "Delete completed successfully")
            if (progressValue >= 100)
                stop()
        }
    }

    Component.onCompleted: {
        Theme.AppTheme.mode = root.themeMode

        applySnapshot(backend.bootstrap())

        if (!pathField.text || pathField.text === "")
            syncPathField()

        refreshPreviewSelection()
    }

    MouseArea {
        anchors.fill: parent
        z: 10000
        visible: root.editingPath
        enabled: root.editingPath
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: false

        onPressed: function(mouse) {
            var p = mapToItem(pathBar, mouse.x, mouse.y)
            var insidePathBar = p.x >= 0 && p.y >= 0 && p.x < pathBar.width && p.y < pathBar.height

            if (!insidePathBar) {
                root.finishPathEditing(false)
                mouse.accepted = false
                return
            }

            mouse.accepted = false
        }
    }
}


