# URL History Tracker

A Chrome/Edge browser extension that silently records every URL you visit across all open tabs, appending each entry to a plain-text file (`URLHIST.txt`) in your OS temporary directory.

## How it works

Because browser extensions cannot write directly to the filesystem, the extension communicates with a small Python companion script via Chrome's **Native Messaging** API. Each time a page finishes loading, the extension sends the URL and a timestamp to the companion script, which appends a line to `URLHIST.txt`.

```
Chrome/Edge Extension
  └─ background.js (service worker)
       │  chrome.tabs.onUpdated → URL detected
       ↓
chrome.runtime.sendNativeMessage
       ↓
native-host/urlhist_host.py
       └─ appends to $TMPDIR/URLHIST.txt
```

Output format:
```
2026-04-26 09:15:02  https://example.com, Example Domain
2026-04-26 09:15:44  https://another-site.com, Another Site
2026-04-26 09:16:01  https://no-title-page.com
```
The page title (from the `<title>` tag) is appended after the URL, comma-separated. If the page has no title the URL is written alone.

## Requirements

- Google Chrome or Microsoft Edge (any recent version)
- Python 3 installed and available in your `PATH`

## Installation

### 1. Load the extension

1. Open `chrome://extensions` (or `edge://extensions`)
2. Enable **Developer mode** (toggle, top-right)
3. Click **Load unpacked** and select the `extension/` folder
4. Copy the **Extension ID** displayed under the extension name

### 2. Register the native messaging host

**macOS / Linux**

```bash
./install.sh <EXTENSION_ID>
```

**Windows** (Command Prompt, run as your normal user)

```bat
install.bat <EXTENSION_ID>
```

The install script will:
- Make `urlhist_host.py` executable
- Write a resolved native host manifest (with your local path and extension ID) to the correct browser directory
- Register the host for both Chrome and Edge if both are installed

### 3. Restart Chrome / Edge

Native host registration takes effect after a browser restart.

## Usage

Once installed, browsing works as normal — no interaction required. Internal browser pages (`chrome://`, `about:`, `edge://`, `data:`) are filtered out automatically.

To view the log:

**macOS / Linux**
```bash
cat /tmp/URLHIST.txt
```

**Windows** (PowerShell)
```powershell
Get-Content "$env:TEMP\URLHIST.txt"
```

## Project structure

```
urlhist-extension/
├── extension/
│   ├── manifest.json          # MV3 extension manifest
│   └── background.js          # Service worker: tab listener + native messaging
├── native-host/
│   ├── urlhist_host.py        # Python native messaging host
│   └── com.urlhist.host.json  # Native host registration manifest template
├── install.sh                 # macOS/Linux install script
├── install.bat                # Windows install script
└── .gitignore
```

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| URLHIST.txt is not created | Native host not registered — re-run the install script and restart the browser |
| `Native host error` in the extension's service worker console | Wrong extension ID in the host manifest — re-run the install script with the correct ID |
| Python not found | Ensure `python3` (macOS/Linux) or `python` (Windows) is on your `PATH` |

To open the service worker console: `chrome://extensions` → click **Service Worker** link under the extension.
