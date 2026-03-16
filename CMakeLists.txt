cmake_minimum_required(VERSION 3.16)

project(FileExplorer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml QuickControls2)

if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
endif()

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appFileExplorer
    main.cpp
    FileAssociationService.cpp
    FileAssociationService.h
)

if(WIN32)
    target_sources(appFileExplorer PRIVATE FileAssociationService_win.cpp)
elseif(APPLE)
    target_sources(appFileExplorer PRIVATE FileAssociationService_mac.cpp)
elseif(UNIX)
    target_sources(appFileExplorer PRIVATE FileAssociationService_linux.cpp)
endif()

target_include_directories(appFileExplorer PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

qt_add_qml_module(appFileExplorer
    URI FileExplorer

    QML_FILES
        qml/Main.qml
        qml/components/AppIcon.qml
        qml/components/ExplorerScrollbarH.qml
        qml/components/ExplorerScrollbarV.qml
        qml/components/IconButton.qml
        qml/components/InlineRenameField.qml
        qml/components/NotificationCard.qml
        qml/components/SelectionBand.qml
        qml/components/StyledMenu.qml
        qml/components/StyledMenuItem.qml
        qml/components/StyledMenuSeparator.qml
        qml/components/ThinProgressBar.qml
        qml/components/WindowButton.qml

    RESOURCES
        assets/icons/add.svg
        assets/icons/add-to-drive.svg
        assets/icons/arrow-back.svg
        assets/icons/arrow-forward.svg
        assets/icons/arrow-upward.svg
        assets/icons/check-box-outline-blank.svg
        assets/icons/chevron-right.svg
        assets/icons/chevron-left.svg
        assets/icons/close.svg
        assets/icons/computer.svg
        assets/icons/content-copy.svg
        assets/icons/content-cut.svg
        assets/icons/content-paste.svg
        assets/icons/dark-mode.svg
        assets/icons/delete.svg
        assets/icons/description.svg
        assets/icons/desktop-windows.svg
        assets/icons/devices.svg
        assets/icons/detailed-view.svg
        assets/icons/download.svg
        assets/icons/edit.svg
        assets/icons/error.svg
        assets/icons/expand-more.svg
        assets/icons/filter-none.svg
        assets/icons/folder.svg
        assets/icons/grid-view.svg
        assets/icons/hard-drive.svg
        assets/icons/history.svg
        assets/icons/home.svg
        assets/icons/image.svg
        assets/icons/info.svg
        assets/icons/insert-drive-file.svg
        assets/icons/keyboard-arrow-down.svg
        assets/icons/keyboard-arrow-up.svg
        assets/icons/launch.svg
        assets/icons/light-mode.svg
        assets/icons/list-view.svg
        assets/icons/lock.svg
        assets/icons/minimize.svg
        assets/icons/moon.svg
        assets/icons/more-horiz.svg
        assets/icons/movie.svg
        assets/icons/music-note.svg
        assets/icons/notifications.svg
        assets/icons/picture-as-pdf.svg
        assets/icons/refresh.svg
        assets/icons/save.svg
        assets/icons/search.svg
        assets/icons/sort.svg
        assets/icons/storage.svg
        assets/icons/sun.svg
        assets/icons/sync.svg
        assets/icons/terminal.svg
        assets/icons/tile-view.svg
        assets/icons/undo.svg
        assets/icons/usb.svg
        assets/icons/view-list.svg
        assets/icons/view-list-alt.svg
        assets/icons/visibility.svg
        assets/icons/zip.svg
        assets/icons/check.svg
        assets/icons/code.svg
        assets/icons/light/add.png
        assets/icons/light/add.svg
        assets/icons/light/add-to-drive.png
        assets/icons/light/add-to-drive.svg
        assets/icons/light/arrow-back.png
        assets/icons/light/arrow-back.svg
        assets/icons/light/arrow-forward.png
        assets/icons/light/arrow-forward.svg
        assets/icons/light/arrow-upward.png
        assets/icons/light/arrow-upward.svg
        assets/icons/light/check.png
        assets/icons/light/check.svg
        assets/icons/light/check-box-outline-blank.png
        assets/icons/light/check-box-outline-blank.svg
        assets/icons/light/chevron-left.png
        assets/icons/light/chevron-left.svg
        assets/icons/light/chevron-right.png
        assets/icons/light/chevron-right.svg
        assets/icons/light/close.png
        assets/icons/light/close.svg
        assets/icons/light/code.png
        assets/icons/light/code.svg
        assets/icons/light/computer.png
        assets/icons/light/computer.svg
        assets/icons/light/content-copy.png
        assets/icons/light/content-copy.svg
        assets/icons/light/content-cut.png
        assets/icons/light/content-cut.svg
        assets/icons/light/content-paste.png
        assets/icons/light/content-paste.svg
        assets/icons/light/dark-mode.png
        assets/icons/light/dark-mode.svg
        assets/icons/light/delete.png
        assets/icons/light/delete.svg
        assets/icons/light/description.png
        assets/icons/light/description.svg
        assets/icons/light/desktop-windows.png
        assets/icons/light/desktop-windows.svg
        assets/icons/light/detailed-view.png
        assets/icons/light/detailed-view.svg
        assets/icons/light/devices.png
        assets/icons/light/devices.svg
        assets/icons/light/download.png
        assets/icons/light/download.svg
        assets/icons/light/edit.png
        assets/icons/light/edit.svg
        assets/icons/light/error.png
        assets/icons/light/error.svg
        assets/icons/light/expand-more.png
        assets/icons/light/expand-more.svg
        assets/icons/light/filter-none.png
        assets/icons/light/filter-none.svg
        assets/icons/light/folder.png
        assets/icons/light/folder.svg
        assets/icons/light/grid-view.png
        assets/icons/light/grid-view.svg
        assets/icons/light/hard-drive.png
        assets/icons/light/hard-drive.svg
        assets/icons/light/history.png
        assets/icons/light/history.svg
        assets/icons/light/home.png
        assets/icons/light/home.svg
        assets/icons/light/image.png
        assets/icons/light/image.svg
        assets/icons/light/info.png
        assets/icons/light/info.svg
        assets/icons/light/insert-drive-file.png
        assets/icons/light/insert-drive-file.svg
        assets/icons/light/keyboard-arrow-down.png
        assets/icons/light/keyboard-arrow-down.svg
        assets/icons/light/keyboard-arrow-up.png
        assets/icons/light/keyboard-arrow-up.svg
        assets/icons/light/launch.png
        assets/icons/light/launch.svg
        assets/icons/light/light-mode.png
        assets/icons/light/light-mode.svg
        assets/icons/light/list-view.png
        assets/icons/light/list-view.svg
        assets/icons/light/lock.png
        assets/icons/light/lock.svg
        assets/icons/light/minimize.png
        assets/icons/light/minimize.svg
        assets/icons/light/moon.png
        assets/icons/light/moon.svg
        assets/icons/light/more-horiz.png
        assets/icons/light/more-horiz.svg
        assets/icons/light/movie.png
        assets/icons/light/movie.svg
        assets/icons/light/music-note.png
        assets/icons/light/music-note.svg
        assets/icons/light/notifications.png
        assets/icons/light/notifications.svg
        assets/icons/light/picture-as-pdf.png
        assets/icons/light/picture-as-pdf.svg
        assets/icons/light/refresh.png
        assets/icons/light/refresh.svg
        assets/icons/light/save.png
        assets/icons/light/save.svg
        assets/icons/light/search.png
        assets/icons/light/search.svg
        assets/icons/light/sort.png
        assets/icons/light/sort.svg
        assets/icons/light/storage.png
        assets/icons/light/storage.svg
        assets/icons/light/sun.png
        assets/icons/light/sun.svg
        assets/icons/light/sync.png
        assets/icons/light/sync.svg
        assets/icons/light/terminal.png
        assets/icons/light/terminal.svg
        assets/icons/light/tile-view.png
        assets/icons/light/tile-view.svg
        assets/icons/light/undo.png
        assets/icons/light/undo.svg
        assets/icons/light/usb.png
        assets/icons/light/usb.svg
        assets/icons/light/view-list.png
        assets/icons/light/view-list.svg
        assets/icons/light/view-list-alt.png
        assets/icons/light/view-list-alt.svg
        assets/icons/light/visibility.png
        assets/icons/light/visibility.svg
        assets/icons/light/zip.png
        assets/icons/light/zip.svg
        assets/icons/dark/add.png
        assets/icons/dark/add.svg
        assets/icons/dark/add-to-drive.png
        assets/icons/dark/add-to-drive.svg
        assets/icons/dark/arrow-back.png
        assets/icons/dark/arrow-back.svg
        assets/icons/dark/arrow-forward.png
        assets/icons/dark/arrow-forward.svg
        assets/icons/dark/arrow-upward.png
        assets/icons/dark/arrow-upward.svg
        assets/icons/dark/check.png
        assets/icons/dark/check.svg
        assets/icons/dark/check-box-outline-blank.png
        assets/icons/dark/check-box-outline-blank.svg
        assets/icons/dark/chevron-left.png
        assets/icons/dark/chevron-left.svg
        assets/icons/dark/chevron-right.png
        assets/icons/dark/chevron-right.svg
        assets/icons/dark/close.png
        assets/icons/dark/close.svg
        assets/icons/dark/code.png
        assets/icons/dark/code.svg
        assets/icons/dark/computer.png
        assets/icons/dark/computer.svg
        assets/icons/dark/content-copy.png
        assets/icons/dark/content-copy.svg
        assets/icons/dark/content-cut.png
        assets/icons/dark/content-cut.svg
        assets/icons/dark/content-paste.png
        assets/icons/dark/content-paste.svg
        assets/icons/dark/dark-mode.png
        assets/icons/dark/dark-mode.svg
        assets/icons/dark/delete.png
        assets/icons/dark/delete.svg
        assets/icons/dark/description.png
        assets/icons/dark/description.svg
        assets/icons/dark/desktop-windows.png
        assets/icons/dark/desktop-windows.svg
        assets/icons/dark/detailed-view.png
        assets/icons/dark/detailed-view.svg
        assets/icons/dark/devices.png
        assets/icons/dark/devices.svg
        assets/icons/dark/download.png
        assets/icons/dark/download.svg
        assets/icons/dark/edit.png
        assets/icons/dark/edit.svg
        assets/icons/dark/error.png
        assets/icons/dark/error.svg
        assets/icons/dark/expand-more.png
        assets/icons/dark/expand-more.svg
        assets/icons/dark/filter-none.png
        assets/icons/dark/filter-none.svg
        assets/icons/dark/folder.png
        assets/icons/dark/folder.svg
        assets/icons/dark/grid-view.png
        assets/icons/dark/grid-view.svg
        assets/icons/dark/hard-drive.png
        assets/icons/dark/hard-drive.svg
        assets/icons/dark/history.png
        assets/icons/dark/history.svg
        assets/icons/dark/home.png
        assets/icons/dark/home.svg
        assets/icons/dark/image.png
        assets/icons/dark/image.svg
        assets/icons/dark/info.png
        assets/icons/dark/info.svg
        assets/icons/dark/insert-drive-file.png
        assets/icons/dark/insert-drive-file.svg
        assets/icons/dark/keyboard-arrow-down.png
        assets/icons/dark/keyboard-arrow-down.svg
        assets/icons/dark/keyboard-arrow-up.png
        assets/icons/dark/keyboard-arrow-up.svg
        assets/icons/dark/launch.png
        assets/icons/dark/launch.svg
        assets/icons/dark/light-mode.png
        assets/icons/dark/light-mode.svg
        assets/icons/dark/list-view.png
        assets/icons/dark/list-view.svg
        assets/icons/dark/lock.png
        assets/icons/dark/lock.svg
        assets/icons/dark/minimize.png
        assets/icons/dark/minimize.svg
        assets/icons/dark/moon.png
        assets/icons/dark/moon.svg
        assets/icons/dark/more-horiz.png
        assets/icons/dark/more-horiz.svg
        assets/icons/dark/movie.png
        assets/icons/dark/movie.svg
        assets/icons/dark/music-note.png
        assets/icons/dark/music-note.svg
        assets/icons/dark/notifications.png
        assets/icons/dark/notifications.svg
        assets/icons/dark/picture-as-pdf.png
        assets/icons/dark/picture-as-pdf.svg
        assets/icons/dark/refresh.png
        assets/icons/dark/refresh.svg
        assets/icons/dark/save.png
        assets/icons/dark/save.svg
        assets/icons/dark/search.png
        assets/icons/dark/search.svg
        assets/icons/dark/sort.png
        assets/icons/dark/sort.svg
        assets/icons/dark/storage.png
        assets/icons/dark/storage.svg
        assets/icons/dark/sun.png
        assets/icons/dark/sun.svg
        assets/icons/dark/sync.png
        assets/icons/dark/sync.svg
        assets/icons/dark/terminal.png
        assets/icons/dark/terminal.svg
        assets/icons/dark/tile-view.png
        assets/icons/dark/tile-view.svg
        assets/icons/dark/undo.png
        assets/icons/dark/undo.svg
        assets/icons/dark/usb.png
        assets/icons/dark/usb.svg
        assets/icons/dark/view-list.png
        assets/icons/dark/view-list.svg
        assets/icons/dark/view-list-alt.png
        assets/icons/dark/view-list-alt.svg
        assets/icons/dark/visibility.png
        assets/icons/dark/visibility.svg
        assets/icons/dark/zip.png
        assets/icons/dark/zip.svg
)

set_target_properties(appFileExplorer PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appFileExplorer
    PRIVATE
        Qt6::Quick
        Qt6::Qml
        Qt6::QuickControls2
)

if(WIN32)
    target_link_libraries(appFileExplorer PRIVATE
        Shlwapi
        Advapi32
    )
endif()

if(APPLE)
    target_link_libraries(appFileExplorer PRIVATE
        "-framework CoreFoundation"
        "-framework CoreServices"
    )
endif()

if(UNIX AND NOT APPLE)
    target_link_libraries(appFileExplorer PRIVATE
        PkgConfig::GIO
    )
endif()

include(GNUInstallDirs)

install(TARGETS appFileExplorer
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET appFileExplorer
    OUTPUT_SCRIPT deploy_script
)
install(SCRIPT ${deploy_script})