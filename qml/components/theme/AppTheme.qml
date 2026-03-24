pragma Singleton
import QtQuick

QtObject {
    id: theme

    property string mode: "Dark"   // Dark | Light | System
    property bool systemDark: false

    readonly property bool isDark: mode === "Dark" || (mode === "System" && systemDark)

    Component.onCompleted: {
        console.log("AppTheme loaded, mode =", mode, "isDark =", isDark)
    }

    // Base surfaces
    readonly property color bg: isDark ? "#0f1115" : "#f3f4f6"
    readonly property color titleBg: isDark ? "#14171d" : "#eceef1"
    readonly property color surface: isDark ? "#171b22" : "#f7f7f8"
    readonly property color surface2: isDark ? "#161b22" : "#f1f2f4"
    readonly property color surface3: isDark ? "#11161d" : "#ffffff"
    readonly property color popupBg: isDark ? "#1b2230" : "#ffffff"
    readonly property color popupAltBg: isDark ? "#232c3a" : "#f8fafc"

    // Borders
    readonly property color border: isDark ? "#252b36" : "#d7dbe1"
    readonly property color borderSoft: isDark ? "#1d232c" : "#e4e7ec"
    readonly property color separator: isDark ? "#3a4352" : "#d9dde4"

    // Text
    readonly property color text: isDark ? "#edf1f7" : "#1f2329"
    readonly property color muted: isDark ? "#9aa4b2" : "#6b7280"
    readonly property color disabledText: isDark ? "#7f8ba0" : "#98a1ae"

    // Interaction
    readonly property color hover: isDark ? "#212835" : "#e9edf3"
    readonly property color pressed: isDark ? "#2c3646" : "#dde4ee"
    readonly property color accent: "#4c82f7"
    readonly property color selected: isDark ? "#2c3544" : "#dfe9f8"
    readonly property color selectedSoft: isDark ? "#202837" : "#eef3fb"
    readonly property color menuHighlight: isDark ? "#253041" : "#dfe9f8"
    readonly property color menuHighlightBorder: isDark ? "#334155" : "#c7d7ee"

    // Status
    readonly property color danger: "#df5c5c"
    readonly property color success: "#3f73f1"

    // Explorer-specific
    readonly property color driveUsedBlue: "#3f73f1"
    readonly property color driveUsedRed: "#df5c5c"
    readonly property color driveFree: isDark ? "#4b5563" : "#d4d8de"

    // Scrollbars
    readonly property color scrollbarThumb: isDark ? "#8f98a7" : "#b8c0cb"
    readonly property color scrollbarThumbHover: isDark ? "#a0a9b8" : "#9ea8b6"
    readonly property color scrollbarThumbPressed: isDark ? "#b0b8c6" : "#8d98a8"
    readonly property color scrollbarTrack: isDark ? "transparent" : "#eef1f5"
}