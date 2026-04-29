pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string fallback: "application-x-executable"

    function app(iconName: string): string {
        if (!iconName || iconName.length === 0)
            return Quickshell.iconPath(fallback, fallback);
        let name = iconName;
        const q = name.indexOf("?");
        if (q >= 0)
            name = name.slice(0, q);
        if (!name.length)
            return Quickshell.iconPath(fallback, fallback);
        return Quickshell.iconPath(name, fallback);
    }

    function forWindowClass(cls: string): string {
        if (!cls || cls.length === 0)
            return "";
        let entry = DesktopEntries.heuristicLookup(cls);
        if (entry && entry.icon && entry.icon.length > 0)
            return app(entry.icon);
        return app(cls);
    }
}
