import QtQuick
import QtQuick.Controls
import "../theme" as Theme

ScrollBar {
    id: control

    property bool darkTheme: Theme.AppTheme.isDark
    property color thumbColor: Theme.AppTheme.scrollbarThumb
    property color thumbHoverColor: Theme.AppTheme.scrollbarThumbHover
    property color thumbPressedColor: Theme.AppTheme.scrollbarThumbPressed
    property color trackColor: Theme.AppTheme.scrollbarTrack

    orientation: Qt.Horizontal
    height: Theme.Metrics.scrollbarThickness
    policy: ScrollBar.AsNeeded

    contentItem: Rectangle {
        implicitHeight: 6
        radius: Theme.Metrics.radiusXs
        color: control.pressed ? control.thumbPressedColor
                               : control.hovered ? control.thumbHoverColor
                                                 : control.thumbColor
        opacity: control.darkTheme ? (control.active ? 0.95 : 0.75)
                                   : (control.active ? 0.9 : 0.8)
    }

    background: Rectangle {
        radius: Theme.Metrics.radiusXs
        color: control.trackColor
        opacity: control.darkTheme ? 0.0 : 1.0
    }
}