# ytdlp-ahk

A Windows desktop application that combines an AutoHotkey v2 wrapper (using WebView2) with a Nuxt (Vue) frontend to download and process media files using `yt-dlp` and `FFmpeg`.

## Features

- **Media Downloader (yt-dlp)**:
  - Downloads video or audio with real-time progress, speed, size, and ETA.
  - Supports playlist downloads, custom formats (m4a, mp3, wav, opus, flac), thumbnail embedding, and metadata tags.
- **Filename Renamer**:
  - Automatically renames files after downloading or converting using user-defined regex rules.
  - Automatically cleans up file paths by removing emojis and non-standard characters.
- **Metadata Editor & Converter (FFmpeg)**:
  - Converts media formats and edits tags (Title, Artist, Album, Year, Genre).
  - Embeds cover art (JPEG, PNG, WebP) into MP3, MP4, and M4A files.
- **UI & Logs Console**:
  - Split-pane layout with configuration on the left and a live console output on the right showing raw logs from yt-dlp, FFmpeg, and startup update checks.

## Project Structure

```text
ytdlp-ahk/
├── frontend/         # Nuxt (Vue) frontend source code
├── lib/              # Modular backend and dependencies
│   ├── WebView2/     # WebViewToo library files
│   ├── yt-dlp/       # yt-dlp and ffmpeg executables
│   ├── Converter.ahk # FFmpeg metadata and conversion logic
│   ├── Downloader.ahk# yt-dlp execution and download tracking
│   ├── JSON.ahk      # JSON parsing library
│   ├── Renamer.ahk   # Regex-based file renaming
│   ├── WindowControls.ahk # Window management and file dialogs
│   └── Updater.ahk   # Startup check for yt-dlp updates
├── main.ahk          # Main AutoHotkey v2 launcher script
└── build.bat         # Script to build frontend and compile files
```

## Getting Started

### Prerequisites

- [AutoHotkey v2](https://www.autohotkey.com/)
- [Node.js](https://nodejs.org/) (v18+)

### Build and Run

1. Install frontend dependencies:
   ```cmd
   cd frontend
   npm install
   ```
2. Build the frontend assets:
   ```cmd
   cd ..
   build.bat
   ```
3. Run the application by launching `main.ahk`.

## Debugging Hotkeys

- **F12**: Open Chrome Developer Tools.
- **Ctrl + R**: Reload the AutoHotkey script.
- **Ctrl + T**: Exit the application.