# ytdlp-ahk

A modern, premium desktop media downloader and processor powered by **Nuxt UI** and **AutoHotkey v2** (using WebView2 integration).

## 🚀 Features

- **Asynchronous YouTube Downloader**:
  - Download video/audio from YouTube and other platforms via `yt-dlp`.
  - Real-time download progress bar, speed, total size, and ETA directly shown in the web interface.
  - Automatically extracts audio formats (`mp3`, `m4a`, `wav`, `opus`, `flac`).
  - Supports embedding YouTube thumbnails and track metadata during the download phase.
- **Metadata Editor & Media Converter**:
  - Load existing audio or video files.
  - Convert files to multiple formats (`mp3`, `m4a`, `wav`, `mp4`, `mkv`).
  - Edit or add tags (Title, Artist, Album, Year, Genre).
  - Embed custom cover art images (JPEG, PNG, WebP) directly into MP3, MP4, and M4A containers.
- **Modern Borderless Window Layout**:
  - Implements custom title bar styling with minimize, maximize, and close handlers connected to AutoHotkey.

## 📂 Project Directory Structure

```text
ytdlp-ahk/
├── lib/
│   ├── WebView2/                    <-- WebViewToo and WebView2 library files
│   │   ├── ComVar.ahk
│   │   ├── Promise.ahk
│   │   ├── WebView2.ahk
│   │   └── WebViewToo.ahk
│   └── yt-dlp/                      <-- Pre-packaged yt-dlp and ffmpeg executables
│       ├── ffmpeg.exe
│       └── yt-dlp.exe
├── frontend/                        <-- Nuxt UI Vue project source
│   ├── app/
│   │   ├── app.vue                  <-- Borderless window layout & drag caption
│   │   └── pages/
│   │       └── index.vue            <-- Core application panel (Downloader & Metadata Editor)
│   ├── nuxt.config.ts               <-- Build configuration for client-only static export
│   └── package.json
├── main.ahk                         <-- Main AutoHotkey v2 launcher script (WebView2 container)
└── build.bat                        <-- One-click build script to compile frontend & patch assets
```

## 🛠️ Getting Started

### Prerequisites

- [AutoHotkey v2](https://www.autohotkey.com/) installed on your Windows machine.
- [Node.js](https://nodejs.org/) (v18+) and npm installed to build the frontend.

### Installation & Execution

1. Open a command prompt in the `frontend` folder and run `npm install` to install dependencies.
2. Run [build.bat](file:///D:/scripts/ytdlp-ahk/build.bat) from the project root to compile the Nuxt frontend and generate the relative local files:
   ```cmd
   build.bat
   ```
3. Once the build completes, double-click [main.ahk](file:///D:/scripts/ytdlp-ahk/main.ahk) to run the application.

## ⌨️ Debugging Hotkeys

While running the application with `main.ahk`:
- **F12**: Opens Chrome Developer Tools for debugging JavaScript, layouts, and styles.
- **Ctrl + R**: Reloads the AutoHotkey script.
- **Ctrl + T**: Instantly terminates the application.