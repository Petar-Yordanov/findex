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
        assets/icons/light/add.png
        assets/icons/light/add-to-drive.png
        assets/icons/light/arrow-back.png
        assets/icons/light/arrow-forward.png
        assets/icons/light/arrow-upward.png
        assets/icons/light/check.png
        assets/icons/light/check-box-outline-blank.png
        assets/icons/light/chevron-left.png
        assets/icons/light/chevron-right.png
        assets/icons/light/close.png
        assets/icons/light/code.png
        assets/icons/light/computer.png
        assets/icons/light/content-copy.png
        assets/icons/light/content-cut.png
        assets/icons/light/content-paste.png
        assets/icons/light/dark-mode.png
        assets/icons/light/delete.png
        assets/icons/light/description.png
        assets/icons/light/desktop-windows.png
        assets/icons/light/detailed-view.png
        assets/icons/light/devices.png
        assets/icons/light/download.png
        assets/icons/light/edit.png
        assets/icons/light/error.png
        assets/icons/light/expand-more.png
        assets/icons/light/filter-none.png
        assets/icons/light/folder.png
        assets/icons/light/grid-view.png
        assets/icons/light/hard-drive.png
        assets/icons/light/history.png
        assets/icons/light/home.png
        assets/icons/light/image.png
        assets/icons/light/info.png
        assets/icons/light/insert-drive-file.png
        assets/icons/light/keyboard-arrow-down.png
        assets/icons/light/keyboard-arrow-up.png
        assets/icons/light/launch.png
        assets/icons/light/light-mode.png
        assets/icons/light/list-view.png
        assets/icons/light/lock.png
        assets/icons/light/minimize.png
        assets/icons/light/moon.png
        assets/icons/light/more-horiz.png
        assets/icons/light/movie.png
        assets/icons/light/music-note.png
        assets/icons/light/notifications.png
        assets/icons/light/picture-as-pdf.png
        assets/icons/light/refresh.png
        assets/icons/light/save.png
        assets/icons/light/search.png
        assets/icons/light/sort.png
        assets/icons/light/storage.png
        assets/icons/light/sun.png
        assets/icons/light/sync.png
        assets/icons/light/terminal.png
        assets/icons/light/tile-view.png
        assets/icons/light/undo.png
        assets/icons/light/usb.png
        assets/icons/light/view-list.png
        assets/icons/light/view-list-alt.png
        assets/icons/light/visibility.png
        assets/icons/light/zip.png

        assets/icons/dark/add.png
        assets/icons/dark/add-to-drive.png
        assets/icons/dark/arrow-back.png
        assets/icons/dark/arrow-forward.png
        assets/icons/dark/arrow-upward.png
        assets/icons/dark/check.png
        assets/icons/dark/check-box-outline-blank.png
        assets/icons/dark/chevron-left.png
        assets/icons/dark/chevron-right.png
        assets/icons/dark/close.png
        assets/icons/dark/code.png
        assets/icons/dark/computer.png
        assets/icons/dark/content-copy.png
        assets/icons/dark/content-cut.png
        assets/icons/dark/content-paste.png
        assets/icons/dark/dark-mode.png
        assets/icons/dark/delete.png
        assets/icons/dark/description.png
        assets/icons/dark/desktop-windows.png
        assets/icons/dark/detailed-view.png
        assets/icons/dark/devices.png
        assets/icons/dark/download.png
        assets/icons/dark/edit.png
        assets/icons/dark/error.png
        assets/icons/dark/expand-more.png
        assets/icons/dark/filter-none.png
        assets/icons/dark/folder.png
        assets/icons/dark/grid-view.png
        assets/icons/dark/hard-drive.png
        assets/icons/dark/history.png
        assets/icons/dark/home.png
        assets/icons/dark/image.png
        assets/icons/dark/info.png
        assets/icons/dark/insert-drive-file.png
        assets/icons/dark/keyboard-arrow-down.png
        assets/icons/dark/keyboard-arrow-up.png
        assets/icons/dark/launch.png
        assets/icons/dark/light-mode.png
        assets/icons/dark/list-view.png
        assets/icons/dark/lock.png
        assets/icons/dark/minimize.png
        assets/icons/dark/moon.png
        assets/icons/dark/more-horiz.png
        assets/icons/dark/movie.png
        assets/icons/dark/music-note.png
        assets/icons/dark/notifications.png
        assets/icons/dark/picture-as-pdf.png
        assets/icons/dark/refresh.png
        assets/icons/dark/save.png
        assets/icons/dark/search.png
        assets/icons/dark/sort.png
        assets/icons/dark/storage.png
        assets/icons/dark/sun.png
        assets/icons/dark/sync.png
        assets/icons/dark/terminal.png
        assets/icons/dark/tile-view.png
        assets/icons/dark/undo.png
        assets/icons/dark/usb.png
        assets/icons/dark/view-list.png
        assets/icons/dark/view-list-alt.png
        assets/icons/dark/visibility.png
        assets/icons/dark/zip.png
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