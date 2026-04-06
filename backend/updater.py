"""
App updater – uses QProcess to run git commands asynchronously.
Checks for updates, pulls if available, and restarts the app.
"""

import os
import sys
from PySide6.QtCore import QObject, Signal, Slot, QProcess, QCoreApplication, QTimer

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class AppUpdater(QObject):
    """Exposes app update functionality to QML."""
    updateStarted = Signal()
    updateFinished = Signal(bool, str)  # success, message

    def __init__(self, parent=None):
        super().__init__(parent)
        self._updating = False
        self._step = ""         # current step: fetch, local, remote, pull
        self._proc = None
        self._local_hash = ""
        self._remote_hash = ""

    @Slot()
    def checkForUpdates(self):
        """Check for updates and apply them if available."""
        if self._updating:
            return
        self._updating = True
        self.updateStarted.emit()
        self._run_fetch()

    # ── Step 1: git fetch origin ───────────────────────────────────────
    def _run_fetch(self):
        self._step = "fetch"
        self._proc = QProcess(self)
        self._proc.setWorkingDirectory(APP_DIR)
        self._proc.finished.connect(self._on_step_finished)
        self._proc.start("git", ["fetch", "origin"])

    # ── Step 2: git rev-parse HEAD ─────────────────────────────────────
    def _run_local_hash(self):
        self._step = "local"
        self._proc = QProcess(self)
        self._proc.setWorkingDirectory(APP_DIR)
        self._proc.finished.connect(self._on_step_finished)
        self._proc.start("git", ["rev-parse", "HEAD"])

    # ── Step 3: git rev-parse origin/main ──────────────────────────────
    def _run_remote_hash(self):
        self._step = "remote"
        self._proc = QProcess(self)
        self._proc.setWorkingDirectory(APP_DIR)
        self._proc.finished.connect(self._on_step_finished)
        self._proc.start("git", ["rev-parse", "origin/main"])

    # ── Step 4: git pull origin main ───────────────────────────────────
    def _run_pull(self):
        self._step = "pull"
        self._proc = QProcess(self)
        self._proc.setWorkingDirectory(APP_DIR)
        self._proc.finished.connect(self._on_step_finished)
        self._proc.start("git", ["pull", "origin", "main"])

    # ── Dispatcher ─────────────────────────────────────────────────────
    def _on_step_finished(self, exitCode, exitStatus):
        proc = self._proc
        self._proc = None
        if proc:
            proc.deleteLater()

        try:
            if self._step == "fetch":
                if exitCode != 0:
                    self._done(False, "Fetch failed. Check your internet connection.")
                    return
                self._run_local_hash()

            elif self._step == "local":
                self._local_hash = bytes(proc.readAllStandardOutput()).decode().strip()
                self._run_remote_hash()

            elif self._step == "remote":
                self._remote_hash = bytes(proc.readAllStandardOutput()).decode().strip()
                if self._local_hash == self._remote_hash:
                    self._done(True, "Already up to date.")
                else:
                    self._run_pull()

            elif self._step == "pull":
                if exitCode == 0:
                    self._done(True, "Update complete! Restarting...")
                    QTimer.singleShot(1500, self._restart_app)
                    return
                else:
                    stderr = bytes(proc.readAllStandardError()).decode().strip()
                    self._done(False, "Pull failed: " + (stderr or "unknown error"))

        except Exception as e:
            self._done(False, f"Error: {e}")

    def _done(self, success, message):
        self._updating = False
        self._step = ""
        self.updateFinished.emit(success, message)

    def _restart_app(self):
        """Restart the application via bash + conda, same as the .desktop launcher."""
        cmd = (
            "source /home/bizon/anaconda3/bin/activate base && "
            f"cd {APP_DIR} && python3 main.py"
        )
        QProcess.startDetached("bash", ["-c", cmd], APP_DIR)
        QCoreApplication.quit()
