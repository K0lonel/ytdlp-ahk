#Requires AutoHotkey v2.0+
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

; Ensure the tools directory exists and extract pre-packaged binaries if compiled
DirCreate("lib/yt-dlp")
FileInstall("lib/yt-dlp/yt-dlp.exe", "lib/yt-dlp/yt-dlp.exe", 0)
FileInstall("lib/yt-dlp/ffmpeg.exe", "lib/yt-dlp/ffmpeg.exe", 0)

; Include WebViewToo library files
#Include lib/WebView2/WebViewToo.ahk
FileEncoding "UTF-8"

ScriptPID := DllCall("GetCurrentProcessId")
GroupAdd("ScriptGroup", "ahk_pid" ScriptPID)

; Create WebViewToo instance with a clean borderless window
global MyWindow := WebViewGui("-Caption +Resize", "YT-DLP & FFmpeg Tool")
MyWindow.OnEvent("Close", (*) => ExitApp())

; Register standard window caption and control callbacks
MyWindow.AddCallBackToScript("DragWindow", DragWindow)
MyWindow.AddCallBackToScript("dragWindow", DragWindow)
MyWindow.AddCallBackToScript("Minimize", minimizeWindow)
MyWindow.AddCallBackToScript("minimizeWindow", minimizeWindow)
MyWindow.AddCallBackToScript("Maximize", maximizeWindow)
MyWindow.AddCallBackToScript("maximizeWindow", maximizeWindow)
MyWindow.AddCallBackToScript("Close", closeWindow)
MyWindow.AddCallBackToScript("closeWindow", closeWindow)
MyWindow.AddCallBackToScript("OpenDevTools", (*) => MyWindow.OpenDevToolsWindow())

; Register custom application callbacks
MyWindow.AddCallBackToScript("selectDirectory", SelectDirectory)
MyWindow.AddCallBackToScript("selectFile", SelectFile)
MyWindow.AddCallBackToScript("startDownload", StartDownload)
MyWindow.AddCallBackToScript("processFile", ProcessFile)

; Browse to the compiled public folder and navigate to index.html
MyWindow.BrowseFolder("frontend/.output/public/")
MyWindow.Navigate("index.html")

; Show the window
MyWindow.Show("w1100 h750 Center")

; Standard hotkeys for debugging
F12::MyWindow.OpenDevToolsWindow()
$^t::ExitApp()
^r::Reload()

; Window Caption Handlers
DragWindow(WebView) {
    DllCall("ReleaseCapture")
    try {
        PostMessage(0x0112, 0xF012, 0,, "ahk_id " WebView.Gui.Hwnd)
    } catch {
        PostMessage(0x0112, 0xF012, 0,, "ahk_id " MyWindow.Hwnd)
    }
}

minimizeWindow(WebView) {
    WebView.Minimize()
}

maximizeWindow(WebView) {
    if (DllCall("IsZoomed", "UPtr", WebView.Hwnd)) {
        WebView.Restore()
    } else {
        WebView.Maximize()
    }
}

closeWindow(WebView) {
    ExitApp()
}

