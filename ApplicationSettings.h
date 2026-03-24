#pragma once

#include <QString>

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

private:
    void ensureDefaults() const;
};