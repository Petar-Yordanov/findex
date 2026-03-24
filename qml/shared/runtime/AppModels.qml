import QtQuick
import QtQml.Models
import Qt.labs.qmlmodels as Labs

Item {
    id: root

    property alias notificationsModel: notificationsModel
    property alias tabsModel: tabsModel
    property alias pathModel: pathModel
    property alias sidebarModel: sidebarModel
    property alias drivesModel: drivesModel
    property alias filesModel: filesModel

    ListModel {
        id: notificationsModel
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
}