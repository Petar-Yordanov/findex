#pragma once

#include <QString>
#include <QVariantList>

class ApplicationSettings final
{
public:
    ApplicationSettings();

    QString theme() const;
    void setTheme(const QString& theme);

    bool previewEnabled() const;
    void setPreviewEnabled(bool enabled);

    QString searchScope() const;
    void setSearchScope(const QString& scope);

    QString viewMode() const;
    void setViewMode(const QString& viewMode);

    bool showHiddenFiles() const;
    void setShowHiddenFiles(bool enabled);

    QVariantList tabs() const;
    void setTabs(const QVariantList& tabs);

    int currentTabIndex() const;
    void setCurrentTabIndex(int index);

private:
    void ensureDefaults() const;
};