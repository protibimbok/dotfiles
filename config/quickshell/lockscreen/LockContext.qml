import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function reset() {
        currentText = "";
        unlockInProgress = false;
        showFailure = false;
    }

    function tryUnlock() {
        if (currentText === "" || unlockInProgress)
            return;

        unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        // Resolved relative to this file: lockscreen/pam/password.conf
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.currentText);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }

        onError: {
            root.currentText = "";
            root.showFailure = true;
            root.unlockInProgress = false;
        }
    }
}
