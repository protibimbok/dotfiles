pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string fallback: "application-x-executable"

    // Manual window-class → icon-name overrides for apps whose class matches no
    // icon and no desktop-entry StartupWMClass (e.g. VirtualBox VM windows).
    readonly property var classOverrides: ({
        "VirtualBox Machine": "virtualbox",
        "VirtualBox Manager": "virtualbox"
    })

    // Check-mode lookup: returns a concrete path, or "" if the icon doesn't
    // exist (never hands Image a failing "name?fallback=…" URL that would warn).
    function _resolve(name: string): string {
        if (!name || name.length === 0)
            return "";
        let n = name;
        const q = n.indexOf("?");
        if (q >= 0)
            n = n.slice(0, q);
        let p = Quickshell.iconPath(n, true);
        return (p && p.length) ? p : "";
    }

    function app(iconName: string): string {
        let p = _resolve(iconName);
        return p.length ? p : _resolve(fallback);
    }

    function forWindowClass(cls: string): string {
        if (!cls || cls.length === 0)
            return "";

        // 1. explicit override
        if (classOverrides[cls]) {
            let o = _resolve(classOverrides[cls]);
            if (o.length)
                return o;
        }

        // 2. desktop entry icon (matches by StartupWMClass / name)
        let entry = DesktopEntries.heuristicLookup(cls);
        if (entry && entry.icon && entry.icon.length > 0) {
            let p = _resolve(entry.icon);
            if (p.length)
                return p;
        }

        // 3. the class itself, then common normalizations
        //    ("VirtualBox Machine" → "virtualbox", "Foo Bar" → "foo")
        let lower = cls.toLowerCase();
        let firstWord = lower.split(" ")[0];
        let candidates = [cls, lower, firstWord];
        for (let i = 0; i < candidates.length; i++) {
            let p = _resolve(candidates[i]);
            if (p.length)
                return p;
        }

        // 4. generic fallback ("" → caller shows a placeholder)
        return _resolve(fallback);
    }
}
