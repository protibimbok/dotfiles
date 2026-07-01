pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.tokens

Singleton {
    id: root

    property var notifications: []
    /// Notifications currently shown as on-screen toasts (newest first).
    property var popups: []
    readonly property int maxPopups: 5
    /// True while the cursor is over the toast stack — pauses toast expiry so a
    /// notification being read (or about to be clicked) never vanishes underneath.
    property bool popupsHovered: false
    property double _popupsHoverSince: 0
    property int unreadCount: 0
    /// 0 = silent (block all), 1 = normal, 2 = priority (all alerts)
    property int dndMode: 1
    readonly property bool dndEnabled: dndMode === 0

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: false

        onNotification: notification => {
            notification.tracked = true;

            let timeout = notification.expireTimeout;
            let now = Date.now();
            let expiresAt;
            // Freedesktop: 0 = never expire, -1 = server default (we keep until dismissed).
            if (timeout === 0 || timeout < 0) {
                expiresAt = -1;
            } else {
                expiresAt = now + timeout;
            }

            let notif = {
                id: notification.id,
                appName: notification.appName || "",
                appIcon: notification.appIcon || "",
                summary: notification.summary || "",
                body: notification.body || "",
                ts: now,
                timeAgo: "now",
                read: false,
                expiresAt: expiresAt,
                _notifObj: notification
            };

            let list = root.notifications.slice();
            let existing = list.findIndex(n => n.id === notif.id);
            if (existing >= 0) {
                list[existing] = notif;
            } else {
                list.unshift(notif);
            }

            if (list.length > 50) list = list.slice(0, 50);
            root.notifications = list;
            root._syncUnreadCount();

            // Surface a transient toast (unless Do Not Disturb is silencing).
            if (root.dndMode !== 0)
                root._pushPopup(notif, timeout);
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root._updateTimeAgo()
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            root._pruneExpired();
            root._prunePopups();
        }
    }

    function _pushPopup(notif: var, timeout: int) {
        // Toasts live for the app-supplied timeout, falling back to a default.
        let life = timeout > 0 ? timeout : Durations.toastLife;
        let entry = {
            id: notif.id,
            appName: notif.appName,
            appIcon: notif.appIcon,
            summary: notif.summary,
            body: notif.body,
            expiresAt: Date.now() + life
        };

        let list = root.popups.slice();
        let existing = list.findIndex(p => p.id === entry.id);
        if (existing >= 0)
            list[existing] = entry;
        else
            list.unshift(entry);

        if (list.length > maxPopups) list = list.slice(0, maxPopups);
        root.popups = list;
    }

    // Freeze the countdown while hovered; on release, push every toast's expiry out
    // by however long the cursor lingered so the remaining lifetime is preserved.
    onPopupsHoveredChanged: {
        if (popupsHovered) {
            _popupsHoverSince = Date.now();
        } else if (_popupsHoverSince > 0) {
            let paused = Date.now() - _popupsHoverSince;
            _popupsHoverSince = 0;
            if (paused > 0 && popups.length > 0) {
                let list = popups.slice();
                for (let i = 0; i < list.length; i++)
                    list[i].expiresAt += paused;
                popups = list;
            }
        }
    }

    function _prunePopups() {
        if (root.popupsHovered)
            return;
        let now = Date.now();
        let list = popups.slice();
        let changed = false;
        for (let i = list.length - 1; i >= 0; i--) {
            if (now >= list[i].expiresAt) {
                list.splice(i, 1);
                changed = true;
            }
        }
        if (changed) popups = list;
    }

    function dismissPopup(id: int) {
        let list = popups.slice();
        let idx = list.findIndex(p => p.id === id);
        if (idx >= 0) {
            list.splice(idx, 1);
            popups = list;
        }
    }

    function _syncUnreadCount() {
        let n = 0;
        for (let i = 0; i < notifications.length; i++) {
            if (!notifications[i].read) n++;
        }
        unreadCount = n;
    }

    function _pruneExpired() {
        let now = Date.now();
        let list = notifications.slice();
        let changed = false;
        for (let i = list.length - 1; i >= 0; i--) {
            if (list[i].expiresAt > 0 && now >= list[i].expiresAt) {
                if (list[i]._notifObj) list[i]._notifObj.dismiss();
                list.splice(i, 1);
                changed = true;
            }
        }
        if (changed) {
            notifications = list;
            _syncUnreadCount();
        }
    }

    function _updateTimeAgo() {
        let now = Date.now();
        let list = notifications.slice();
        let changed = false;
        for (let i = 0; i < list.length; i++) {
            let diff = now - list[i].ts;
            let newAgo;
            if (diff < 60000) newAgo = "now";
            else if (diff < 3600000) newAgo = Math.floor(diff / 60000) + "m ago";
            else if (diff < 86400000) newAgo = Math.floor(diff / 3600000) + "h ago";
            else newAgo = Math.floor(diff / 86400000) + "d ago";
            if (list[i].timeAgo !== newAgo) {
                list[i].timeAgo = newAgo;
                changed = true;
            }
        }
        if (changed) notifications = list;
    }

    function dismiss(id: int) {
        let list = notifications.slice();
        let idx = list.findIndex(n => n.id === id);
        if (idx >= 0) {
            let notif = list[idx];
            if (notif._notifObj) notif._notifObj.dismiss();
            list.splice(idx, 1);
            root.notifications = list;
            _syncUnreadCount();
            dismissPopup(id);
        }
    }

    function clearAll() {
        for (let i = 0; i < notifications.length; i++) {
            let n = notifications[i];
            if (n._notifObj) n._notifObj.dismiss();
        }
        notifications = [];
        popups = [];
        unreadCount = 0;
    }

    function markRead() {
        let list = notifications.slice();
        for (let i = 0; i < list.length; i++) list[i].read = true;
        notifications = list;
        unreadCount = 0;
    }
}
