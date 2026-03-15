import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml.Models
import Qt.labs.qmlmodels as Labs
import Qt5Compat.GraphicalEffects

Window {
    id: root
    width: 1400
    height: 860
    visible: true
    title: "File Explorer"
    color: bg
    flags: Qt.Window
         | Qt.FramelessWindowHint
         | Qt.WindowMinMaxButtonsHint
         | Qt.WindowCloseButtonHint
    minimumWidth: 980
    minimumHeight: 640

    property string themeMode: "Light" // Dark | Light | System
    property bool darkTheme: themeMode === "System" ? false : themeMode === "Dark"

    property color bg: darkTheme ? "#0f1115" : "#f3f4f6"
    property color titleBg: darkTheme ? "#14171d" : "#eceef1"
    property color surface: darkTheme ? "#171b22" : "#f7f7f8"
    property color surface2: darkTheme ? "#161b22" : "#f1f2f4"
    property color surface3: darkTheme ? "#11161d" : "#ffffff"
    property color border: darkTheme ? "#252b36" : "#d7dbe1"
    property color borderSoft: darkTheme ? "#1d232c" : "#e4e7ec"
    property color text: darkTheme ? "#edf1f7" : "#1f2329"
    property color muted: darkTheme ? "#9aa4b2" : "#6b7280"
    property color hover: darkTheme ? "#212835" : "#e9edf3"
    property color pressed: darkTheme ? "#2c3646" : "#dde4ee"
    property color accent: "#4c82f7"
    property color selected: darkTheme ? "#2c3544" : "#dfe9f8"
    property color selectedSoft: darkTheme ? "#202837" : "#eef3fb"
    property color driveUsedBlue: "#3f73f1"
    property color driveUsedRed: "#df5c5c"
    property color driveFree: darkTheme ? "#4b5563" : "#d4d8de"
    property color scrollbarThumb: darkTheme ? "#8f98a7" : "#b8c0cb"
    property color scrollbarThumbHover: darkTheme ? "#a0a9b8" : "#9ea8b6"
    property color scrollbarThumbPressed: darkTheme ? "#b0b8c6" : "#8d98a8"
    property color scrollbarTrack: darkTheme ? "transparent" : "#eef1f5"
    property int notificationOverlayBottomOffset: notificationsPopup.visible ? (notificationsPopup.height + 52) : 40

    property bool tabDragActive: false

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

    ListModel {
        id: notificationsModel
    }

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

    property int detailsRowHeight: 34

    property var selectedFileRows: ({})
    property int selectionAnchorRow: -1

    property bool detailsSelectionActive: false
    property bool detailsSelectionMoved: false
    property real detailsSelectionStartX: 0
    property real detailsSelectionStartY: 0
    property real detailsSelectionCurrentX: 0
    property real detailsSelectionCurrentY: 0

    property int editingFileRow: -1
    property string editingFileNameDraft: ""

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

        var rows = filesModel.rows.slice(0)
        var entry = Object.assign({}, rows[row])
        entry.name = trimmed
        rows[row] = entry
        filesModel.rows = rows

        editingFileRow = -1
        editingFileNameDraft = ""
    }

    function cancelRenameRow() {
        editingFileRow = -1
        editingFileNameDraft = ""
    }

    function addNewFolder() {
        var rows = filesModel.rows.slice(0)
        rows.unshift({
            "name": uniqueName("New folder", ""),
            "dateModified": currentDateTimeString(),
            "type": "File folder",
            "size": "",
            "icon": "assets/icons/folder.svg"
        })
        filesModel.rows = rows
        beginRenameRow(0)
    }

    function addNewFile() {
        var rows = filesModel.rows.slice(0)
        rows.unshift({
            "name": uniqueName("New file", ".txt"),
            "dateModified": currentDateTimeString(),
            "type": "Text Document",
            "size": "0 KB",
            "icon": "assets/icons/description.svg"
        })
        filesModel.rows = rows
        beginRenameRow(0)
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

        var label = draggedFileCount === 1
                ? ("\"" + draggedFileName + "\"")
                : (draggedFileCount + " items")

        addToastNotification(
            "Moved " + label + " to " + targetLabel,
            "success"
        )

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
        while (pathModel.count > 0)
            pathModel.remove(pathModel.count - 1)

        for (var i = 0; i < parts.length; ++i) {
            pathModel.append({
                label: parts[i].label,
                icon: parts[i].icon || (i === 0 ? "assets/icons/hard-drive.svg" : "assets/icons/folder.svg")
            })
        }

        syncPathField()
        editingPath = false

        var currentLabel = pathModel.get(pathModel.count - 1).label
        renameTab(currentTab, currentLabel)

        addToastNotification("Navigated to " + pathField.text, "info")

        // TODO: reload filesModel for this path
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

    function addTab(titleText) {
        tabsModel.append({ title: titleText, icon: "assets/icons/folder.svg" })
        currentTab = tabsModel.count - 1
        Qt.callLater(function() {
            ensureTabVisible(currentTab)
        })
    }

    function closeTab(index) {
        if (tabsModel.count <= 1 || index < 0 || index >= tabsModel.count)
            return
        tabsModel.remove(index)
        if (currentTab >= tabsModel.count)
            currentTab = tabsModel.count - 1
        if (currentTab < 0)
            currentTab = 0
    }

    function renameTab(index, newTitle) {
        if (index >= 0 && index < tabsModel.count)
            tabsModel.setProperty(index, "title", newTitle)
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

    function openLocation(label, iconText, kind) {
        while (pathModel.count > 0)
            pathModel.remove(pathModel.count - 1)

        var driveMatch = label.match(/\(([A-Z]:)\)$/)
        if (kind === "drive" && driveMatch) {
            pathModel.append({ label: driveMatch[1], icon: iconText })
        } else if (label === "Home") {
            pathModel.append({ label: "Home", icon: iconText })
        } else {
            pathModel.append({ label: label, icon: iconText })
        }

        selectedSidebarLabel = label
        selectedSidebarKind = kind || ""

        syncPathField()
        editingPath = false
    }

    function enterFolder(folderName) {
        var parts = []
        for (var i = 0; i < pathModel.count; ++i) {
            parts.push({
                label: pathModel.get(i).label,
                icon: pathModel.get(i).icon
            })
        }

        parts.push({ label: folderName, icon: "assets/icons/folder.svg" })
        navigateToPath(parts)
    }

    function fileRowValue(row, key) {
        var r = filesModel.rows[row]
        return r && r[key] !== undefined ? r[key] : ""
    }

    function viewModeIcon(mode) {
        if (mode === "Details")
            return "assets/icons/detailed-view.svg"
        if (mode === "Tiles")
            return "assets/icons/tile-view.svg"
        if (mode === "Compact")
            return "assets/icons/list-view.svg"
        if (mode === "Large icons")
            return "assets/icons/grid-view.svg"
        return "assets/icons/list-view.svg"
    }

    ListModel {
        id: tabsModel
        ListElement { title: "Home"; icon: "assets/icons/home.svg" }
        ListElement { title: "Local Disk (C:)"; icon: "assets/icons/hard-drive.svg" }
    }

    ListModel {
        id: pathModel
        ListElement { label: "C:"; icon: "assets/icons/hard-drive.svg" }
        ListElement { label: "Projects"; icon: "assets/icons/folder.svg" }
        ListElement { label: "Qt"; icon: "assets/icons/folder.svg" }
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
                    { label: "Recent", icon: "assets/icons/history.svg", kind: "quick", section: false },
                    { label: "Home", icon: "assets/icons/home.svg", kind: "quick", section: false },
                    { label: "Desktop", icon: "assets/icons/desktop-windows.svg", kind: "quick", section: false },
                    { label: "Downloads", icon: "assets/icons/download.svg", kind: "quick", section: false },
                    { label: "Documents", icon: "assets/icons/description.svg", kind: "quick", section: false },
                    { label: "Pictures", icon: "assets/icons/image.svg", kind: "quick", section: false },
                    { label: "Music", icon: "assets/icons/music-note.svg", kind: "quick", section: false },
                    { label: "Videos", icon: "assets/icons/movie.svg", kind: "quick", section: false },
                ]
            }
        ]
    }

    ListModel {
        id: drivesModel
        ListElement {
            label: "Local Disk (C:)"
            icon: "assets/icons/hard-drive.svg"
            used: 0.5
            total: 1.0
            usedText: "0.5 TB used of 1 TB"
        }
        ListElement {
            label: "Data (D:)"
            icon: "assets/icons/storage.svg"
            used: 0.37
            total: 1.0
            usedText: "0.37 TB used of 1 TB"
        }
        ListElement {
            label: "Backup (E:)"
            icon: "assets/icons/save.svg"
            used: 0.91
            total: 1.0
            usedText: "0.91 TB used of 1 TB"
        }
        ListElement {
            label: "USB Drive (F:)"
            icon: "assets/icons/usb.svg"
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
            { "name": "Backup", "dateModified": "13/02/2026 12:01", "type": "File folder", "size": "", "icon": "assets/icons/folder.svg" },
            { "name": "Games", "dateModified": "06/03/2026 21:58", "type": "File folder", "size": "", "icon": "assets/icons/folder.svg" },
            { "name": "inetpub", "dateModified": "07/02/2026 22:34", "type": "File folder", "size": "", "icon": "assets/icons/folder.svg" },
            { "name": "Program Files", "dateModified": "06/03/2026 22:07", "type": "File folder", "size": "", "icon": "assets/icons/folder.svg" },
            { "name": "appverifUI.dll", "dateModified": "12/11/2025 15:27", "type": "Application extension", "size": "110 KB", "icon": "assets/icons/insert-drive-file.svg" },
            { "name": "chrome.exe", "dateModified": "03/03/2026 09:14", "type": "Application", "size": "248 MB", "icon": "assets/icons/insert-drive-file.svg" },
            { "name": "readme.txt", "dateModified": "28/02/2026 18:42", "type": "Text Document", "size": "4 KB", "icon": "assets/icons/description.svg" },
            { "name": "meeting-notes.docx", "dateModified": "10/03/2026 11:05", "type": "Microsoft Word Document", "size": "86 KB", "icon": "assets/icons/description.svg" },
            { "name": "budget-2026.xlsx", "dateModified": "14/03/2026 08:51", "type": "Microsoft Excel Worksheet", "size": "214 KB", "icon": "assets/icons/description.svg" },
            { "name": "presentation-q1.pptx", "dateModified": "07/03/2026 16:23", "type": "Microsoft PowerPoint Presentation", "size": "3.8 MB", "icon": "assets/icons/description.svg" },
            { "name": "invoice-1482.pdf", "dateModified": "01/03/2026 13:37", "type": "PDF Document", "size": "512 KB", "icon": "assets/icons/picture-as-pdf.svg" },
            { "name": "hero-banner.png", "dateModified": "11/03/2026 20:16", "type": "PNG File", "size": "1.9 MB", "icon": "assets/icons/image.svg" },
            { "name": "vacation-photo.jpg", "dateModified": "22/02/2026 17:08", "type": "JPEG Image", "size": "4.6 MB", "icon": "assets/icons/image.svg" },
            { "name": "logo-final.svg", "dateModified": "09/03/2026 10:44", "type": "SVG Document", "size": "72 KB", "icon": "assets/icons/image.svg" },
            { "name": "theme-song.mp3", "dateModified": "18/01/2026 21:55", "type": "MP3 File", "size": "8.7 MB", "icon": "assets/icons/music-note.svg" },
            { "name": "launch-trailer.mp4", "dateModified": "13/03/2026 22:11", "type": "MP4 Video", "size": "148 MB", "icon": "assets/icons/movie.svg" },
            { "name": "archive-backup.zip", "dateModified": "05/03/2026 07:30", "type": "Compressed (zipped) Folder", "size": "640 MB", "icon": "assets/icons/zip.svg" },
            { "name": "logs.7z", "dateModified": "27/02/2026 23:03", "type": "7-Zip Archive", "size": "92 MB", "icon": "assets/icons/zip.svg" },
            { "name": "installer.msi", "dateModified": "16/02/2026 14:29", "type": "Windows Installer Package", "size": "27 MB", "icon": "assets/icons/insert-drive-file.svg" },
            { "name": "config.json", "dateModified": "12/03/2026 09:57", "type": "JSON Source File", "size": "12 KB", "icon": "assets/icons/code.svg" },
            { "name": "settings.yaml", "dateModified": "11/03/2026 08:40", "type": "YAML Document", "size": "6 KB", "icon": "assets/icons/code.svg" },
            { "name": "main.cpp", "dateModified": "14/03/2026 10:32", "type": "C++ Source File", "size": "34 KB", "icon": "assets/icons/code.svg" },
            { "name": "mainwindow.qml", "dateModified": "14/03/2026 10:48", "type": "QML File", "size": "58 KB", "icon": "assets/icons/code.svg" },
            { "name": "script.ps1", "dateModified": "06/03/2026 12:19", "type": "PowerShell Script", "size": "9 KB", "icon": "assets/icons/terminal.svg" },
            { "name": "run.bat", "dateModified": "20/02/2026 19:11", "type": "Windows Batch File", "size": "2 KB", "icon": "assets/icons/terminal.svg" },
            { "name": "package-lock.json", "dateModified": "14/03/2026 10:49", "type": "JSON Source File", "size": "418 KB", "icon": "assets/icons/code.svg" },
            { "name": "database.db", "dateModified": "08/03/2026 15:02", "type": "Database File", "size": "19 MB", "icon": "assets/icons/storage.svg" },
            { "name": "font-regular.ttf", "dateModified": "25/01/2026 13:13", "type": "TrueType Font File", "size": "164 KB", "icon": "assets/icons/insert-drive-file.svg" },
            { "name": "shortcut.lnk", "dateModified": "02/03/2026 08:12", "type": "Shortcut", "size": "1 KB", "icon": "assets/icons/launch.svg" },
            { "name": "DumpStack.log", "dateModified": "12/03/2026 12:21", "type": "Log File", "size": "12 KB", "icon": "assets/icons/description.svg" },
            { "name": "notes.md", "dateModified": "14/03/2026 09:26", "type": "Markdown File", "size": "18 KB", "icon": "assets/icons/description.svg" },
            { "name": "design.fig", "dateModified": "04/03/2026 17:46", "type": "FIG File", "size": "28 MB", "icon": "assets/icons/insert-drive-file.svg" },
            { "name": "virtual-disk.vhdx", "dateModified": "21/02/2026 23:58", "type": "Virtual Hard Disk", "size": "18 GB", "icon": "assets/icons/storage.svg" },
            { "name": "certificate.pem", "dateModified": "15/02/2026 06:44", "type": "PEM File", "size": "3 KB", "icon": "assets/icons/lock.svg" },
        ]
    }

    Menu {
        id: emptyAreaContextMenu

        Menu {
            title: "Change view"

            MenuItem { text: "Details"; onTriggered: root.currentViewMode = "Details" }
            MenuItem { text: "Tiles"; onTriggered: root.currentViewMode = "Tiles" }
            MenuItem { text: "Compact"; onTriggered: root.currentViewMode = "Compact" }
            MenuItem { text: "Large icons"; onTriggered: root.currentViewMode = "Large icons" }
        }

        Menu {
            title: "New"

            MenuItem {
                text: "File"
                onTriggered: root.addNewFile()
            }

            MenuItem {
                text: "Folder"
                onTriggered: root.addNewFolder()
            }
        }

        Menu {
            title: "Sort by"

            Menu {
                title: "Name"
                MenuItem { text: "Ascending"; onTriggered: root.sortFilesExplicit(0, true) }
                MenuItem { text: "Descending"; onTriggered: root.sortFilesExplicit(0, false) }
            }

            Menu {
                title: "Date modified"
                MenuItem { text: "Ascending"; onTriggered: root.sortFilesExplicit(1, true) }
                MenuItem { text: "Descending"; onTriggered: root.sortFilesExplicit(1, false) }
            }

            Menu {
                title: "Type"
                MenuItem { text: "Ascending"; onTriggered: root.sortFilesExplicit(2, true) }
                MenuItem { text: "Descending"; onTriggered: root.sortFilesExplicit(2, false) }
            }

            Menu {
                title: "Size"
                MenuItem { text: "Ascending"; onTriggered: root.sortFilesExplicit(3, true) }
                MenuItem { text: "Descending"; onTriggered: root.sortFilesExplicit(3, false) }
            }
        }

        MenuSeparator {}
        MenuItem {
            text: "Select all"
            onTriggered: root.selectAllFiles()
        }
        MenuItem { text: "Properties" }
    }

    Menu {
        id: tabContextMenu

        MenuItem { text: "New tab"; onTriggered: root.addTab("New Tab") }
        MenuItem {
            text: "Close tab"
            enabled: root.contextTabIndex >= 0 && tabsModel.count > 1
            onTriggered: root.closeTab(root.contextTabIndex)
        }
        MenuItem {
            text: "Duplicate tab"
            enabled: root.contextTabIndex >= 0
            onTriggered: {
                if (root.contextTabIndex >= 0)
                    root.addTab(tabsModel.get(root.contextTabIndex).title + " Copy")
            }
        }
        MenuSeparator {}
        MenuItem {
            text: "Rename active tab"
            enabled: root.contextTabIndex >= 0
            onTriggered: {
                if (root.contextTabIndex >= 0)
                    root.renameTab(root.contextTabIndex, tabsModel.get(root.contextTabIndex).title + " Renamed")
            }
        }
    }

    Menu {
        id: createMenu

        MenuItem {
            text: "New folder"
            onTriggered: root.addNewFolder()
        }

        MenuItem {
            text: "New file"
            onTriggered: root.addNewFile()
        }
    }

    Menu {
        id: moreActionsMenu

        MenuItem { text: "Compress" }
        MenuItem { text: "Extract here" }
        MenuItem { text: "Duplicate" }
        MenuSeparator {}

        Menu {
            title: "Open with..."

            MenuItem { text: "Notepad" }
            MenuItem { text: "Visual Studio Code" }
            MenuItem { text: "Qt Creator" }
            MenuItem { text: "Windows Media Player" }
        }

        MenuItem { text: "Copy path" }
        MenuItem { text: "Open in terminal" }
        MenuSeparator {}
        MenuItem {
            text: "Select all"
            onTriggered: root.selectAllFiles()
        }
        MenuItem { text: "Show hidden files" }
        MenuItem { text: "Properties" }
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
            color: darkTheme ? "#1b2230" : "#ffffff"
            border.color: root.border
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
                    color: root.text
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            Rectangle {
                width: parent ? parent.width : 360
                height: 1
                color: root.borderSoft
            }

            Item {
                width: parent ? parent.width : 360
                height: 68

                Text {
                    anchors.fill: parent
                    anchors.margins: 18
                    text: root.confirmDialogMessage
                    color: root.text
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: parent ? parent.width : 360
                height: 1
                color: root.borderSoft
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
                                root.addToastNotification("Deleted successfully", "success")
                            } else if (root.confirmDialogAction === "deleteSelection") {
                                var count = root.selectedFileCount()
                                root.addToastNotification(
                                    count > 1
                                        ? ("Deleted " + count + " items successfully")
                                        : "Deleted successfully",
                                    "success"
                                )
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
                           ? (darkTheme ? "#384355" : "#dce4ef")
                           : noMouse.containsMouse
                             ? root.hover
                             : "transparent"
                    border.color: root.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "No"
                        color: root.text
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

        background: Item {
            implicitWidth: notificationsPopup.width
            implicitHeight: notificationsPopup.height

            DropShadow {
                anchors.fill: popupBg
                source: popupBg
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 25
                color: root.darkTheme ? "#66000000" : "#22000000"
            }

            Rectangle {
                id: popupBg
                anchors.fill: parent
                radius: 12
                color: darkTheme ? "#1b2230" : "#ffffff"
                border.color: root.border
                border.width: 1
            }
        }

        Column {
            anchors.fill: parent
            spacing: 8

            Text {
                text: "Notifications"
                color: root.text
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
                            color: darkTheme ? "#232c3a" : "#f8fafc"
                            border.color: root.borderSoft
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
                                        color: root.text
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: trayCloseMouse.containsMouse ? root.hover : "transparent"

                                        AppIcon {
                                            anchors.centerIn: parent
                                            source: "assets/icons/close.svg"
                                            iconSize: 12
                                            iconColor: root.muted
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
                                    color: root.driveFree

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, modelData.progress / 100))
                                        height: parent.height
                                        radius: 3
                                        color: modelData.done ? root.driveUsedBlue : root.accent
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
            color: darkTheme ? "#1b2230" : "#fcfcfd"
            border.color: root.border
            border.width: 1
        }

        Column {
            anchors.fill: parent
            spacing: 4

            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: folderMouse.containsMouse ? root.hover : "transparent"

                AppIcon {
                    anchors.centerIn: parent
                    source: "assets/icons/folder.svg"
                    iconSize: 16
                    iconColor: root.text
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.searchScope = "folder"
                        searchScopeMenu.close()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: driveMouse.pressed
                       ? root.pressed
                       : driveMouse.containsMouse
                         ? (darkTheme ? "#2a3444" : "#e6eefb")
                         : "transparent"

                AppIcon {
                    anchors.centerIn: parent
                    source: "assets/icons/hard-drive.svg"
                    iconSize: 16
                    iconColor: root.text
                }

                MouseArea {
                    id: driveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.searchScope = "global"
                        searchScopeMenu.close()
                    }
                }
            }
        }
    }

    Menu {
        id: sidebarContextMenu

        MenuItem {
            text: "Open"
            enabled: root.contextSidebarLabel !== ""
            onTriggered: root.openLocation(root.contextSidebarLabel, root.contextSidebarIcon)
        }
        MenuItem {
            text: "Open in new tab"
            enabled: root.contextSidebarLabel !== ""
            onTriggered: root.addTab(root.contextSidebarLabel)
        }
        MenuSeparator {}
        MenuItem { text: "Pin"; enabled: root.contextSidebarKind !== "section" }
        MenuItem { text: "Properties"; enabled: root.contextSidebarKind !== "section" }
    }

    Menu {
        id: fileRowContextMenu

        MenuItem {
            text: "Open"
            enabled: root.contextFileRow >= 0
            onTriggered: {
                if (root.contextFileRow >= 0 && root.fileRowValue(root.contextFileRow, "type") === "File folder")
                    root.enterFolder(root.fileRowValue(root.contextFileRow, "name"))
            }
        }
        MenuItem { text: "Open in new tab" }
        Menu {
            title: "Open with..."

            MenuItem { text: "Notepad" }
            MenuItem { text: "Visual Studio Code" }
            MenuItem { text: "Qt Creator" }
            MenuItem { text: "Windows Media Player" }
            MenuSeparator {}
            MenuItem { text: "Choose another app..." }
        }
        MenuItem {
            text: "Select all"
            onTriggered: root.selectAllFiles()
        }
        MenuSeparator {}
        MenuItem { text: "Cut" }
        MenuItem { text: "Copy" }
        MenuItem {
            text: "Rename"
            enabled: root.contextFileRow >= 0
            onTriggered: root.beginRenameRow(root.contextFileRow)
        }
        MenuSeparator {}
        MenuItem {
            text: "Delete"
            enabled: root.contextFileRow >= 0
            onTriggered: root.askDeleteRow(root.contextFileRow)
        }
        MenuItem { text: "Properties" }
    }

    Menu {
        id: multiFileContextMenu

        MenuItem {
            text: "Open"
            enabled: root.selectedFileCount() > 0
            onTriggered: {
                if (root.selectedFileCount() === 1 && root.currentFileRow >= 0
                        && root.fileRowValue(root.currentFileRow, "type") === "File folder") {
                    root.enterFolder(root.fileRowValue(root.currentFileRow, "name"))
                } else {
                    root.addToastNotification("Opened " + root.selectedFileCount() + " items", "info")
                }
            }
        }

        MenuItem { text: "Open in new tab"; enabled: root.selectedFileCount() === 1 }

        MenuSeparator {}

        MenuItem { text: "Cut"; enabled: root.selectedFileCount() > 0 }
        MenuItem {
            text: "Copy"
            enabled: root.selectedFileCount() > 0
            onTriggered: root.addToastNotification(
                root.selectedFileCount() > 1
                    ? ("Copied " + root.selectedFileCount() + " items")
                    : "Copied successfully to clipboard",
                "success"
            )
        }

        MenuSeparator {}

        MenuItem {
            text: "Delete"
            enabled: root.selectedFileCount() > 0
            onTriggered: root.askDeleteSelection()
        }

        MenuItem {
            text: "Rename"
            enabled: root.selectedFileCount() === 1 && root.currentFileRow >= 0
            onTriggered: root.beginRenameRow(root.currentFileRow)
        }

        MenuSeparator {}

        MenuItem {
            text: "Select all"
            onTriggered: root.selectAllFiles()
        }

        MenuItem {
            text: "Clear selection"
            enabled: root.selectedFileCount() > 0
            onTriggered: root.clearFileSelection()
        }

        MenuSeparator {}

        MenuItem {
            text: "Properties"
            enabled: root.selectedFileCount() > 0
        }
    }

    Menu {
        id: fileAreaContextMenu

        MenuItem {
            text: "New folder"
            onTriggered: root.addNewFolder()
        }

        MenuItem {
            text: "New file"
            onTriggered: root.addNewFile()
        }

        MenuSeparator {}
        MenuItem { text: "Paste" }
        MenuSeparator {}
        MenuItem { text: "Refresh" }
        MenuItem { text: "Properties" }
    }

    Menu {
        id: viewModeMenu

        MenuItem { text: "Details"; onTriggered: root.currentViewMode = "Details" }
        MenuItem { text: "Tiles"; onTriggered: root.currentViewMode = "Tiles" }
        MenuItem { text: "Compact"; onTriggered: root.currentViewMode = "Compact" }
        MenuItem { text: "Large icons"; onTriggered: root.currentViewMode = "Large icons" }
    }

    Menu {
        id: themeMenu

        MenuItem { text: "Dark"; onTriggered: root.themeMode = "Dark" }
        MenuItem { text: "Light"; onTriggered: root.themeMode = "Light" }
        MenuItem { text: "System"; onTriggered: root.themeMode = "System" }
    }

    component NotificationCard : Rectangle {
        id: card

        property int notificationId: -1
        property string title: ""
        property string kind: "info"
        property int progress: -1
        property bool autoClose: false
        property bool done: false

        width: 320
        height: progress >= 0 ? 84 : 58
        radius: 12
        color: darkTheme ? "#1b2230" : "#ffffff"
        border.color: root.border
        border.width: 1

        function restartTimer() {
            if (autoClose)
                closeTimer.restart()
        }

        Timer {
            id: closeTimer
            interval: 2600
            repeat: false
            onTriggered: root.removeNotification(card.notificationId)
        }

        Component.onCompleted: {
            if (autoClose)
                closeTimer.start()
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Row {
                width: parent.width
                spacing: 8

                AppIcon {
                    source: kind === "success"
                            ? "assets/icons/check.svg"
                            : kind === "error"
                              ? "assets/icons/close.svg"
                              : kind === "warning"
                                ? "assets/icons/error.svg"
                                : kind === "progress"
                                  ? "assets/icons/sync.svg"
                                  : "assets/icons/info.svg"
                    iconSize: 16
                    iconColor: root.text
                }

                Text {
                    width: parent.width - 40
                    text: card.title
                    color: root.text
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: progress >= 0 ? 2 : 1
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: closeToastMouse.containsMouse ? root.hover : "transparent"

                    AppIcon {
                        anchors.centerIn: parent
                        source: "assets/icons/close.svg"
                        iconSize: 12
                        iconColor: root.muted
                    }

                    MouseArea {
                        id: closeToastMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.removeNotification(card.notificationId)
                    }
                }
            }

            Rectangle {
                visible: progress >= 0
                width: parent.width
                height: 6
                radius: 3
                color: root.driveFree

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, progress / 100))
                    height: parent.height
                    radius: 3
                    color: done ? root.driveUsedBlue : root.accent
                }
            }

            Text {
                visible: progress >= 0
                text: done ? "Completed" : (progress + "%")
                color: root.muted
                font.pixelSize: 11
            }
        }
    }

    component WindowButton : Rectangle {
        id: wb
        property url iconSource: ""
        property color hoverColor: darkTheme ? "#2c3544" : "#dbe7fb"
        property color pressedColor: darkTheme ? "#39465b" : "#c9daf8"
        property color iconHoverColor: root.text
        signal clicked

        width: 42
        height: 28
        radius: 8
        color: mouse.pressed ? pressedColor : mouse.containsMouse ? hoverColor : "transparent"
        border.color: mouse.containsMouse && !mouse.pressed ? (darkTheme ? "#3b4659" : "#bfd0ef") : "transparent"
        border.width: mouse.containsMouse ? 1 : 0

        AppIcon {
            anchors.centerIn: parent
            source: wb.iconSource
            iconSize: 14
            iconColor: mouse.containsMouse ? wb.iconHoverColor : root.text
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: wb.clicked()
        }
    }

    component IconButton : Rectangle {
        id: ib
        property url iconSource: ""
        property string tooltipText: ""
        signal clicked

        width: 32
        height: 32
        radius: 8
        color: mouse.pressed
               ? (darkTheme ? "#3a475d" : "#cadbf8")
               : mouse.containsMouse
                 ? (darkTheme ? "#2d3748" : "#dce8fb")
                 : "transparent"
        border.color: mouse.containsMouse
                      ? (darkTheme ? "#425066" : "#bfd0ef")
                      : "transparent"
        border.width: mouse.containsMouse ? 1 : 0

        AppIcon {
            anchors.centerIn: parent
            source: ib.iconSource
            iconSize: 18
            iconColor: mouse.containsMouse
                       ? (darkTheme ? "#ffffff" : "#111827")
                       : root.text
        }

        ToolTip.visible: mouse.containsMouse && tooltipText !== ""
        ToolTip.text: tooltipText

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ib.clicked()
        }
    }

    component ExplorerScrollbarV : ScrollBar {
        id: sb
        orientation: Qt.Vertical
        width: 10
        policy: ScrollBar.AsNeeded

        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: sb.pressed ? root.scrollbarThumbPressed
                              : sb.hovered ? root.scrollbarThumbHover
                                           : root.scrollbarThumb
            opacity: darkTheme ? (sb.active ? 0.95 : 0.75)
                               : (sb.active ? 0.9 : 0.8)
        }

        background: Rectangle {
            radius: 3
            color: darkTheme ? "transparent" : root.scrollbarTrack
            opacity: darkTheme ? 0.0 : 1.0
        }
    }

    component ExplorerScrollbarH : ScrollBar {
        id: sb
        orientation: Qt.Horizontal
        height: 10
        policy: ScrollBar.AsNeeded

        contentItem: Rectangle {
            implicitHeight: 6
            radius: 3
            color: sb.pressed ? root.scrollbarThumbPressed
                              : sb.hovered ? root.scrollbarThumbHover
                                           : root.scrollbarThumb
            opacity: darkTheme ? (sb.active ? 0.95 : 0.75)
                               : (sb.active ? 0.9 : 0.8)
        }

        background: Rectangle {
            radius: 3
            color: darkTheme ? "transparent" : root.scrollbarTrack
            opacity: darkTheme ? 0.0 : 1.0
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

                ScrollBar.vertical: ExplorerScrollbarV {}
                ScrollBar.horizontal: ExplorerScrollbarH {}

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
                           ? root.selectedSoft
                           : root.isFileRowSelected(row)
                             ? root.selected
                             : cellMouse.containsMouse ? root.selectedSoft : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 8

                        AppIcon {
                            visible: column === 0
                            source: root.fileRowValue(row, "icon")
                            iconSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                            iconColor: root.text
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
                            color: column === 0 ? root.text : root.muted
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            width: parent.width - (column === 0 ? 28 : 0)
                            horizontalAlignment: Text.AlignLeft
                        }

                        TextField {
                            visible: column === 0 && root.editingFileRow === row
                            width: parent.width - 28
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.editingFileNameDraft
                            color: root.text
                            font.pixelSize: 13
                            selectByMouse: true
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 0
                            bottomPadding: 0

                            background: Rectangle {
                                radius: 6
                                color: root.darkTheme ? "#1b2230" : "#ffffff"
                                border.color: root.accent
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

                            onAccepted: root.commitRenameRow(row, root.editingFileNameDraft)

                            onActiveFocusChanged: {
                                if (!activeFocus && visible)
                                    root.commitRenameRow(row, root.editingFileNameDraft)
                            }

                            Keys.onEscapePressed: root.cancelRenameRow()
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
                            if (root.fileRowValue(row, "type") === "File folder")
                                root.enterFolder(root.fileRowValue(row, "name"))
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
                border.color: root.accent
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

                    ScrollBar.vertical: ExplorerScrollbarV {}
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
                                   ? root.selectedSoft
                                   : root.isFileRowSelected(index)
                                     ? root.selected
                                     : tileMouse.containsMouse ? root.selectedSoft : "transparent"
                            border.color: root.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged
                                          ? root.accent
                                          : "transparent"
                            border.width: root.detailsDropHoverRow === index && tileDelegate.isFolderTarget && !tileDelegate.sameAsDragged ? 1 : 0
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: root.borderSoft
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
                                source: modelData.icon
                                iconSize: 34
                                iconColor: root.text
                            }

                            Column {
                                width: Math.max(220, parent.width - 420)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    visible: root.editingFileRow !== index
                                    text: modelData.name
                                    color: root.text
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                TextField {
                                    visible: root.editingFileRow === index
                                    width: parent.width
                                    height: 26
                                    text: root.editingFileNameDraft
                                    color: root.text
                                    font.pixelSize: 14
                                    selectByMouse: true
                                    leftPadding: 8
                                    rightPadding: 8
                                    topPadding: 0
                                    bottomPadding: 0

                                    background: Rectangle {
                                        radius: 6
                                        color: root.darkTheme ? "#1b2230" : "#ffffff"
                                        border.color: root.accent
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
                                    color: root.muted
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
                                    color: root.text
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: "Size: " + ((modelData.size && modelData.size !== "") ? modelData.size : "—")
                                    color: root.text
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
                                if (modelData.type === "File folder")
                                    root.enterFolder(modelData.name)
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
                        border.color: root.accent
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

                    ScrollBar.vertical: ExplorerScrollbarV {}
                    ScrollBar.horizontal: null

                    delegate: Item {
                        id: compactDelegate
                        required property int index
                        required property var modelData

                        property real pressX: 0
                        property real pressY: 0
                        property bool dragStarted: false

                        width: ListView.view.width
                        height: 30

                        readonly property bool isFolderTarget: modelData.type === "File folder"
                        readonly property bool sameAsDragged: root.isDraggedRow(index)

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: root.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                   ? root.selectedSoft
                                   : root.isFileRowSelected(index)
                                     ? root.selected
                                     : compactMouse.containsMouse ? root.selectedSoft : "transparent"
                            border.color: root.detailsDropHoverRow === index && compactDelegate.isFolderTarget && !compactDelegate.sameAsDragged
                                          ? root.accent
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
                                source: modelData.icon
                                iconSize: 14
                                iconColor: root.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                visible: root.editingFileRow !== index
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: root.text
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
                                color: root.text
                                font.pixelSize: 13
                                selectByMouse: true
                                leftPadding: 8
                                rightPadding: 8
                                topPadding: 0
                                bottomPadding: 0

                                background: Rectangle {
                                    radius: 6
                                    color: root.darkTheme ? "#1b2230" : "#ffffff"
                                    border.color: root.accent
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
                                if (modelData.type === "File folder")
                                    root.enterFolder(modelData.name)
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
                        border.color: root.accent
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

                ScrollBar.vertical: ExplorerScrollbarV {}
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
                           ? root.selectedSoft
                           : root.isFileRowSelected(index)
                             ? root.selected
                             : gridMouse.containsMouse ? root.selectedSoft : "transparent"
                    border.color: root.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged
                                  ? root.accent
                                  : "transparent"
                    border.width: root.detailsDropHoverRow === index && gridDelegate.isFolderTarget && !gridDelegate.sameAsDragged ? 1 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        AppIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: modelData.icon
                            iconSize: 28
                            iconColor: root.text
                        }

                        Text {
                            visible: root.editingFileRow !== index
                            width: 88
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            text: modelData.name
                            color: root.text
                            font.pixelSize: 12
                        }

                        TextField {
                            visible: root.editingFileRow === index
                            width: 88
                            height: 24
                            text: root.editingFileNameDraft
                            color: root.text
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            leftPadding: 6
                            rightPadding: 6
                            topPadding: 0
                            bottomPadding: 0

                            background: Rectangle {
                                radius: 6
                                color: root.darkTheme ? "#1b2230" : "#ffffff"
                                border.color: root.accent
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

                        onClicked: function(mouse) {
                            mouse.accepted = true
                        }

                        onPressed: function(mouse) {
                            gridDelegate.pressX = mouse.x
                            gridDelegate.pressY = mouse.y
                            gridDelegate.dragStarted = false
                            dragProxy.x = mouse.x - 12
                            dragProxy.y = mouse.y - 12

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
                            }
                        }

                        onPositionChanged: function(mouse) {
                            if (!(pressedButtons & Qt.LeftButton))
                                return

                            dragProxy.x = mouse.x - 12
                            dragProxy.y = mouse.y - 12

                            if (!gridDelegate.dragStarted) {
                                var dx = mouse.x - gridDelegate.pressX
                                var dy = mouse.y - gridDelegate.pressY
                                if ((dx * dx + dy * dy) >= 36 && root.isFileRowSelected(index)) {
                                    root.beginFileDrag(index)
                                    gridDelegate.dragStarted = true
                                }
                            }
                        }

                        onDoubleClicked: {
                            if (modelData.type === "File folder")
                                root.enterFolder(modelData.name)
                        }

                        onReleased: {
                            dragProxy.x = 0
                            dragProxy.y = 0
                            gridDelegate.dragStarted = false
                            root.detailsDropHoverRow = -1
                            root.clearFileDrag()
                        }

                        onCanceled: {
                            dragProxy.x = 0
                            dragProxy.y = 0
                            gridDelegate.dragStarted = false
                            root.detailsDropHoverRow = -1
                            root.clearFileDrag()
                        }

                        Item {
                            id: dragProxy
                            x: 0
                            y: 0
                            width: 24
                            height: 24
                            opacity: 0.01

                            Drag.active: gridDelegate.dragStarted
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
                                gridDelegate.dragStarted = false
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
                    border.color: root.accent
                    border.width: 1
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.visibility === Window.Maximized ? 0 : 14
        color: root.bg
        border.color: root.visibility === Window.Maximized ? "transparent" : root.border
        border.width: root.visibility === Window.Maximized ? 0 : 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: root.titleBg
                border.color: root.borderSoft
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
                                       ? root.pressed
                                       : leftScrollMouse.containsMouse
                                         ? root.hover
                                         : "transparent"
                                opacity: tabFlick.contentX > 0 ? 1.0 : 0.45

                                AppIcon {
                                    anchors.centerIn: parent
                                    source: "assets/icons/chevron-left.svg"
                                    iconSize: 14
                                    iconColor: root.text
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
                                        color: addTabMouse.containsMouse ? root.hover : "transparent"

                                        AppIcon {
                                            anchors.centerIn: parent
                                            source: "assets/icons/add.svg"
                                            iconSize: 16
                                            iconColor: root.text
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
                                        interactive: !root.tabDragActive && contentWidth > width
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
                                                    required property int index
                                                    required property var modelData

                                                    property bool movedEnough: false

                                                    x: index * (root.tabWidth + root.tabSpacing)
                                                    y: 1
                                                    width: root.tabWidth
                                                    height: 32
                                                    radius: 9
                                                    z: root.draggedTabIndex === index ? 100 : 1

                                                    transform: Translate {
                                                        x: root.draggedTabIndex === index ? root.draggedTabOffset : 0
                                                    }

                                                    color: index === root.currentTab
                                                           ? (tabMouse.pressed
                                                                ? (root.darkTheme ? "#2a3342" : "#e7edf8")
                                                                : tabMouse.containsMouse
                                                                  ? (root.darkTheme ? "#242c3a" : "#f4f7fc")
                                                                  : (root.darkTheme ? "#202633" : "#ffffff"))
                                                           : (tabMouse.pressed
                                                                ? root.pressed
                                                                : tabMouse.containsMouse
                                                                  ? root.hover
                                                                  : "transparent")

                                                    border.color: index === root.currentTab ? root.border : "transparent"
                                                    border.width: 1

                                                    Row {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left: parent.left
                                                        anchors.leftMargin: 12
                                                        spacing: 8

                                                        AppIcon {
                                                            source: modelData.icon
                                                            iconSize: 15
                                                            iconColor: root.text
                                                        }

                                                        Text {
                                                            text: modelData.title
                                                            color: root.text
                                                            font.pixelSize: 13
                                                            font.bold: index === root.currentTab
                                                            elide: Text.ElideRight
                                                            width: 140
                                                        }
                                                    }

                                                    Rectangle {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 8
                                                        width: 18
                                                        height: 18
                                                        radius: 9
                                                        color: closeMouse.containsMouse ? root.hover : "transparent"
                                                        z: 3

                                                        AppIcon {
                                                            anchors.centerIn: parent
                                                            source: "assets/icons/close.svg"
                                                            iconSize: 12
                                                            iconOpacity: 0.75
                                                            iconColor: root.muted
                                                        }

                                                        MouseArea {
                                                            id: closeMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            acceptedButtons: Qt.LeftButton
                                                            preventStealing: true

                                                            onClicked: function(mouse) {
                                                                root.closeTab(index)
                                                                mouse.accepted = true
                                                            }
                                                        }
                                                    }

                                                    DragHandler {
                                                        id: dragHandler
                                                        target: null
                                                        acceptedButtons: Qt.LeftButton
                                                        xAxis.enabled: true
                                                        yAxis.enabled: false

                                                        onActiveChanged: {
                                                            root.tabDragActive = active

                                                            if (active) {
                                                                root.currentTab = index
                                                                root.draggedTabIndex = index
                                                                root.draggedTabStartIndex = index
                                                                root.draggedTabOffset = 0
                                                                tabDelegate.movedEnough = false
                                                                tabAutoScrollTimer.start()
                                                            } else {
                                                                root.tabAutoScrollDirection = 0
                                                                tabAutoScrollTimer.stop()
                                                                root.draggedTabIndex = -1
                                                                root.draggedTabStartIndex = -1
                                                                root.draggedTabOffset = 0
                                                                tabDelegate.movedEnough = false
                                                            }
                                                        }

                                                        onTranslationChanged: {
                                                            if (root.draggedTabIndex !== index)
                                                                return

                                                            if (Math.abs(translation.x) > 8)
                                                                tabDelegate.movedEnough = true

                                                            var slotSize = root.tabWidth + root.tabSpacing

                                                            var draggedCenterX =
                                                                    root.draggedTabStartIndex * slotSize
                                                                    + translation.x
                                                                    + root.tabWidth / 2

                                                            var targetIndex = Math.floor(draggedCenterX / slotSize)
                                                            targetIndex = Math.max(0, Math.min(tabsModel.count - 1, targetIndex))

                                                            root.draggedTabOffset =
                                                                    draggedCenterX
                                                                    - (index * slotSize + root.tabWidth / 2)

                                                            if (targetIndex !== index) {
                                                                root.moveTab(index, targetIndex)
                                                                root.draggedTabIndex = targetIndex
                                                                root.ensureTabVisible(targetIndex)
                                                            }

                                                            var posInViewport = tabDelegate.mapToItem(
                                                                tabViewport,
                                                                tabDelegate.width / 2,
                                                                tabDelegate.height / 2
                                                            ).x + root.draggedTabOffset

                                                            if (posInViewport < 36)
                                                                root.tabAutoScrollDirection = -1
                                                            else if (posInViewport > tabViewport.width - 36)
                                                                root.tabAutoScrollDirection = 1
                                                            else
                                                                root.tabAutoScrollDirection = 0
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: tabMouse
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 30
                                                        hoverEnabled: true
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                                                        onPressed: function(mouse) {
                                                            if (mouse.button === Qt.RightButton) {
                                                                root.contextTabIndex = index
                                                                tabContextMenu.popup()
                                                                return
                                                            }

                                                            if (mouse.button === Qt.LeftButton)
                                                                root.currentTab = index
                                                        }

                                                        onClicked: function(mouse) {
                                                            if (mouse.button === Qt.LeftButton && !tabDelegate.movedEnough) {
                                                                root.currentTab = index
                                                                root.ensureTabVisible(index)
                                                            }
                                                        }

                                                        onDoubleClicked: {
                                                            if (!tabDelegate.movedEnough)
                                                                root.toggleMaximize()
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
                                            GradientStop { position: 0.0; color: darkTheme ? "#000000" : "#cfd5dd" }
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
                                            GradientStop { position: 1.0; color: darkTheme ? "#000000" : "#cfd5dd" }
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
                                       ? root.pressed
                                       : rightScrollMouse.containsMouse
                                         ? root.hover
                                         : "transparent"
                                opacity: tabFlick.contentX < (tabFlick.contentWidth - tabFlick.width - 1) ? 1.0 : 0.45

                                AppIcon {
                                    anchors.centerIn: parent
                                    source: "assets/icons/chevron-right.svg"
                                    iconSize: 14
                                    iconColor: root.text
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
                            iconSource: "assets/icons/minimize.svg"
                            onClicked: root.showMinimized()
                        }

                        WindowButton {
                            iconSource: root.visibility === Window.Maximized
                                        ? "assets/icons/filter-none.svg"
                                        : "assets/icons/check-box-outline-blank.svg"
                            onClicked: root.toggleMaximize()
                        }

                        WindowButton {
                            iconSource: "assets/icons/close.svg"
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
                color: root.surface
                border.color: root.borderSoft
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    IconButton {
                        iconSource: "assets/icons/arrow-back.svg"
                        tooltipText: "Back"
                        onClicked: {
                            if (pathModel.count > 1) {
                                pathModel.remove(pathModel.count - 1)
                                syncPathField()
                            }
                        }
                    }

                    IconButton { iconSource: "assets/icons/arrow-forward.svg"; tooltipText: "Forward" }

                    IconButton {
                        iconSource: "assets/icons/arrow-upward.svg"
                        tooltipText: "Up"
                        onClicked: {
                            if (pathModel.count > 1) {
                                pathModel.remove(pathModel.count - 1)
                                syncPathField()
                            }
                        }
                    }

                    IconButton { iconSource: "assets/icons/refresh.svg"; tooltipText: "Refresh" }

                    Rectangle {
                        id: pathBar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 10
                        color: darkTheme ? "#1b2230" : "#fcfcfd"
                        border.color: root.editingPath ? root.accent : root.border
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
                                                required property int index
                                                required property var modelData
                                                spacing: 6

                                                readonly property bool dropHovered: root.breadcrumbDropHoverIndex === index

                                                Rectangle {
                                                    id: crumbPill
                                                    height: 28
                                                    radius: 8
                                                    color: dropHovered
                                                           ? root.selectedSoft
                                                           : crumbMouse.pressed
                                                             ? root.pressed
                                                             : crumbMouse.containsMouse
                                                               ? (darkTheme ? "#344055" : "#dfe9f8")
                                                               : "transparent"
                                                    border.color: dropHovered ? root.accent : "transparent"
                                                    border.width: dropHovered ? 1 : 0
                                                    width: Math.min(crumbContent.implicitWidth + 16, 190)
                                                    clip: true

                                                    DropArea {
                                                        anchors.fill: parent

                                                        onEntered: function(drag) {
                                                            drag.accepted = root.draggedFileCount > 0
                                                            if (drag.accepted)
                                                                root.breadcrumbDropHoverIndex = index
                                                        }

                                                        onExited: function(drag) {
                                                            if (root.breadcrumbDropHoverIndex === index)
                                                                root.breadcrumbDropHoverIndex = -1
                                                        }

                                                        onDropped: function(drop) {
                                                            if (root.draggedFileCount > 0) {
                                                                drop.accepted = true
                                                                root.handleDroppedItem(modelData.label, "breadcrumb")
                                                            }
                                                            if (root.breadcrumbDropHoverIndex === index)
                                                                root.breadcrumbDropHoverIndex = -1
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
                                                            source: modelData.icon
                                                            iconSize: 13
                                                            visible: modelData.icon !== ""
                                                            iconColor: root.text
                                                        }

                                                        Text {
                                                            id: crumbText
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.label
                                                            color: root.text
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
                                                        acceptedButtons: Qt.LeftButton
                                                        z: 1

                                                        onClicked: {
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
                                                    source: "assets/icons/chevron-right.svg"
                                                    iconSize: 12
                                                    iconOpacity: 0.65
                                                    iconColor: root.muted
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
                                color: root.text
                                font.pixelSize: 13
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 0
                                bottomPadding: 0
                                verticalAlignment: TextInput.AlignVCenter
                                background: Rectangle { color: "transparent" }
                                onAccepted: root.editingPath = false
                                onActiveFocusChanged: {
                                    if (!activeFocus)
                                        root.editingPath = false
                                }
                                Keys.onEscapePressed: root.editingPath = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 38
                        radius: 10
                        color: darkTheme ? "#1b2230" : "#fcfcfd"
                        border.color: searchField.activeFocus ? root.accent : root.border
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
                                       ? root.pressed
                                       : searchScopeMouse.containsMouse
                                         ? root.hover
                                         : "transparent"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    AppIcon {
                                        source: root.searchScope === "global"
                                                ? "assets/icons/hard-drive.svg"
                                                : "assets/icons/folder.svg"
                                        iconSize: 14
                                        iconColor: root.text
                                    }

                                    AppIcon {
                                        source: searchScopeMenu.visible
                                                ? "assets/icons/keyboard-arrow-up.svg"
                                                : "assets/icons/keyboard-arrow-down.svg"
                                        iconSize: 10
                                        iconOpacity: 0.6
                                        iconColor: root.muted
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
                                source: "assets/icons/search.svg"
                                iconSize: 14
                                iconOpacity: 0.65
                                iconColor: root.muted
                            }

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: root.searchScope === "global"
                                                 ? "Search everywhere"
                                                 : "Search in folder"
                                placeholderTextColor: root.muted
                                text: root.currentSearch
                                color: root.text
                                font.pixelSize: 13
                                topPadding: 0
                                bottomPadding: 0
                                leftPadding: 0
                                rightPadding: 0
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                background: Rectangle { color: "transparent" }

                                onTextChanged: root.currentSearch = text
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: root.surface2
                border.color: root.borderSoft
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    IconButton {
                        id: createButton
                        iconSource: "assets/icons/add.svg"
                        tooltipText: "Create"
                        onClicked: createMenu.popup()
                    }

                    IconButton {
                        iconSource: "assets/icons/content-cut.svg"
                        tooltipText: "Cut"
                    }

                    IconButton {
                        iconSource: "assets/icons/content-copy.svg"
                        tooltipText: "Copy"
                        onClicked: root.addToastNotification("Copied successfully to clipboard", "success")
                    }

                    IconButton {
                        iconSource: "assets/icons/content-paste.svg"
                        tooltipText: "Paste"
                    }

                    IconButton {
                        iconSource: "assets/icons/edit.svg"
                        tooltipText: "Rename"
                        onClicked: {
                            if (root.currentFileRow >= 0)
                                root.beginRenameRow(root.currentFileRow)
                        }
                    }

                    IconButton {
                        iconSource: "assets/icons/delete.svg"
                        tooltipText: "Delete"
                        onClicked: {
                            if (root.selectedFileCount() > 1)
                                root.askDeleteSelection()
                            else if (root.currentFileRow >= 0)
                                root.askDeleteRow(root.currentFileRow)
                        }
                    }

                    IconButton {
                        iconSource: "assets/icons/sync.svg"
                        tooltipText: "Test progress notification"
                        onClicked: {
                            deleteProgressTimer.stop()
                            deleteProgressTimer.progressValue = 0
                            deleteProgressTimer.notificationId = root.addProgressNotification("Moving files...", 0)
                            deleteProgressTimer.start()
                        }
                    }
                    IconButton {
                        id: toolbarViewButton
                        iconSource: root.viewModeIcon(root.currentViewMode)
                        tooltipText: "View"
                        onClicked: viewModeMenu.popup()
                    }

                    IconButton {
                        id: moreButton
                        iconSource: "assets/icons/more-horiz.svg"
                        tooltipText: "More"
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
                        id: themeButton
                        width: 116
                        height: 32
                        radius: 9
                        color: themeMouse.pressed
                               ? (darkTheme ? "#3a475d" : "#cadbf8")
                               : themeMouse.containsMouse
                                 ? (darkTheme ? "#2d3748" : "#dce8fb")
                                 : (darkTheme ? "#1d2431" : "#fafbfc")
                        border.color: root.border
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            AppIcon {
                                source: root.themeMode === "Dark"
                                        ? "assets/icons/moon.svg"
                                        : root.themeMode === "Light"
                                          ? "assets/icons/sun.svg"
                                          : "assets/icons/computer.svg"
                                iconSize: 14
                                iconColor: root.text
                            }

                            Text {
                                text: root.themeMode
                                color: root.text
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
                        color: darkTheme ? "#121820" : "#f4f6f8"
                        border.color: root.borderSoft
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

                                    ScrollBar.vertical: ExplorerScrollbarV {}
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
                                                                 ? root.selectedSoft
                                                                 : (root.selectedSidebarLabel === itemLabel && root.selectedSidebarKind === itemKind)
                                                                   ? root.selected
                                                                   : tapArea.pressed
                                                                     ? root.pressed
                                                                     : tapArea.containsMouse
                                                                       ? (darkTheme ? "#2a3444" : "#e6eefb")
                                                                       : "transparent"
                                            border.color: dropHovered ? root.accent : "transparent"
                                            border.width: dropHovered ? 1 : 0
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

                                                    AppIcon {
                                                        anchors.centerIn: parent
                                                        visible: hasChildren
                                                        source: expanded
                                                                ? "assets/icons/keyboard-arrow-down.svg"
                                                                : "assets/icons/chevron-right.svg"
                                                        iconSize: 12
                                                        iconColor: root.muted
                                                    }
                                                }

                                                Item {
                                                    visible: !itemSection
                                                    width: 16
                                                    height: 16

                                                    AppIcon {
                                                        anchors.centerIn: parent
                                                        source: itemIcon
                                                        iconSize: 15
                                                        iconColor: root.text
                                                    }
                                                }

                                                Text {
                                                    text: itemLabel
                                                    color: itemSection ? root.muted : root.text
                                                    font.pixelSize: itemSection ? 11 : 13
                                                    font.bold: itemSection
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        DropArea {
                                            anchors.fill: parent

                                            onEntered: function(drag) {
                                                var ok = !itemSection
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
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (hasChildren)
                                                        treeView.toggleExpanded(row)
                                                    else
                                                        root.openLocation(itemLabel, itemIcon, itemKind)
                                                }
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
                                Layout.preferredHeight: Math.min(
                                    400,
                                    20 + 22 + (drivesModel.count * 62)
                                )
                                Layout.minimumHeight: 120
                                radius: 12
                                color: darkTheme ? "#171d27" : "#fbfcfd"
                                border.color: root.borderSoft
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4

                                    Text {
                                        text: "Drives"
                                        color: root.text
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    Repeater {
                                        model: drivesModel

                                        delegate: Rectangle {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            width: parent ? parent.width : 240
                                            height: 48
                                            radius: 8

                                            readonly property real usedPct: modelData.total > 0 ? (modelData.used / modelData.total) : 0
                                            readonly property color usedColor: usedPct >= 0.85 ? root.driveUsedRed : root.driveUsedBlue
                                            readonly property bool dropHovered: root.navDropHoverLabel === modelData.label
                                                                                && root.navDropHoverKind === "drive"

                                            color: dropHovered
                                                   ? root.selectedSoft
                                                   : (root.selectedSidebarKind === "drive" && root.selectedSidebarLabel === modelData.label)
                                                     ? root.selected
                                                     : driveMouse.pressed
                                                       ? root.pressed
                                                       : driveMouse.containsMouse
                                                         ? (darkTheme ? "#2a3444" : "#e6eefb")
                                                         : "transparent"

                                            border.color: dropHovered ? root.accent : "transparent"
                                            border.width: dropHovered ? 1 : 0

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
                                                        source: modelData.icon
                                                        iconSize: 14
                                                        iconColor: root.text
                                                    }

                                                    Text {
                                                        text: modelData.label
                                                        color: root.text
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: 5
                                                    radius: 3
                                                    color: root.driveFree

                                                    Rectangle {
                                                        width: parent.width * Math.max(0, Math.min(1, usedPct))
                                                        height: parent.height
                                                        radius: 3
                                                        color: usedColor
                                                    }
                                                }

                                                Text {
                                                    text: modelData.usedText
                                                    color: root.muted
                                                    font.pixelSize: 10
                                                }
                                            }

                                            DropArea {
                                                anchors.fill: parent

                                                onEntered: function(drag) {
                                                    drag.accepted = true
                                                    root.setNavDropHover(modelData.label, "drive")
                                                }

                                                onExited: function(drag) {
                                                    root.clearNavDropHover(modelData.label, "drive")
                                                }

                                                onDropped: function(drop) {
                                                    drop.accepted = true
                                                    root.handleDroppedItem(modelData.label, "drive")
                                                    root.clearNavDropHover(modelData.label, "drive")
                                                }
                                            }

                                            MouseArea {
                                                id: driveMouse
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
                               ? (darkTheme ? "#2a3342" : "#d7dfeb")
                               : splitterMouse.containsMouse
                                 ? (darkTheme ? "#212938" : "#e3e9f2")
                                 : "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2
                            height: parent.height
                            radius: 1
                            color: splitterMouse.pressed
                                   ? root.accent
                                   : splitterMouse.containsMouse
                                     ? root.border
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
                        color: root.surface3
                        border.color: root.borderSoft
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.currentViewMode === "Details" ? 40 : 0
                                visible: root.currentViewMode === "Details"
                                color: darkTheme ? "#171d27" : "#f6f7f9"
                                border.color: root.borderSoft
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
                                        color: nameHeaderMouse.containsMouse ? root.hover : "transparent"

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            spacing: 6

                                            Text {
                                                text: "Name"
                                                color: root.text
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            AppIcon {
                                                visible: root.sortColumn === 0
                                                source: root.sortAscending
                                                        ? "assets/icons/keyboard-arrow-up.svg"
                                                        : "assets/icons/keyboard-arrow-down.svg"
                                                iconSize: 12
                                                iconColor: root.text
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
                                            color: resizeNameMouse.pressed ? root.accent : resizeNameMouse.containsMouse ? root.hover : "transparent"

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
                                        color: dateHeaderMouse.containsMouse ? root.hover : "transparent"

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            spacing: 6

                                            Text {
                                                text: "Date modified"
                                                color: root.text
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            AppIcon {
                                                visible: root.sortColumn === 1
                                                source: root.sortAscending
                                                        ? "assets/icons/keyboard-arrow-up.svg"
                                                        : "assets/icons/keyboard-arrow-down.svg"
                                                iconSize: 12
                                                iconColor: root.text
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
                                            color: resizeDateMouse.pressed ? root.accent : resizeDateMouse.containsMouse ? root.hover : "transparent"

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
                                        color: typeHeaderMouse.containsMouse ? root.hover : "transparent"

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            spacing: 6

                                            Text {
                                                text: "Type"
                                                color: root.text
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            AppIcon {
                                                visible: root.sortColumn === 2
                                                source: root.sortAscending
                                                        ? "assets/icons/keyboard-arrow-up.svg"
                                                        : "assets/icons/keyboard-arrow-down.svg"
                                                iconSize: 12
                                                iconColor: root.text
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
                                            color: resizeTypeMouse.pressed ? root.accent : resizeTypeMouse.containsMouse ? root.hover : "transparent"

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
                                        color: sizeHeaderMouse.containsMouse ? root.hover : "transparent"

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            spacing: 6

                                            Text {
                                                text: "Size"
                                                color: root.text
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            AppIcon {
                                                visible: root.sortColumn === 3
                                                source: root.sortAscending
                                                        ? "assets/icons/keyboard-arrow-up.svg"
                                                        : "assets/icons/keyboard-arrow-down.svg"
                                                iconSize: 12
                                                iconColor: root.text
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

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: darkTheme ? "#141920" : "#f6f7f9"
                                border.color: root.borderSoft
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        text: root.selectedFileCount() > 0
                                              ? (filesModel.rowCount + " items   " + root.selectedFileCount() + " selected")
                                              : (filesModel.rowCount + " items")
                                        color: root.muted
                                        font.pixelSize: 11
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        id: bottomViewButton
                                        width: 24
                                        height: 24
                                        radius: 7
                                        color: "transparent"

                                        DropShadow {
                                            anchors.fill: bottomViewBg
                                            source: bottomViewBg
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 8
                                            samples: 17
                                            color: root.darkTheme ? "#50000000" : "#18000000"
                                        }

                                        Rectangle {
                                            id: bottomViewBg
                                            anchors.fill: parent
                                            radius: 7
                                            color: bottomViewMouse.pressed
                                                   ? root.pressed
                                                   : bottomViewMouse.containsMouse
                                                     ? root.hover
                                                     : (darkTheme ? "#1a1f27" : "#ffffff")
                                            border.color: bottomViewMouse.containsMouse || bottomViewMouse.pressed
                                                          ? root.border
                                                          : root.borderSoft
                                            border.width: 1
                                        }

                                        AppIcon {
                                            anchors.centerIn: parent
                                            source: root.currentViewMode === "Large icons"
                                                    ? "assets/icons/grid-view.svg"
                                                    : root.currentViewMode === "Tiles"
                                                      ? "assets/icons/tile-view.svg"
                                                      : root.currentViewMode === "Details"
                                                        ? "assets/icons/detailed-view.svg"
                                                        : "assets/icons/list-view.svg"
                                            iconSize: 13
                                            iconOpacity: 0.75
                                            iconColor: root.muted
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
                                        color: "transparent"

                                        DropShadow {
                                            anchors.fill: notificationsBg
                                            source: notificationsBg
                                            horizontalOffset: 0
                                            verticalOffset: 2
                                            radius: 8
                                            samples: 17
                                            color: root.darkTheme ? "#50000000" : "#18000000"
                                        }

                                        Rectangle {
                                            id: notificationsBg
                                            anchors.fill: parent
                                            radius: 7
                                            color: notificationsMouse.pressed
                                                   ? root.pressed
                                                   : notificationsMouse.containsMouse
                                                     ? root.hover
                                                     : (darkTheme ? "#1a1f27" : "#ffffff")
                                            border.color: notificationsMouse.containsMouse || notificationsMouse.pressed
                                                          ? root.border
                                                          : root.borderSoft
                                            border.width: 1
                                        }

                                        AppIcon {
                                            anchors.centerIn: parent
                                            source: "assets/icons/notifications.svg"
                                            iconSize: 13
                                            iconOpacity: 0.8
                                            iconColor: root.muted
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
                                            color: root.accent
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

                        notificationId: modelData.notificationId
                        title: modelData.title
                        kind: modelData.kind
                        progress: modelData.progress
                        autoClose: modelData.autoClose
                        done: modelData.done
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
            color: darkTheme ? "#1b2230" : "#ffffff"
            border.color: root.border
            border.width: 1
        }

        Row {
            id: previewContent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            spacing: 8

            AppIcon {
                source: root.draggedFileIcon !== "" ? root.draggedFileIcon : "assets/icons/insert-drive-file.svg"
                iconSize: 20
                iconColor: root.text
            }

            Text {
                text: root.draggedFileCount > 1
                      ? (root.draggedFileCount + " items")
                      : root.draggedFileName
                color: root.text
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
        interval: 16
        repeat: true

        onTriggered: {
            if (root.tabAutoScrollDirection === 0 || !root.tabDragActive)
                return

            root.scrollTabsBy(root.tabAutoScrollDirection * 12)
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

    Component.onCompleted: syncPathField()
}