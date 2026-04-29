pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property var notifications: []
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
        onTriggered: root._pruneExpired()
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
        }
    }

    function clearAll() {
        for (let i = 0; i < notifications.length; i++) {
            let n = notifications[i];
            if (n._notifObj) n._notifObj.dismiss();
        }
        notifications = [];
        unreadCount = 0;
    }

    function markRead() {
        let list = notifications.slice();
        for (let i = 0; i < list.length; i++) list[i].read = true;
        notifications = list;
        unreadCount = 0;
    }
}
