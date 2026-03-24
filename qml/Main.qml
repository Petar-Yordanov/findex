import QtQuick
import QtQuick.Window
import "components/foundation"
import "components/theme" as Theme
import "features/files"
import "shared/layout" as Layout
import "shared/runtime" as Runtime
import "shared/popups"

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

    property var backend: fileManagerBridge

    onThemeModeChanged: Theme.AppTheme.mode = themeMode

    Runtime.AppModels {
        id: appModels
    }

    Runtime.AppOverlays {
        id: overlays
        anchors.fill: parent
        z: 2000
        rootWindow: root
        notificationsModel: appModels.notificationsModel
    }

    ListModel {
        id: toastModel
    }

    property alias notificationsModel: appModels.notificationsModel
    property alias tabsModel: appModels.tabsModel
    property alias pathModel: appModels.pathModel
    property alias sidebarModel: appModels.sidebarModel
    property alias drivesModel: appModels.drivesModel
    property alias filesModel: appModels.filesModel

    property alias createMenu: overlays.createMenu
    property alias moreActionsMenu: overlays.moreActionsMenu
    property alias confirmDialog: overlays.confirmDialog
    property alias notificationsPopup: overlays.notificationsPopup
    property alias searchScopeMenu: overlays.searchScopeMenu
    property alias breadcrumbContextMenu: overlays.breadcrumbContextMenu
    property alias emptyAreaContextMenu: overlays.emptyAreaContextMenu
    property alias tabContextMenu: overlays.tabContextMenu
    property alias sidebarContextMenu: overlays.sidebarContextMenu
    property alias fileRowContextMenu: overlays.fileRowContextMenu
    property alias multiFileContextMenu: overlays.multiFileContextMenu
    property alias fileAreaContextMenu: overlays.fileAreaContextMenu
    property alias viewModeMenu: overlays.viewModeMenu
    property alias themeMenu: overlays.themeMenu

    property int notificationOverlayBottomOffset: notificationsPopup.visible ? (notificationsPopup.height + 52) : 40
    property var tabAutoScrollTimerRef: tabAutoScrollTimer

    property bool tabDragActive: false
    property bool tabPressActive: false

    property int currentTab: 1
    property int currentFileRow: 0
    property bool editingPath: false
    property string currentSearch: ""

    property string themeMode: backend && backend.savedTheme ? backend.savedTheme() : "Light"
    property string searchScope: backend && backend.savedSearchScope ? backend.savedSearchScope() : "folder"
    property string currentViewMode: backend && backend.savedViewMode ? backend.savedViewMode() : "Details"
    property bool previewEnabled: backend && backend.savedPreviewEnabled ? backend.savedPreviewEnabled() : true
    property bool showHiddenFiles: backend && backend.savedShowHiddenFiles ? backend.savedShowHiddenFiles() : false

    property int contextTabIndex: -1
    property int contextFileRow: -1
    property string contextSidebarLabel: ""
    property string contextSidebarKind: ""
    property string contextSidebarIcon: ""
    property string selectedSidebarLabel: "Local Disk (C:)"
    property string selectedSidebarKind: "drive"

    property int resizeMargin: visibility === Window.Maximized ? 0 : Theme.Metrics.spacingSm

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

    property int contextBreadcrumbIndex: -1

    property int tabWidth: 210
    property int tabSpacing: Theme.Metrics.spacingSm
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

    function navigationBarRef() {
        return appShell && appShell.navigationBarRef ? appShell.navigationBarRef : null
    }

    function titleBarRef() {
        return appShell && appShell.titleBarRef ? appShell.titleBarRef : null
    }

    function pathFieldRef() {
        var nav = navigationBarRef()
        return nav && nav.pathFieldRef ? nav.pathFieldRef : nullf
    }

    function pathBarRef() {
        var nav = navigationBarRef()
        return nav && nav.pathBarRef ? nav.pathBarRef : null
    }

    function tabFlickRef() {
        var titleBar = titleBarRef()
        return titleBar && titleBar.tabFlickRef ? titleBar.tabFlickRef : null
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

    function startTestProgressNotification() {
        deleteProgressTimer.stop()
        deleteProgressTimer.progressValue = 0
        deleteProgressTimer.notificationId = addProgressNotification("Moving files...", 0)
        deleteProgressTimer.start()
    }

    function finishPathEditing(acceptTypedPath) {
        if (!editingPath)
            return

        var pf = pathFieldRef()

        if (acceptTypedPath) {
            editingPath = false
            applySnapshot(backend.navigateToPathString(pf ? pf.text : ""))
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

        if (snapshot.message)
            console.log("notification message:", snapshot.message)

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

        // if (snapshot.sidebar !== undefined)
        //     sidebarModel.rows = toJsArray(snapshot.sidebar)

        if (snapshot.files !== undefined) {
            filesModel.rows = toJsArray(snapshot.files)

            if (filesModel.rows.length === 0) {
                clearFileSelection()
                currentFileRow = -1
                selectionAnchorRow = -1
            } else if (currentFileRow >= filesModel.rows.length) {
                currentFileRow = filesModel.rows.length - 1
            }
        }

        if (snapshot.currentTab !== undefined)
            currentTab = snapshot.currentTab

        if (snapshot.pathText !== undefined) {
            var pf = pathFieldRef()
            if (pf)
                pf.text = snapshot.pathText
        }

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
            if (root.enabled && root.tooltipText !== "")
                buttonTooltip.shown = true
        }
    }

    BaseTooltip {
        id: buttonTooltip
        text: root.tooltipText
        darkTheme: Theme.AppTheme.isDark
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
        var flick = tabFlickRef()
        if (!flick)
            return

        var maxX = Math.max(0, flick.contentWidth - flick.width)
        flick.contentX = Math.max(0, Math.min(maxX, flick.contentX + delta))
    }

    function ensureTabVisible(index) {
        var flick = tabFlickRef()
        if (!flick || index < 0 || index >= tabsModel.count)
            return

        var left = index * (tabWidth + tabSpacing)
        var right = left + tabWidth
        var viewLeft = flick.contentX
        var viewRight = flick.contentX + flick.width

        if (left < viewLeft)
            flick.contentX = left
        else if (right > viewRight)
            flick.contentX = right - flick.width
    }

    function addToastNotification(message, kind) {
        var id = nextNotificationId++
        var level = kind || "info"

        notificationsModel.append({
            notificationId: id,
            title: message,
            kind: level,
            progress: -1,
            autoClose: true,
            done: true
        })

        toastModel.append({
            toastId: id,
            title: message,
            kind: level,
            duration: 5000
        })

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
        for (var i = 0; i <= index; ++i) {
            parts.push({
                label: pathModel.get(i).label,
                icon: pathModel.get(i).icon
            })
        }

        navigateToPath(parts)
    }

    function syncPathField() {
        var pf = pathFieldRef()
        if (!pf)
            return

        var parts = []
        for (var i = 0; i < pathModel.count; ++i)
            parts.push(pathModel.get(i).label)

        if (parts.length === 0) {
            pf.text = ""
            return
        }

        var first = parts[0]

        if (/^[A-Z]:$/.test(first))
            pf.text = first + "/" + parts.slice(1).join("/")
        else
            pf.text = parts.join("/")
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

    Layout.AppShell {
        id: appShell
        anchors.fill: parent
        z: 0

        rootWindow: root

        tabsModel: root.tabsModel
        pathModel: root.pathModel
        sidebarModel: root.sidebarModel
        drivesModel: root.drivesModel
        filesModel: root.filesModel

        createMenu: root.createMenu
        moreActionsMenu: root.moreActionsMenu
        viewModeMenu: root.viewModeMenu
        themeMenu: root.themeMenu
        searchScopeMenu: root.searchScopeMenu
        breadcrumbContextMenu: root.breadcrumbContextMenu
        fileRowContextMenu: root.fileRowContextMenu
        multiFileContextMenu: root.multiFileContextMenu
        emptyAreaContextMenu: root.emptyAreaContextMenu
        sidebarContextMenu: root.sidebarContextMenu
        notificationsPopup: root.notificationsPopup
        notificationsModel: root.notificationsModel
    }

    ToastOverlay {
        id: toastOverlay
        anchors.fill: parent
        z: 1800
        rootWindow: root
        toastsModel: toastModel
    }

    Layout.WindowResizeHandles {
        anchors.fill: parent
        z: 1500
        rootWindow: root
    }

    FileDragPreview {
        id: fileDragPreview
        rootWindow: root
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
        console.log("before bootstrap:",
                    "tabs=", tabsModel ? tabsModel.count : "undef",
                    "drives=", drivesModel ? drivesModel.count : "undef",
                    "files=", (filesModel && filesModel.rows) ? filesModel.rows.length : "undef")

        var snapshot = backend.bootstrap()
        applySnapshot(snapshot)

        var pf = pathFieldRef()
        if (pf && (!pf.text || pf.text === ""))
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
            var bar = pathBarRef()

            if (!bar) {
                root.finishPathEditing(false)
                mouse.accepted = false
                return
            }

            var p = mapToItem(bar, mouse.x, mouse.y)
            var insidePathBar = p.x >= 0 && p.y >= 0 && p.x < bar.width && p.y < bar.height

            if (!insidePathBar) {
                root.finishPathEditing(false)
                mouse.accepted = false
                return
            }

            mouse.accepted = false
        }
    }
}