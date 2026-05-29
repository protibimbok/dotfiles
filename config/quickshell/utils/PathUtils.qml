pragma Singleton
import Quickshell
import QtQuick

Singleton {
    function normalizeLocalPath(p: string): string {
        if (!p || p.length === 0)
            return p;
        let s = String(p).replace(/\\/g, "/").trim();
        if (!s.startsWith("file://"))
            return s;
        s = s.substring("file://".length);
        if (s.startsWith("localhost/"))
            s = "/" + s.substring("localhost/".length);
        else if (!s.startsWith("/") && !/^[A-Za-z]:/.test(s))
            s = "/" + s;
        return s;
    }

    function home(): string {
        const raw = Quickshell.env("HOME") || "";
        return normalizeLocalPath(String(raw));
    }

    function fileUrl(path: string): string {
        if (!path || path.length === 0)
            return "";
        const norm = normalizeLocalPath(path).replace(/\\/g, "/");
        const enc = norm.split("/").map(seg => encodeURIComponent(seg)).join("/");
        return "file://" + enc;
    }
}
