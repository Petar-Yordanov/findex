#include "ApplicationSettings.h"

#include <QSettings>

namespace {
    static const QString kThemeKey = QStringLiteral("theme");
    static const QString kPreviewEnabledKey = QStringLiteral("previewEnabled");
    static const QString kSearchScopeKey = QStringLiteral("searchScope");
    static const QString kViewModeKey = QStringLiteral("viewMode");
    static const QString kShowHiddenFilesKey = QStringLiteral("showHiddenFiles");

    static const QString kDefaultTheme = QStringLiteral("Light");
    static const bool kDefaultPreviewEnabled = true;
    static const QString kDefaultSearchScope = QStringLiteral("folder");
    static const QString kDefaultViewMode = QStringLiteral("Details");
    static const bool kDefaultShowHiddenFiles = false;
}

ApplicationSettings::ApplicationSettings()
{
    ensureDefaults();
}

void ApplicationSettings::ensureDefaults() const
{
    QSettings settings;

    if (!settings.contains(kThemeKey))
        settings.setValue(kThemeKey, kDefaultTheme);

    if (!settings.contains(kPreviewEnabledKey))
        settings.setValue(kPreviewEnabledKey, kDefaultPreviewEnabled);

    if (!settings.contains(kSearchScopeKey))
        settings.setValue(kSearchScopeKey, kDefaultSearchScope);

    if (!settings.contains(kViewModeKey))
        settings.setValue(kViewModeKey, kDefaultViewMode);

    if (!settings.contains(kShowHiddenFilesKey))
        settings.setValue(kShowHiddenFilesKey, kDefaultShowHiddenFiles);
}

QString ApplicationSettings::theme() const
{
    QSettings settings;
    return settings.value(kThemeKey, kDefaultTheme).toString();
}

void ApplicationSettings::setTheme(const QString& theme)
{
    const QString normalized = theme.trimmed().isEmpty()
    ? kDefaultTheme
    : theme.trimmed();

    QSettings settings;
    settings.setValue(kThemeKey, normalized);
}

bool ApplicationSettings::previewEnabled() const
{
    QSettings settings;
    return settings.value(kPreviewEnabledKey, kDefaultPreviewEnabled).toBool();
}

void ApplicationSettings::setPreviewEnabled(bool enabled)
{
    QSettings settings;
    settings.setValue(kPreviewEnabledKey, enabled);
}

QString ApplicationSettings::searchScope() const
{
    QSettings settings;
    return settings.value(kSearchScopeKey, kDefaultSearchScope).toString();
}

void ApplicationSettings::setSearchScope(const QString& scope)
{
    const QString normalized = scope.trimmed().isEmpty()
    ? kDefaultSearchScope
    : scope.trimmed();

    QSettings settings;
    settings.setValue(kSearchScopeKey, normalized);
}

QString ApplicationSettings::viewMode() const
{
    QSettings settings;
    return settings.value(kViewModeKey, kDefaultViewMode).toString();
}

void ApplicationSettings::setViewMode(const QString& viewMode)
{
    const QString normalized = viewMode.trimmed().isEmpty()
    ? kDefaultViewMode
    : viewMode.trimmed();

    QSettings settings;
    settings.setValue(kViewModeKey, normalized);
}

bool ApplicationSettings::showHiddenFiles() const
{
    QSettings settings;
    return settings.value(kShowHiddenFilesKey, kDefaultShowHiddenFiles).toBool();
}

void ApplicationSettings::setShowHiddenFiles(bool enabled)
{
    QSettings settings;
    settings.setValue(kShowHiddenFilesKey, enabled);
}