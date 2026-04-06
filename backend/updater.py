"""
App updater – runs `git pull` in the app directory and reports the result.
Runs in a background thread so the UI stays responsive.
"""

import os
import subprocess
from PySide6.QtCore import QObject, Signal, Slot, QThread

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class _PullWorker(QObject):
    """Worker that runs git commands in a background thread."""
    finished = Signal(bool, str)  # success, message

    def run(self):
        try:
            # Fetch first to check if there are updates
            subprocess.run(
                ["git", "fetch", "origin"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=30
            )

            # Check if we're behind
            status = subprocess.run(
                ["git", "status", "-uno"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=10
            )

            if "Your branch is up to date" in status.stdout:
                self.finished.emit(True, "Already up to date.")
                return

            # Pull latest changes
            result = subprocess.run(
                ["git", "pull", "origin", "main"],
                cwd=APP_DIR, capture_output=True, text=True, timeout=60
            )

            if result.returncode == 0:
                # Count what changed
                lines = result.stdout.strip().split('\n')
                self.finished.emit(True, "Update complete. Please restart the app to apply changes.")
            else:
                err = result.stderr.strip() or result.stdout.strip()
                self.finished.emit(False, f"Update failed: {err}")

        except subprocess.TimeoutExpired:
            self.finished.emit(False, "Update timed out. Check your internet connection.")
        except Exception as e:
            self.finished.emit(False, f"Update error: {e}")


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
        """Run git pull in a background thread."""
        if self._updating:
            return

        self._updating = True
        self.updateStarted.emit()

        self._thread = QThread()
        self._worker = _PullWorker()
        self._worker.moveToThread(self._thread)

        self._thread.started.connect(self._worker.run)
        self._worker.finished.connect(self._on_finished)
        self._worker.finished.connect(self._thread.quit)
        self._worker.finished.connect(self._worker.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)

        self._thread.start()

    def _on_finished(self, success, message):
        self._updating = False
        self._thread = None
        self._worker = None
        self.updateFinished.emit(success, message)
