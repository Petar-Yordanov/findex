#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "sidebar/SidebarViewModel.h"
#include "navigation/NavigationViewModel.h"
#include "toolbar/CommandBarViewModel.h"
#include "tabs/TabsViewModel.h"
#include "preview/PreviewPaneViewModel.h"
#include "statusbar/StatusBarViewModel.h"
#include "workspace/WorkspaceViewModel.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    SidebarViewModel sidebarViewModel;
    NavigationViewModel navigationViewModel;
    CommandBarViewModel commandBarViewModel;
    TabsViewModel tabsViewModel;
    PreviewPaneViewModel previewPaneViewModel;
    StatusBarViewModel statusBarViewModel;
    WorkspaceViewModel workspaceViewModel;

    auto refreshPreview = [&]()
    {
        const QVariantMap data = workspaceViewModel.previewData();
        if (data.isEmpty())
            previewPaneViewModel.clearPreview();
        else
            previewPaneViewModel.showPreviewData(data);
    };

    commandBarViewModel.setViewMode(workspaceViewModel.viewMode());
    statusBarViewModel.setCurrentViewMode(workspaceViewModel.viewMode());
    statusBarViewModel.setTotalItems(workspaceViewModel.totalItems());
    statusBarViewModel.setSelectedItems(workspaceViewModel.selectedItems());
    statusBarViewModel.setNotificationCount(0);

    QObject::connect(
        &commandBarViewModel,
        &CommandBarViewModel::viewModeChanged,
        [&]()
        {
            workspaceViewModel.setViewMode(commandBarViewModel.viewMode());
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::viewModeChanged,
        [&]()
        {
            commandBarViewModel.setViewMode(workspaceViewModel.viewMode());
            statusBarViewModel.setCurrentViewMode(workspaceViewModel.viewMode());
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::selectedItemsChanged,
        [&]()
        {
            statusBarViewModel.setSelectedItems(workspaceViewModel.selectedItems());
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::selectionStateChanged,
        [&]()
        {
            refreshPreview();
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::totalItemsChanged,
        [&]()
        {
            statusBarViewModel.setTotalItems(workspaceViewModel.totalItems());
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::openFileRequested,
        [](const QVariantMap& fileData)
        {
            qDebug() << "openFile:" << fileData;
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::openDirectoryRequested,
        [](const QVariantMap& directoryData)
        {
            qDebug() << "openDirectory:" << directoryData;
        });

    refreshPreview();

    engine.rootContext()->setContextProperty("appSidebarViewModel", &sidebarViewModel);
    engine.rootContext()->setContextProperty("appNavigationViewModel", &navigationViewModel);
    engine.rootContext()->setContextProperty("appCommandBarViewModel", &commandBarViewModel);
    engine.rootContext()->setContextProperty("appTabsViewModel", &tabsViewModel);
    engine.rootContext()->setContextProperty("appPreviewPaneViewModel", &previewPaneViewModel);
    engine.rootContext()->setContextProperty("appStatusBarViewModel", &statusBarViewModel);
    engine.rootContext()->setContextProperty("appWorkspaceViewModel", &workspaceViewModel);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Findex", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}