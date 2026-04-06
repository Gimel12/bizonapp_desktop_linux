"""
Bizon App v2 — Qt 6 + QML Tesla-style diagnostic workstation app.
"""
import sys
import os

# ── Force GPU-accelerated OpenGL rendering (must be set before any Qt imports) ─
# Without these, Qt tries Vulkan → fails on NVIDIA → falls back to extremely
# slow software rendering.
os.environ.setdefault("QSG_RHI_BACKEND", "opengl")
os.environ.setdefault("QTWEBENGINE_CHROMIUM_FLAGS",
                       "--disable-vulkan --enable-gpu-rasterization --enable-native-gpu-memory-buffers")
os.environ.setdefault("QT_OPENGL", "desktop")

# Must be called before QApplication is created
from PySide6.QtWebEngineQuick import QtWebEngineQuick
QtWebEngineQuick.initialize()

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtCore import QUrl

from backend.chat_handler import ChatHandler

__version__ = "2.0.0"


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Bizon App")
    app.setApplicationVersion(__version__)
    app.setOrganizationName("Bizon Tech")

    icon_path = os.path.join(os.path.dirname(__file__), "ico.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    # Register Python types for QML
    qmlRegisterType(ChatHandler, "BizonBackend", 1, 0, "ChatHandler")

    engine = QQmlApplicationEngine()

    # Add QML import path
    qml_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "qml")
    engine.addImportPath(qml_dir)

    # Load root QML
    qml_file = os.path.join(qml_dir, "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        print("Failed to load QML. Check for errors above.", file=sys.stderr)
        sys.exit(1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