; Directory and File Pickers
SelectDirectory(WebView, CallbackName) {
    selectedDir := DirSelect(, 3, "Select Download Destination Folder")
    if (selectedDir != "") {
        ; Send selected directory back to web UI
        escapedPath := StrReplace(selectedDir, "\", "\\")
        WebView.ExecuteScript("window.onDirectorySelected('" escapedPath "')")
    }
}

SelectFile(WebView, FileType) {
    ; FileType is either 'media' or 'cover'
    filter := ""
    title := ""
    if (FileType == "media") {
        filter := "Media Files (*.mp4;*.mkv;*.avi;*.mp3;*.m4a;*.ogg;*.wav;*.flac)"
        title := "Select Media File"
    } else {
        filter := "Image Files (*.jpg;*.jpeg;*.png;*.webp)"
        title := "Select Cover Image"
    }
    
    selectedFile := FileSelect(3,, title, filter)
    if (selectedFile != "") {
        escapedPath := StrReplace(selectedFile, "\", "\\")
        WebView.ExecuteScript("window.onFileSelected('" FileType "', '" escapedPath "')")
    }
}

; Start yt-dlp Download Asynchronously
StartDownload(WebView, ConfigJson) {
    ; Parse parameters from the JSON string passed by frontend
    ; Format: { url: "...", format: "video|audio", audioFormat: "mp3|m4a|...", outputDir: "...", embedThumbnail: true|false, addMetadata: true|false }
    try {
        ; Simple JSON-like parsing since AutoHotkey doesn't have native JSON
        ; We will extract the values using RegEx
        RegExMatch(ConfigJson, '"url":"([^"]+)"', &mUrl)
        RegExMatch(ConfigJson, '"format":"([^"]+)"', &mFormat)
        RegExMatch(ConfigJson, '"audioFormat":"([^"]+)"', &mAudioFormat)
        RegExMatch(ConfigJson, '"outputDir":"([^"]+)"', &mOutputDir)
        RegExMatch(ConfigJson, '"embedThumbnail":([a-z]+)', &mEmbedThumb)
        RegExMatch(ConfigJson, '"addMetadata":([a-z]+)', &mAddMeta)
        
        url := mUrl ? mUrl[1] : ""
        format := mFormat ? mFormat[1] : "video"
        audioFormat := mAudioFormat ? mAudioFormat[1] : "mp3"
        outputDir := mOutputDir ? StrReplace(mOutputDir[1], "\\", "\") : A_ScriptDir
        embedThumb := mEmbedThumb && mEmbedThumb[1] == "true" ? true : false
        addMeta := mAddMeta && mAddMeta[1] == "true" ? true : false
        
        if (url == "") {
            MsgBox("URL cannot be empty!", "Error", 48)
            return
        }

        ; Resolve relative tools paths
        ytDlpPath := A_ScriptDir "\lib\yt-dlp\yt-dlp.exe"
        ffmpegPath := A_ScriptDir "\lib\yt-dlp\ffmpeg.exe"

        ; Build command arguments
        cmdArgs := " --ffmpeg-location `"" ffmpegPath "`""
        
        ; Output template
        cmdArgs .= " -o `"" outputDir "\%(title)s.\%(ext)s`""
        
        ; Force newline-separated progress output for AHK parser
        cmdArgs .= " --newline"
        
        if (format == "audio") {
            cmdArgs .= " -x --audio-format " audioFormat
        } else {
            ; Best video + best audio merged into mp4/mkv
            cmdArgs .= " -f `"bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best`""
        }
        
        if (embedThumb) {
            cmdArgs .= " --embed-thumbnail"
        }
        if (addMeta) {
            cmdArgs .= " --embed-metadata"
        }
        
        fullCmd := "`"" ytDlpPath "`" " cmdArgs " `"" url "`""
        
        ; Launch the command asynchronously and redirect stdout to a temp file
        tempLog := A_Temp "\ytdlp_dl_" A_TickCount ".log"
        if FileExist(tempLog)
            FileDelete(tempLog)
            
        ; Run cmd.exe /c hidden
        shellCmd := A_ComSpec " /c `"" fullCmd " > `"" tempLog "`" 2>&1`""
        
        ; Run process and retrieve process ID
        pid := 0
        Run(shellCmd,, "Hide", &pid)
        
        if (pid == 0) {
            WebView.ExecuteScript("window.onDownloadError('Failed to launch downloader.')")
            return
        }
        
        ; Start a timer to monitor the download progress
        logPosition := 0
        SetTimer(MonitorDownload, 200)
    } catch Error as err {
        MsgBox("Failed to start download: " err.Message, "Error", 16)
    }
    
    ; Inner function to monitor process and parse log file
    MonitorDownload() {
        if (!ProcessExist(pid)) {
            ; Process finished, stop timer
            SetTimer(, 0)
            
            ; Final read to get everything
            if FileExist(tempLog) {
                try {
                    fileContent := FileRead(tempLog)
                    ; Check for errors in the log
                    if (InStr(fileContent, "ERROR:") || InStr(fileContent, "fatal:")) {
                        ; Extract error line
                        RegExMatch(fileContent, "m)(ERROR:.*|fatal:.*)$", &mErr)
                        errMsg := mErr ? mErr[1] : "An error occurred during download."
                        WebView.ExecuteScript("window.onDownloadError('" StrReplace(errMsg, "'", "\'") "')")
                    } else {
                        WebView.ExecuteScript("window.onDownloadComplete()")
                    }
                } catch {
                    WebView.ExecuteScript("window.onDownloadComplete()")
                }
                
                ; Cleanup log file after brief delay to avoid lock issues
                SetTimer(CleanupLog, -1000)
            } else {
                WebView.ExecuteScript("window.onDownloadComplete()")
            }
            return
        }
        
        ; Read log and parse latest progress line
        if FileExist(tempLog) {
            try {
                fileContent := FileRead(tempLog)
                ; Split into lines
                lines := StrSplit(fileContent, "`n", "`r")
                
                ; Search backward for progress lines
                loop lines.Length {
                    idx := lines.Length - A_Index + 1
                    line := lines[idx]
                    
                    ; Look for yt-dlp download progress format:
                    ; [download]  12.3% of ~10.00MiB at  2.45MiB/s ETA 00:04
                    if RegExMatch(line, "i)\[download\]\s+([\d\.]+)%\s+of\s+([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)", &m) {
                        percent := m[1]
                        totalSize := m[2]
                        speed := m[3]
                        eta := m[4]
                        
                        ; Send updates to WebView
                        WebView.ExecuteScript("window.onDownloadProgress(" percent ", '" totalSize "', '" speed "', '" eta "')")
                        break
                    }
                    
                    ; Look for post-processing/ffmpeg messages
                    if InStr(line, "[ExtractAudio]") {
                        WebView.ExecuteScript("window.onDownloadProgress(100, '', '', '', 'Extracting audio...')")
                        break
                    }
                    if InStr(line, "[ThumbnailsConvertor]") {
                        WebView.ExecuteScript("window.onDownloadProgress(100, '', '', '', 'Converting thumbnails...')")
                        break
                    }
                    if InStr(line, "[EmbedSubtitle]") {
                        WebView.ExecuteScript("window.onDownloadProgress(100, '', '', '', 'Embedding subtitles...')")
                        break
                    }
                    if InStr(line, "[Metadata]") {
                        WebView.ExecuteScript("window.onDownloadProgress(100, '', '', '', 'Writing metadata...')")
                        break
                    }
                }
            }
        }
    }
    
    CleanupLog() {
        try {
            if FileExist(tempLog)
                FileDelete(tempLog)
        }
    }
}

; Run FFmpeg Process for Converting & Metadata Editing
ProcessFile(WebView, ConfigJson) {
    ; Parse parameters from the JSON string passed by frontend
    ; Format: { filePath: "...", action: "convert|metadata", format: "mp3|mp4|...", title: "...", artist: "...", album: "...", year: "...", genre: "...", coverPath: "...", outputDir: "..." }
    try {
        RegExMatch(ConfigJson, '"filePath":"([^"]+)"', &mFilePath)
        RegExMatch(ConfigJson, '"action":"([^"]+)"', &mAction)
        RegExMatch(ConfigJson, '"format":"([^"]+)"', &mFormat)
        RegExMatch(ConfigJson, '"title":"([^"]+)"', &mTitle)
        RegExMatch(ConfigJson, '"artist":"([^"]+)"', &mArtist)
        RegExMatch(ConfigJson, '"album":"([^"]+)"', &mAlbum)
        RegExMatch(ConfigJson, '"year":"([^"]+)"', &mYear)
        RegExMatch(ConfigJson, '"genre":"([^"]+)"', &mGenre)
        RegExMatch(ConfigJson, '"coverPath":"([^"]+)"', &mCoverPath)
        RegExMatch(ConfigJson, '"outputDir":"([^"]+)"', &mOutputDir)

        filePath := mFilePath ? StrReplace(mFilePath[1], "\\", "\") : ""
        action := mAction ? mAction[1] : "convert"
        format := mFormat ? mFormat[1] : "mp3"
        titleVal := mTitle ? mTitle[1] : ""
        artistVal := mArtist ? mArtist[1] : ""
        albumVal := mAlbum ? mAlbum[1] : ""
        yearVal := mYear ? mYear[1] : ""
        genreVal := mGenre ? mGenre[1] : ""
        coverPath := mCoverPath ? StrReplace(mCoverPath[1], "\\", "\") : ""
        outputDir := mOutputDir ? StrReplace(mOutputDir[1], "\\", "\") : A_ScriptDir

        if (filePath == "" || !FileExist(filePath)) {
            MsgBox("Source file not found: " filePath, "Error", 48)
            return
        }

        ffmpegPath := A_ScriptDir "\lib\yt-dlp\ffmpeg.exe"
        
        ; Extract file details
        SplitPath(filePath, &origName, &origDir, &origExt, &nameNoExt)
        
        ; Determine output extension and path
        outExt := (action == "convert") ? format : origExt
        outPath := outputDir "\" nameNoExt "_processed." outExt
        
        ; Avoid overwriting same file directly (ffmpeg will prompt or fail)
        if (outPath == filePath) {
            outPath := outputDir "\" nameNoExt "_mod." outExt
        }

        ; Build FFmpeg command arguments
        cmdArgs := " -y -i `"" filePath "`""
        
        ; Handle Cover Art mapping if cover image is provided
        coverIdx := -1
        if (coverPath != "" && FileExist(coverPath)) {
            cmdArgs .= " -i `"" coverPath "`""
            coverIdx := 1
        }
        
        ; Handle action types
        if (action == "convert") {
            if (format == "mp3") {
                cmdArgs .= " -c:a libmp3lame -q:a 2"
            } else if (format == "m4a") {
                cmdArgs .= " -c:a aac -b:a 192k"
            } else if (format == "wav") {
                cmdArgs .= " -c:a pcm_s16le"
            } else if (format == "mp4") {
                cmdArgs .= " -c:v libx264 -c:a aac -b:a 192k -pix_fmt yuv420p"
            } else if (format == "mkv") {
                cmdArgs .= " -c:v copy -c:a copy"
            }
        } else {
            ; Simply copy original streams if just editing metadata
            cmdArgs .= " -c:v copy -c:a copy"
        }
        
        ; Add metadata arguments
        if (titleVal != "")
            cmdArgs .= " -metadata title=`"" titleVal "`""
        if (artistVal != "")
            cmdArgs .= " -metadata artist=`"" artistVal "`""
        if (albumVal != "")
            cmdArgs .= " -metadata album=`"" albumVal "`""
        if (yearVal != "")
            cmdArgs .= " -metadata date=`"" yearVal "`""
        if (genreVal != "")
            cmdArgs .= " -metadata genre=`"" genreVal "`""

        ; Map cover art if present
        if (coverIdx != -1) {
            if (outExt == "mp3") {
                ; For MP3, map cover to ID3v2 attached image
                cmdArgs .= " -map 0:0 -map 1:0 -id3v2_version 3 -metadata:s:v title=`"Album cover`" -metadata:s:v comment=`"Cover (front)`""
            } else if (outExt == "mp4" || outExt == "m4a") {
                ; For MP4/M4A, map cover as attached_pic video stream
                cmdArgs .= " -map 0 -map 1 -disposition:v:1 attached_pic"
            } else {
                cmdArgs .= " -map 0 -map 1"
            }
        }
        
        cmdArgs .= " `"" outPath "`""
        fullCmd := "`"" ffmpegPath "`" " cmdArgs
        
        ; Run FFmpeg command hidden and wait for it
        tempLog := A_Temp "\ffmpeg_proc_" A_TickCount ".log"
        shellCmd := A_ComSpec " /c `"" fullCmd " > `"" tempLog "`" 2>&1`""
        
        pid := 0
        Run(shellCmd,, "Hide", &pid)
        
        if (pid == 0) {
            WebView.ExecuteScript("window.onProcessError('Failed to launch FFmpeg.')")
            return
        }
        
        ; Monitor FFmpeg execution
        SetTimer(MonitorFFmpeg, 200)
    } catch Error as err {
        MsgBox("Failed to start processing: " err.Message, "Error", 16)
    }
    
    MonitorFFmpeg() {
        if (!ProcessExist(pid)) {
            SetTimer(, 0)
            
            ; Verify output file exists and has size > 0
            if (FileExist(outPath) && FileGetSize(outPath) > 0) {
                escapedOut := StrReplace(outPath, "\", "\\")
                WebView.ExecuteScript("window.onProcessComplete('" escapedOut "')")
            } else {
                ; Read error log
                errMsg := "FFmpeg processing failed."
                if FileExist(tempLog) {
                    try {
                        logText := FileRead(tempLog)
                        RegExMatch(logText, "m)(Error.*|Invalid.*|Output.*failed)$", &mErr)
                        if (mErr)
                            errMsg := mErr[0]
                    }
                }
                WebView.ExecuteScript("window.onProcessError('" StrReplace(errMsg, "'", "\'") "')")
            }
            
            ; Cleanup log
            try {
                if FileExist(tempLog)
                    FileDelete(tempLog)
            }
            return
        }
    }
}
