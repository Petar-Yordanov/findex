cmake_minimum_required(VERSION 3.16)

project(Findex VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml QuickControls2)

if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
endif()

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(Findex
    main.cpp

    FileAssociationService.cpp
    FileAssociationService.h
    FileManagerBridge.cpp
    FileManagerBridge.h

    FileManagerSessionService.cpp
    FileManagerSessionService.h
    FileManagerNavigationService.cpp
    FileManagerNavigationService.h
    FileManagerFileOpsService.cpp
    FileManagerFileOpsService.h
    FileManagerSearchService.cpp
    FileManagerSearchService.h
    FileManagerSidebarService.cpp
    FileManagerSidebarService.h
)

if(WIN32)
    target_sources(Findex PRIVATE FileAssociationService_win.cpp appicon.rc)
elseif(APPLE)
    target_sources(Findex PRIVATE FileAssociationService_mac.cpp)
elseif(UNIX)
    target_sources(Findex PRIVATE FileAssociationService_linux.cpp)
endif()

target_include_directories(Findex PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

qt_add_qml_module(Findex
    URI Findex

    QML_FILES
        qml/Main.qml
        qml/components/foundation/AppIcon.qml
        qml/components/foundation/ExplorerScrollbarH.qml
        qml/components/foundation/ExplorerScrollbarV.qml
        qml/components/foundation/IconButton.qml
        qml/components/foundation/InlineRenameField.qml
        qml/components/foundation/NotificationCard.qml
        qml/components/foundation/SelectionBand.qml
        qml/components/foundation/StyledMenu.qml
        qml/components/foundation/StyledMenuItem.qml
        qml/components/foundation/StyledMenuSeparator.qml
        qml/components/foundation/ThinProgressBar.qml
        qml/components/foundation/WindowButton.qml
        qml/components/foundation/BaseTooltip.qml

        qml/components/theme/AppTheme.qml
        qml/components/theme/Metrics.qml
        qml/components/theme/Typography.qml

        qml/shared/menus/ViewModeMenu.qml
        qml/shared/menus/ThemeMenu.qml
        qml/shared/menus/OpenWithMenu.qml
        qml/shared/menus/CopyPathsMenu.qml
        qml/shared/menus/SortByMenu.qml
        qml/shared/menus/CreateMenu.qml

        qml/features/files/FileContextMenu.qml
        qml/features/files/MultiFileContextMenu.qml
        qml/features/files/EmptyAreaContextMenu.qml
        qml/features/sidebar/SidebarContextMenu.qml
        qml/features/tabs/TabContextMenu.qml
        qml/features/breadcrumb/BreadcrumbContextMenu.qml

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
        assets/icons/light/preview.png

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
        assets/icons/dark/preview.png

        SOURCES FileManagerBridge.h FileManagerBridge.cpp
        SOURCES FileManagerSessionService.h FileManagerSessionService.cpp
        SOURCES FileManagerNavigationService.h FileManagerNavigationService.cpp
        SOURCES FileManagerFileOpsService.h FileManagerFileOpsService.cpp
        SOURCES FileManagerSearchService.h FileManagerSearchService.cpp
        SOURCES FileManagerSidebarService.h FileManagerSidebarService.cpp
        RESOURCES qml/components/theme/qmldir
        RESOURCES assets/icons/findex-color.png assets/icons/findex-plain.png
        RESOURCES appicon.rc
        RESOURCES findex.desktop
        QML_FILES qml/features/views/DetailsFileView.qml
        QML_FILES qml/features/views/TilesFileView.qml
        QML_FILES qml/features/views/CompactFileView.qml
        QML_FILES qml/features/views/LargeIconsFileView.qml
        QML_FILES qml/shared/menus/MoreActionsMenu.qml
        QML_FILES qml/shared/popups/NotificationsPopup.qml
        QML_FILES qml/shared/dialogs/ConfirmDialog.qml
        QML_FILES qml/shared/cards/DriveCard.qml
        QML_FILES qml/features/sidebar/DriveListPane.qml
        QML_FILES qml/features/sidebar/SidebarItem.qml
        QML_FILES qml/features/sidebar/SidebarTreePane.qml
        QML_FILES qml/features/breadcrumb/BreadcrumbItem.qml
        QML_FILES qml/features/breadcrumb/BreadcrumbBar.qml
        QML_FILES qml/shared/headers/ResizableHeaderCell.qml
        QML_FILES qml/shared/headers/DetailsHeaderBar.qml
        QML_FILES qml/shared/panels/PreviewPane.qml
        QML_FILES qml/features/files/FileDragPreview.qml
        QML_FILES qml/features/tabs/TabButton.qml
        QML_FILES qml/features/tabs/TabStrip.qml
        QML_FILES qml/shared/popups/SearchScopePopup.qml
        QML_FILES qml/shared/headers/AppTitleBar.qml
        QML_FILES
        QML_FILES
        QML_FILES qml/shared/panels/WorkspaceArea.qml
        QML_FILES qml/features/files/FileAreaContextMenu.qml
        QML_FILES
        QML_FILES qml/shared/layout/NavigationBar.qml
        QML_FILES qml/shared/layout/CommandBar.qml
        QML_FILES qml/shared/layout/SplitWorkspace.qml
        QML_FILES qml/shared/runtime/AppModels.qml
        QML_FILES qml/shared/runtime/AppOverlays.qml
        QML_FILES qml/shared/layout/AppShell.qml
        QML_FILES qml/shared/layout/WindowResizeHandles.qml
        QML_FILES qml/shared/popups/ToastOverlay.qml
        SOURCES ApplicationSettings.h ApplicationSettings.cpp
)

set_target_properties(Findex PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

target_link_libraries(Findex
    PRIVATE
        Qt6::Quick
        Qt6::Qml
        Qt6::QuickControls2
)

if(WIN32)
    target_link_libraries(Findex PRIVATE
        Shlwapi
        Advapi32
    )
endif()

if(APPLE)
    target_link_libraries(Findex PRIVATE
        "-framework CoreFoundation"
        "-framework CoreServices"
    )
endif()

if(UNIX AND NOT APPLE)
    target_link_libraries(Findex PRIVATE
        PkgConfig::GIO
    )
endif()

include(GNUInstallDirs)

install(TARGETS Findex
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET Findex
    OUTPUT_SCRIPT deploy_script
)
install(SCRIPT ${deploy_script})
