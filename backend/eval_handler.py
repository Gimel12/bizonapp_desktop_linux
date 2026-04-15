"""
EvalHandler — Side-by-side model comparison for the Bizon App.

Sends the same prompt to two different model/backend combos via the
diagnostic chat API and streams results back to the QML EvalView.
"""
import json
import os
import time

from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QByteArray
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest, QNetworkReply

_APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYSTEM_PROMPT_PATH = os.path.join(_APP_DIR, "system_prompt.md")

API_URL = "http://localhost:4000/api/diagnostic/chat"


class _ModelSlot(QObject):
    """Handles a single API request for one side of the comparison."""

    finished = Signal(str, str, str)  # side ("A"|"B"), result text, usage JSON
    errored = Signal(str, str)          # side, error text
    statusUpdate = Signal(str, str)     # side, status message

    def __init__(self, side, network, parent=None):
        super().__init__(parent)
        self._side = side
        self._network = network
        self._reply = None
        self._buffer = ""
        self._result = ""
        self._usage = {}
        self._start_time = 0

    def fire(self, prompt, backend, model, system_prompt):
        body = {
            "messages": [{"role": "user", "content": prompt}],
            "backend": backend,
        }
        if model and backend == "ollama":
            body["model"] = model
        if system_prompt and system_prompt.strip():
            body["systemPrompt"] = system_prompt

        req = QNetworkRequest(QUrl(API_URL))
        req.setHeader(QNetworkRequest.KnownHeaders.ContentTypeHeader,
                      "application/json")
        req.setTransferTimeout(120000)

        self._start_time = time.monotonic()
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
            self.statusUpdate.emit(self._side, ev.get("message", ""))
        elif t == "result":
            content = ev.get("result") or ev.get("content", "")
            self._result = content
            self._usage = ev.get("usage", {})
        elif t == "error":
            self.errored.emit(self._side, ev.get("error", "Unknown error"))

    def _on_error(self, code):
        if code == QNetworkReply.NetworkError.NoError:
            return
        if code == QNetworkReply.NetworkError.ConnectionRefusedError:
            self.errored.emit(self._side,
                              "Cannot connect to Bizon API. Is the service running?")
        elif code == QNetworkReply.NetworkError.TimeoutError:
            self.errored.emit(self._side, "Request timed out.")
        else:
            self.errored.emit(self._side, f"Network error ({code})")

    def _on_finished(self):
        if self._buffer.strip():
            try:
                self._handle_event(json.loads(self._buffer.strip()))
            except json.JSONDecodeError:
                pass
        self._buffer = ""
        if self._result:
            elapsed_ms = int((time.monotonic() - self._start_time) * 1000) if self._start_time else 0
            usage = self._usage or {}
            output_tokens = usage.get("outputTokens", 0)
            elapsed_s = elapsed_ms / 1000.0 if elapsed_ms > 0 else 0
            tps = round(output_tokens / elapsed_s, 1) if elapsed_s > 0 and output_tokens > 0 else 0
            stats = {
                "inputTokens": usage.get("inputTokens", 0),
                "outputTokens": output_tokens,
                "totalTokens": usage.get("totalTokens", 0),
                "toolCalls": usage.get("toolCalls", 0),
                "elapsedMs": elapsed_ms,
                "tokensPerSecond": tps,
            }
            self.finished.emit(self._side, self._result, json.dumps(stats))
        if self._reply:
            self._reply.deleteLater()
            self._reply = None

    def abort(self):
        if self._reply:
            self._reply.abort()


class EvalHandler(QObject):
    """Exposes side-by-side model comparison to QML."""

    # ── Signals for QML ──────────────────────────────────────────────────
    resultReady = Signal(str, str, str)  # side ("A"|"B"), result text, usage JSON
    errorOccurred = Signal(str, str)  # side, error text
    statusUpdate = Signal(str, str)   # side, status message
    busyChanged = Signal()
    ollamaModelsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._network = QNetworkAccessManager(self)
        self._slot_a = None
        self._slot_b = None
        self._busy = False
        self._ollama_models = []
        self._system_prompt = ""
        self._load_system_prompt()
        self._fetch_ollama_models()

    # ── System prompt ────────────────────────────────────────────────────

    def _load_system_prompt(self):
        try:
            with open(SYSTEM_PROMPT_PATH, "r", encoding="utf-8") as f:
                self._system_prompt = f.read()
        except Exception:
            self._system_prompt = ""

    # ── Ollama models (reuse same logic as ChatHandler) ──────────────────

    def _fetch_ollama_models(self):
        req = QNetworkRequest(QUrl("http://localhost:11434/api/tags"))
        req.setTransferTimeout(5000)
        self._models_reply = self._network.get(req)
        self._models_reply.finished.connect(self._on_models_fetched)

    def _on_models_fetched(self):
        reply = self._models_reply
        self._models_reply = None
        if not reply:
            return
        if reply.error() != reply.NetworkError.NoError:
            reply.deleteLater()
            return
        try:
            data = json.loads(bytes(reply.readAll().data()).decode("utf-8"))
            names = [m["name"] for m in data.get("models", [])]
            self._ollama_models = sorted(names)
            self.ollamaModelsChanged.emit()
        except Exception:
            pass
        finally:
            reply.deleteLater()

    @Property("QVariantList", notify=ollamaModelsChanged)
    def ollamaModels(self):
        return self._ollama_models

    @Slot()
    def refreshModels(self):
        self._fetch_ollama_models()

    # ── Properties ───────────────────────────────────────────────────────

    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    def _set_busy(self, v):
        if self._busy != v:
            self._busy = v
            self.busyChanged.emit()

    # ── Counters for tracking completion ─────────────────────────────────

    def _on_slot_finished(self, side, text, usage_json):
        self.resultReady.emit(side, text, usage_json)
        self._check_done()

    def _on_slot_error(self, side, text):
        self.errorOccurred.emit(side, text)
        self._check_done()

    def _on_slot_status(self, side, text):
        self.statusUpdate.emit(side, text)

    _pending = 0

    def _check_done(self):
        self._pending -= 1
        if self._pending <= 0:
            self._set_busy(False)

    # ── Public API ───────────────────────────────────────────────────────

    @Slot(str, str, str, str, str)
    def runComparison(self, prompt, backendA, modelA, backendB, modelB):
        """Run the same prompt against two model configurations."""
        prompt = prompt.strip()
        if not prompt or self._busy:
            return

        self._set_busy(True)
        self._pending = 2

        # Slot A
        self._slot_a = _ModelSlot("A", self._network, self)
        self._slot_a.finished.connect(self._on_slot_finished)
        self._slot_a.errored.connect(self._on_slot_error)
        self._slot_a.statusUpdate.connect(self._on_slot_status)
        self._slot_a.fire(prompt, backendA.lower(), modelA, self._system_prompt)

        # Slot B
        self._slot_b = _ModelSlot("B", self._network, self)
        self._slot_b.finished.connect(self._on_slot_finished)
        self._slot_b.errored.connect(self._on_slot_error)
        self._slot_b.statusUpdate.connect(self._on_slot_status)
        self._slot_b.fire(prompt, backendB.lower(), modelB, self._system_prompt)

    @Slot()
    def cancelComparison(self):
        if self._slot_a:
            self._slot_a.abort()
        if self._slot_b:
            self._slot_b.abort()
        self._pending = 0
        self._set_busy(False)
