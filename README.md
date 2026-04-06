# Bizon App – Desktop Linux

A Qt 6 / QML desktop application for Bizon AI workstations. Provides an integrated diagnostic hub with AI chat (powered by Ollama or Claude), embedded web views for guides and resources, and one-click app updates from GitHub.

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![Qt](https://img.shields.io/badge/Qt-6-green)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## Features

- **AI Chat** – Conversational diagnostic assistant with rich markdown rendering (tables, code blocks, lists, inline code badges)
- **Ollama Model Selector** – Auto-detects installed Ollama models; switch between them from the top bar
- **Claude Backend** – Optional Anthropic Claude support (requires API key)
- **System Prompt** – Managed via `system_prompt.md`; sent with every AI request
- **Dark / Light Mode** – Toggle between dark and light themes; all components adapt dynamically
- **Embedded Browser** – Tabbed web views for Notion guides, NVIDIA AI Catalog, and support resources
- **One-Click Updates** – Pull the latest version from GitHub directly from the app
- **Tool Execution** – AI can run diagnostic commands on the workstation and report results

---

## Project Structure

```
bizon_app_v2/
├── main.py                    # App entry point
├── backend/
│   ├── chat_handler.py        # AI chat backend (Ollama/Claude, system prompt, model selection)
│   └── updater.py             # GitHub update mechanism (git pull in background thread)
├── qml/
│   ├── Main.qml               # Root window, top bar, tab navigation
│   ├── components/
│   │   ├── Theme.qml          # Singleton theme (dark/light palettes, colors, typography)
│   │   ├── AssistantMessage.qml # Rich markdown-to-HTML renderer for AI responses
│   │   ├── UserMessage.qml    # User message bubble
│   │   ├── CommandRow.qml     # Tool execution status row
│   │   ├── StatusBubble.qml   # Loading/thinking indicator
│   │   ├── ErrorBubble.qml    # Error display
│   │   ├── UsageLine.qml      # Token usage summary
│   │   ├── TabButton.qml      # Top bar tab button
│   │   ├── NavButton.qml      # Browser navigation button
│   │   ├── PromptEditor.qml   # System prompt editor (admin only)
│   │   └── qmldir             # QML module registration
│   └── views/
│       ├── ChatView.qml       # Chat interface with message list and input
│       ├── BrowserView.qml    # Embedded Chromium web view
│       └── qmldir             # QML module registration
├── system_prompt.md           # AI system prompt (sent with every request)
├── bizon-app.png              # App icon (512x512)
├── bizon-app.svg              # App icon source (SVG)
├── requirements.txt           # Python dependencies
└── .gitignore
```

---

## Requirements

- **OS**: Ubuntu 20.04+ / Linux (tested on Bizon workstations)
- **Python**: 3.10+
- **PySide6**: Qt 6 bindings (`pip install PySide6 PySide6-WebEngine`)
- **Ollama**: Running locally on port 11434 (for AI chat)
- **Bizon API Server**: Running at `http://localhost:3456` (`/opt/bizon-api-server`)

---

## Installation

The app is pre-installed on Bizon workstations at:

```
/usr/local/share/dlbt_os/bza/bizon_app_v2/
```

For a fresh install:

```bash
cd /usr/local/share/dlbt_os/bza/
git clone https://github.com/Gimel12/bizonapp_desktop_linux.git bizon_app_v2
```

Install Python dependencies (if not already available):

```bash
pip install PySide6 PySide6-WebEngine
```

---

## Running

```bash
cd /usr/local/share/dlbt_os/bza/bizon_app_v2
python3 main.py
```

Or click **Bizon App** from the desktop dock / application launcher.

---

## Updating

### From the app
Click the **↻ Update** button in the top bar. The app pulls the latest code from GitHub. Restart the app to apply changes.

### From the terminal
```bash
cd /usr/local/share/dlbt_os/bza/bizon_app_v2
git pull origin main
```

---

## Configuration

### System Prompt
Edit `system_prompt.md` to change the AI's behavior. This file is sent with every chat request.

### Environment Variables
Set in `main.py` before Qt initialization:
- `QSG_RHI_BACKEND=opengl` – Force OpenGL (avoids slow Vulkan software fallback)
- `QT_OPENGL=desktop` – Use desktop OpenGL
- `ANTHROPIC_API_KEY` – Required for Claude backend (set in server environment)

---

## Desktop Entry

The `.desktop` file is located at:

```
/usr/share/applications/bizon_app.desktop
```

It launches the app with conda activated and points to the new icon.

---

## Development

### Pushing updates
```bash
cd /usr/local/share/dlbt_os/bza/bizon_app_v2
git add -A
git commit -m "description of changes"
git push origin main
```

All users can then click **↻ Update** in the app to pull the latest changes.

### Adding a new QML component
1. Create the `.qml` file in `qml/components/`
2. Register it in `qml/components/qmldir`
3. Use it in any other QML file via `import "components"`

---

## License

Proprietary – Bizon Tech Inc. Internal use only.
