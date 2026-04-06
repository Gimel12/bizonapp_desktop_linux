"""
App updater – checks for updates via git fetch, then pulls and restarts
the app so that changed QML/Python files don't crash the running process.
"""

import os
import sys
import subprocess
from PySide6.QtCore import QObject, Signal, Slot, QThread, QProcess, QCoreApplication, QTimer

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN_PY = os.path.join(APP_DIR, "main.py")


class _UpdateWorker(QObject):
    """Worker that runs git commands in a background thread."""
    # status: "up_to_date" | "updated" | "error"
    finished = Signal(str, str)  # status, message

    def run(self):
        try:
            # Fetch latest refs
            fetch = subprocess.run(
                ["git", "fetch", "origin"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=30
            )
            if fetch.returncode != 0:
                self.finished.emit("error", "Fetch failed: " + (fetch.stderr.strip() or "unknown error"))
                return

            # Compare local vs remote
            local = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=5
            ).stdout.strip()

            remote = subprocess.run(
                ["git", "rev-parse", "origin/main"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=5
            ).stdout.strip()

            if local == remote:
                self.finished.emit("up_to_date", "Already up to date.")
                return

            # There are updates — pull them
            pull = subprocess.run(
                ["git", "pull", "origin", "main"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=60
            )

            if pull.returncode == 0:
                self.finished.emit("updated", "Update downloaded. Restarting app...")
            else:
                err = pull.stderr.strip() or pull.stdout.strip()
                self.finished.emit("error", "Pull failed: " + err)

        except subprocess.TimeoutExpired:
            self.finished.emit("error", "Timed out. Check your internet connection.")
        except Exception as e:
            self.finished.emit("error", f"Error: {e}")


class AppUpdater(QObject):
    """Exposes app update functionality to QML."""
    updateStarted = Signal()
    updateFinished = Signal(bool, str)  # success, message

    def __init__(self, parent=None):
        super().__init__(parent)
        self._thread = None
        self._worker = None
        self._updating = False

    @Slot()
    def checkForUpdates(self):
        """Check for updates and apply them if available."""
        if self._updating:
            return

        self._updating = True
        self.updateStarted.emit()

        self._thread = QThread()
        self._worker = _UpdateWorker()
        self._worker.moveToThread(self._thread)

        self._thread.started.connect(self._worker.run)
        self._worker.finished.connect(self._on_finished)
        self._worker.finished.connect(self._thread.quit)
        self._worker.finished.connect(self._worker.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)

        self._thread.start()

    def _on_finished(self, status, message):
        self._updating = False
        self._thread = None
        self._worker = None

        if status == "updated":
            # Show brief message, then restart after a short delay
            self.updateFinished.emit(True, message)
            QTimer.singleShot(1500, self._restart_app)
        elif status == "up_to_date":
            self.updateFinished.emit(True, message)
        else:
            self.updateFinished.emit(False, message)

    def _restart_app(self):
        """Restart the application by launching a new process and quitting."""
        python = sys.executable
        QProcess.startDetached(python, [MAIN_PY], APP_DIR)
        QCoreApplication.quit()
