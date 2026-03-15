cmake_minimum_required(VERSION 3.16)

project(FileExplorer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Core)

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
        Main.qml
        AppIcon.qml
    RESOURCES
        resources.qrc
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
        Qt6::Core
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
