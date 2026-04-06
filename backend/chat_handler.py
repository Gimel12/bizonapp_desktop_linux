"""
ChatHandler — QObject bridge between QML chat UI and the Bizon diagnostic API.

Communicates with http://localhost:4000/api/diagnostic/chat via NDJSON streaming.
Emits signals that QML connects to for updating the chat view.

System Prompt:
  Reads from system_prompt.md in the app directory. This file is version-controlled
  so pushing updates to GitHub and running the app updater distributes the prompt
  to all clients. The prompt is sent with every API request and used by both
  Claude and Ollama backends.
"""
import json
import os

from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QByteArray
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest, QNetworkReply

# ── System prompt file path ──────────────────────────────────────────────────
_APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYSTEM_PROMPT_PATH = os.path.join(_APP_DIR, "system_prompt.md")


class ChatHandler(QObject):
    """Manages chat API communication and exposes it to QML."""

    API_URL = "http://localhost:4000/api/diagnostic/chat"

    # ── Signals for QML ──────────────────────────────────────────────────
    userMessageAdded = Signal(str)
    assistantMessageAdded = Signal(str)
    commandStarted = Signal(str, int)           # command, iteration
    commandFinished = Signal(str, int, str)     # command, durationMs, error
    statusChanged = Signal(str)                 # status text
    errorOccurred = Signal(str)                 # error text
    usageInfo = Signal(str)                     # usage summary string
    busyChanged = Signal()
    backendChanged = Signal()
    systemPromptChanged = Signal()
    systemPromptSaved = Signal(bool, str)       # success, message
    ollamaModelsChanged = Signal()
    modelChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._messages = []
        self._busy = False
        self._backend = "ollama"
        self._model = ""
        self._ollama_models = []
        self._buffer = ""
        self._network = QNetworkAccessManager(self)
        self._reply = None
        self._models_reply = None
        self._system_prompt = ""
        self._load_system_prompt()
        self._fetch_ollama_models()

    # ── System Prompt ────────────────────────────────────────────────────

    def _load_system_prompt(self):
        """Load system prompt from the file on disk."""
        try:
            with open(SYSTEM_PROMPT_PATH, "r", encoding="utf-8") as f:
                self._system_prompt = f.read()
        except FileNotFoundError:
            self._system_prompt = ""
            print(f"[ChatHandler] system_prompt.md not found at {SYSTEM_PROMPT_PATH}")
        except Exception as e:
            self._system_prompt = ""
            print(f"[ChatHandler] Error reading system_prompt.md: {e}")

    @Property(str, notify=systemPromptChanged)
    def systemPrompt(self):
        return self._system_prompt

    @Slot(str)
    def setSystemPrompt(self, text):
        """Update the in-memory system prompt (does NOT save to disk)."""
        if self._system_prompt != text:
            self._system_prompt = text
            self.systemPromptChanged.emit()

    @Slot(str)
    def saveSystemPrompt(self, text):
        """Save the system prompt to disk and update in-memory copy."""
        try:
            with open(SYSTEM_PROMPT_PATH, "w", encoding="utf-8") as f:
                f.write(text)
            self._system_prompt = text
            self.systemPromptChanged.emit()
            self.systemPromptSaved.emit(True, "System prompt saved successfully.")
        except Exception as e:
            self.systemPromptSaved.emit(False, f"Failed to save: {e}")

    @Slot()
    def reloadSystemPrompt(self):
        """Re-read the system prompt from disk (e.g. after a git pull)."""
        self._load_system_prompt()
        self.systemPromptChanged.emit()

    @Property(str, constant=True)
    def systemPromptPath(self):
        """Expose the file path to QML for display."""
        return SYSTEM_PROMPT_PATH

    # ── Ollama Models ──────────────────────────────────────────────────

    def _fetch_ollama_models(self):
        """Fetch available models from the local Ollama instance."""
        req = QNetworkRequest(QUrl("http://localhost:11434/api/tags"))
        req.setTransferTimeout(5000)
        self._models_reply = self._network.get(req)
        self._models_reply.finished.connect(self._on_models_fetched)

    def _on_models_fetched(self):
        """Parse the Ollama /api/tags response."""
        reply = self._models_reply
        self._models_reply = None
        if not reply:
            return
        if reply.error() != reply.NetworkError.NoError:
            print(f"[ChatHandler] Failed to fetch Ollama models: {reply.errorString()}")
            reply.deleteLater()
            return
        try:
            data = json.loads(bytes(reply.readAll().data()).decode("utf-8"))
            names = [m["name"] for m in data.get("models", [])]
            self._ollama_models = sorted(names)
            if self._ollama_models and not self._model:
                self._model = self._ollama_models[0]
                self.modelChanged.emit()
            self.ollamaModelsChanged.emit()
        except Exception as e:
            print(f"[ChatHandler] Error parsing Ollama models: {e}")
        finally:
            reply.deleteLater()

    @Property("QVariantList", notify=ollamaModelsChanged)
    def ollamaModels(self):
        return self._ollama_models

    @Slot()
    def refreshModels(self):
        """Re-fetch Ollama models (e.g. after installing a new one)."""
        self._fetch_ollama_models()

    @Property(str, notify=modelChanged)
    def model(self):
        return self._model

    @Slot(str)
    def setModel(self, value):
        if self._model != value:
            self._model = value
            self.modelChanged.emit()

    # ── Properties ───────────────────────────────────────────────────────

    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    def _set_busy(self, v):
        if self._busy != v:
            self._busy = v
            self.busyChanged.emit()

    @Property(str, notify=backendChanged)
    def backend(self):
        return self._backend

    @backend.setter
    def backend(self, value):
        if self._backend != value:
            self._backend = value
            self.backendChanged.emit()

    @Slot(str)
    def setBackend(self, value):
        self.backend = value.lower()

    # ── Public Slots ─────────────────────────────────────────────────────

    @Slot(str)
    def sendMessage(self, text):
        text = text.strip()
        if not text or self._busy:
            return

        self.userMessageAdded.emit(text)
        self._messages.append({"role": "user", "content": text})
        self._set_busy(True)
        self._buffer = ""
        self._fire_request()

    @Slot()
    def clearChat(self):
        if self._reply:
            self._reply.abort()
        self._messages.clear()
        self._buffer = ""
        self._set_busy(False)

    # ── Network ──────────────────────────────────────────────────────────

    def _fire_request(self):
        body = {
            "messages": self._messages,
            "backend": self._backend,
        }
        # Include selected model if set
        if self._model:
            body["model"] = self._model
        # Include system prompt so the API uses our managed version
        if self._system_prompt.strip():
            body["systemPrompt"] = self._system_prompt

        req = QNetworkRequest(QUrl(self.API_URL))
        req.setHeader(QNetworkRequest.KnownHeaders.ContentTypeHeader,
                       "application/json")
        req.setTransferTimeout(120000)

        data = QByteArray(json.dumps(body).encode("utf-8"))
        self._reply = self._network.post(req, data)
        self._reply.readyRead.connect(self._on_ready_read)
        self._reply.finished.connect(self._on_finished)
        self._reply.errorOccurred.connect(self._on_error)

    def _on_ready_read(self):
        if not self._reply:
            return
        raw = bytes(self._reply.readAll()).decode("utf-8", errors="replace")
        self._buffer += raw

        while "\n" in self._buffer:
            line, self._buffer = self._buffer.split("\n", 1)
            line = line.strip()
            if not line:
                continue
            try:
                self._handle_event(json.loads(line))
            except json.JSONDecodeError:
                pass

    def _handle_event(self, ev):
        t = ev.get("type", "")

        if t == "status":
            self.statusChanged.emit(ev.get("message", ""))

        elif t == "command":
            self.commandStarted.emit(
                ev.get("command", ""), ev.get("iteration", 0)
            )

        elif t == "command_done":
            self.commandFinished.emit(
                ev.get("command", ""),
                ev.get("duration", 0),
                ev.get("error", ""),
            )

        elif t == "result":
            content = ev.get("result") or ev.get("content", "")
            self.assistantMessageAdded.emit(content)

            usage = ev.get("usage", {})
            tokens = usage.get("totalTokens", 0)
            cmds = usage.get("toolCalls", 0)
            backend = ev.get("backend", "")
            model = ev.get("model", "")
            parts = []
            if tokens:
                parts.append(f"{tokens:,} tokens")
            if cmds:
                parts.append(f"{cmds} commands")
            if backend:
                bname = backend
                if model and model != "default":
                    short = model.split("/")[-1] if "/" in model else model
                    bname += f" \u00B7 {short}"
                parts.append(bname)
            if parts:
                self.usageInfo.emit("  \u2022  ".join(parts))

            self._messages.append({"role": "assistant", "content": content})

        elif t == "error":
            self.errorOccurred.emit(ev.get("error", "Unknown error"))

    def _on_error(self, code):
        if code == QNetworkReply.NetworkError.NoError:
            return
        if code == QNetworkReply.NetworkError.ConnectionRefusedError:
            self.errorOccurred.emit(
                "Cannot connect to Bizon API. Is the service running?"
            )
        elif code == QNetworkReply.NetworkError.TimeoutError:
            self.errorOccurred.emit(
                "Request timed out. The AI may still be processing."
            )
        else:
            self.errorOccurred.emit(f"Network error ({code})")

    def _on_finished(self):
        if self._buffer.strip():
            try:
                self._handle_event(json.loads(self._buffer.strip()))
            except json.JSONDecodeError:
                pass
        self._buffer = ""

        if self._reply:
            self._reply.deleteLater()
            self._reply = None

        self._set_busy(False)
