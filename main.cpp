#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QVariantMap>
#include <QVector>
#include <QSettings>
#include <QCoreApplication>

#include "ApplicationSettings.h"

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

    QCoreApplication::setOrganizationName(QStringLiteral("Findex"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("findex.local"));
    QCoreApplication::setApplicationName(QStringLiteral("Findex"));
    QSettings::setDefaultFormat(QSettings::IniFormat);

    QQmlApplicationEngine engine;

    ApplicationSettings appSettings;

    SidebarViewModel sidebarViewModel;
    NavigationViewModel navigationViewModel;
    CommandBarViewModel commandBarViewModel;
    TabsViewModel tabsViewModel;
    PreviewPaneViewModel previewPaneViewModel;
    StatusBarViewModel statusBarViewModel;
    WorkspaceViewModel workspaceViewModel;

    commandBarViewModel.setBackend(&workspaceViewModel);
    navigationViewModel.setBackend(&workspaceViewModel);

    commandBarViewModel.setThemeMode(appSettings.theme());
    commandBarViewModel.setShowHiddenFiles(appSettings.showHiddenFiles());
    navigationViewModel.setSearchScope(appSettings.searchScope());
    previewPaneViewModel.setPreviewEnabled(appSettings.previewEnabled());

    tabsViewModel.loadState(appSettings.tabs(), appSettings.currentTabIndex());

    {
        const QVector<TabListModel::TabItem> restoredTabs = tabsViewModel.tabsModel()->tabs();
        if (!restoredTabs.isEmpty()) {
            const int current = qBound(0, tabsViewModel.currentIndex(), restoredTabs.size() - 1);
            workspaceViewModel.navigateToPathString(restoredTabs.at(current).path);
            tabsViewModel.syncCurrentTabToPath(restoredTabs.at(current).path);
        }
    }

    auto refreshPreview = [&]()
    {
        const QVariantMap data = workspaceViewModel.previewData();
        if (data.isEmpty())
            previewPaneViewModel.clearPreview();
        else
            previewPaneViewModel.showPreviewData(data);
    };

    auto syncPathState = [&]()
    {
        navigationViewModel.setPathFromBackend(workspaceViewModel.currentDirectoryPath());
        tabsViewModel.syncCurrentTabToPath(workspaceViewModel.currentDirectoryPath());
    };

    auto notify = [&](const QString& title,
                      const QString& kind = QStringLiteral("info"),
                      int progress = -1,
                      bool autoClose = true)
    {
        statusBarViewModel.pushNotification(title, QString(), kind, progress, autoClose, true);
    };

    commandBarViewModel.setViewMode(workspaceViewModel.viewMode());
    statusBarViewModel.setCurrentViewMode(workspaceViewModel.viewMode());
    statusBarViewModel.setTotalItems(workspaceViewModel.totalItems());
    statusBarViewModel.setSelectedItems(workspaceViewModel.selectedItems());
    statusBarViewModel.setNotificationCount(0);

    QObject::connect(
        &commandBarViewModel,
        &CommandBarViewModel::themeModeChanged,
        [&]()
        {
            appSettings.setTheme(commandBarViewModel.themeMode());
            notify(QStringLiteral("Theme changed to %1").arg(commandBarViewModel.themeMode()));
        });

    QObject::connect(
        &commandBarViewModel,
        &CommandBarViewModel::showHiddenFilesChanged,
        [&]()
        {
            appSettings.setShowHiddenFiles(commandBarViewModel.showHiddenFiles());
            notify(commandBarViewModel.showHiddenFiles()
                       ? QStringLiteral("Hidden files shown")
                       : QStringLiteral("Hidden files hidden"));
        });

    QObject::connect(
        &navigationViewModel,
        &NavigationViewModel::searchScopeChanged,
        [&]()
        {
            appSettings.setSearchScope(navigationViewModel.searchScope());
        });

    QObject::connect(
        &previewPaneViewModel,
        &PreviewPaneViewModel::previewEnabledChanged,
        [&]()
        {
            appSettings.setPreviewEnabled(previewPaneViewModel.previewEnabled());
            notify(previewPaneViewModel.previewEnabled()
                       ? QStringLiteral("Preview enabled")
                       : QStringLiteral("Preview hidden"));
        });

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
        &WorkspaceViewModel::currentDirectoryPathChanged,
        [&]()
        {
            syncPathState();
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::fileDropRequested,
        [&](const QVariantList& draggedItems, const QString& targetPath, const QString& targetKind)
        {
            qDebug() << "fileDropRequested:";
            qDebug() << "  targetPath =" << targetPath;
            qDebug() << "  targetKind =" << targetKind;
            qDebug() << "  draggedItems =" << draggedItems;
            workspaceViewModel.performDropOperation(draggedItems, targetPath);
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::fileDragFinished,
        [&](bool accepted, const QString& targetPath, const QString& targetKind)
        {
            qDebug() << "fileDragFinished:" << accepted << targetPath << targetKind;

            if (!accepted) {
                notify(QStringLiteral("Drop cancelled"), QStringLiteral("warning"));
            }
        });

    QObject::connect(
        &sidebarViewModel,
        &SidebarViewModel::openRequested,
        [&](const QString& label, const QString& icon, const QString& kind, const QString& path)
        {
            Q_UNUSED(label);
            Q_UNUSED(icon);
            Q_UNUSED(kind);

            if (!workspaceViewModel.commitInlineEdit())
                return;

            workspaceViewModel.navigateToPathString(path);

            statusBarViewModel.setTotalItems(workspaceViewModel.totalItems());
            statusBarViewModel.setSelectedItems(workspaceViewModel.selectedItems());

            syncPathState();
            refreshPreview();

            notify(QStringLiteral("Open location: %1").arg(path));
        });

    QObject::connect(
        &sidebarViewModel,
        &SidebarViewModel::openInNewTabRequested,
        [&](const QString& label, const QString& icon, const QString& kind, const QString& path)
        {
            Q_UNUSED(icon);
            Q_UNUSED(kind);

            if (!workspaceViewModel.commitInlineEdit())
                return;

            tabsViewModel.addTab();
            workspaceViewModel.navigateToPathString(path);
            tabsViewModel.syncCurrentTabToPath(path);

            syncPathState();
            refreshPreview();

            notify(QStringLiteral("Opened in new tab: %1").arg(label.isEmpty() ? path : label));
        });

    QObject::connect(
        &tabsViewModel,
        &TabsViewModel::tabsStateChanged,
        [&]()
        {
            appSettings.setTabs(tabsViewModel.saveState());
            appSettings.setCurrentTabIndex(tabsViewModel.currentIndex());
        });

    QObject::connect(
        &tabsViewModel,
        &TabsViewModel::tabActivated,
        [&](int index, const QString& title, const QString& path)
        {
            Q_UNUSED(index);
            Q_UNUSED(title);

            if (!workspaceViewModel.commitInlineEdit())
                return;

            workspaceViewModel.navigateToPathString(path);
            tabsViewModel.syncCurrentTabToPath(path);
            refreshPreview();
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::operationCompleted,
        [&](const QString& message)
        {
            notify(message, QStringLiteral("success"));
        });

    QObject::connect(
        &workspaceViewModel,
        &WorkspaceViewModel::operationFailed,
        [&](const QString& message)
        {
            notify(message, QStringLiteral("error"));
        });

    {
        auto* progressNotificationId = new int(-1);

        QObject::connect(
            &workspaceViewModel,
            &WorkspaceViewModel::operationProgress,
            &statusBarViewModel,
            [&, progressNotificationId](const QString& title,
                                        const QString& details,
                                        int progress,
                                        bool done)
            {
                if (*progressNotificationId < 0) {
                    *progressNotificationId = statusBarViewModel.pushNotification(
                        title,
                        details,
                        QStringLiteral("progress"),
                        progress,
                        false,
                        true);
                } else {
                    statusBarViewModel.updateNotificationProgress(
                        *progressNotificationId,
                        progress,
                        done,
                        details,
                        title);
                }

                if (done)
                    *progressNotificationId = -1;
            });
    }

    syncPathState();
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