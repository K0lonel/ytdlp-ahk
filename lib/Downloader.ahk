; Start yt-dlp Download Asynchronously
StartDownload(WebView, ConfigJson) {
    ; Parse parameters from the JSON string passed by frontend
    try {
        config := JSON.Load(ConfigJson)
        url := config.Has("url") ? config["url"] : ""
        format := config.Has("format") ? config["format"] : "video"
        audioFormat := config.Has("audioFormat") ? config["audioFormat"] : "mp3"
        videoFormat := config.Has("videoFormat") ? config["videoFormat"] : "mp4"
        isPlaylist := config.Has("isPlaylist") ? config["isPlaylist"] : false
        playlistAll := config.Has("playlistAll") ? config["playlistAll"] : true
        playlistRange := config.Has("playlistRange") ? config["playlistRange"] : [1, 5]
        outputDir := config.Has("outputDir") ? config["outputDir"] : A_ScriptDir
        embedThumbnail := config.Has("embedThumbnail") ? config["embedThumbnail"] : false
        addMetadata := config.Has("addMetadata") ? config["addMetadata"] : false
        
        rules := []
        if (config.Has("rules") && IsObject(config["rules"])) {
            for r in config["rules"] {
                rules.Push({ pattern: r["pattern"], replacement: r["replacement"] })
            }
        }
        
        ; If directory doesn't exist, create it
        if (!DirExist(outputDir)) {
            DirCreate(outputDir)
        }
        
        ; Build command line parameters
        ytdlpPath := A_ScriptDir "\lib\yt-dlp\yt-dlp.exe"
        fullCmd := "`"" ytdlpPath "`""
        
        ; Format selection
        if (format == "audio") {
            fullCmd .= " --extract-audio --audio-format " audioFormat
        } else {
            ; Video download format selection
            if (videoFormat == "mp4") {
                fullCmd .= " -f `"bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]`""
            } else if (videoFormat == "webm") {
                fullCmd .= " -f `"bv*[ext=webm]+ba[ext=webm]/b[ext=webm]`""
            } else {
                fullCmd .= " -f `"best`""
            }
        }
        
        ; Playlist Options
        if (isPlaylist) {
            fullCmd .= " --yes-playlist"
            if (!playlistAll) {
                fullCmd .= " --playlist-items `"" playlistRange[1] "-" playlistRange[2] "`""
            }
        } else {
            fullCmd .= " --no-playlist"
        }
        
        ; Embed thumbnail
        if (embedThumbnail) {
            fullCmd .= " --embed-thumbnail"
        }
        
        ; Add metadata
        if (addMetadata) {
            fullCmd .= " --embed-metadata"
        }
        
        ; Output template path
        fullCmd .= " -o `"" outputDir "\%(title)s.%(ext)s`""
        
        ; Target URL
        fullCmd .= " `"" url "`""
        
        ; Redirect console logs to temporary file for background monitoring
        tempLog := A_Temp "\ytdlp_dl_" A_TickCount ".log"
        if FileExist(tempLog)
            FileDelete(tempLog)
            
        ; Run in background
        pid := 0
        Run(A_ComSpec " /c `"" fullCmd " > `"" tempLog "`" 2>&1`"", A_ScriptDir "\lib\yt-dlp", "Hide", &pid)
        
        if (pid == 0) {
            MsgBox("Failed to start download process.", "Error", 16)
            return
        }
        
        ; Start monitoring execution via Timer
        SetTimer(MonitorDownload, 200)
    } catch Error as err {
        MsgBox("Failed to initiate download: " err.Message, "Error", 16)
    }
    
    ; Inner function to monitor process and parse log file
    MonitorDownload() {
        if (!ProcessExist(pid)) {
            ; Process finished, stop timer
            SetTimer(, 0)
            
            ; Final read to get everything
            if FileExist(tempLog) {
                UpdateLogConsole(WebView, tempLog)
                try {
                    fileContent := FileRead(tempLog)
                    ; Check for errors in the log
                    if (InStr(fileContent, "ERROR:") || InStr(fileContent, "fatal:")) {
                        ; Extract error line
                        RegExMatch(fileContent, "m)(ERROR:.*|fatal:.*)$", &mErr)
                        errMsg := mErr ? mErr[1] : "An error occurred during download."
                        WebView.ExecuteScript("window.onDownloadError('" StrReplace(errMsg, "'", "\'") "')")
                    } else {
                        FileAppend("`r`n[Renamer] Scanning output directory for files to rename: " outputDir "`r`n", tempLog)
                        finalPaths := RenameAllFilesIndex(outputDir, rules, tempLog)
                        
                        ; Final console update to show the renamer logs
                        UpdateLogConsole(WebView, tempLog)
                        
                        if (finalPaths.Length > 0) {
                            pathsStr := ""
                            for path in finalPaths {
                                pathsStr .= (pathsStr == "" ? "" : "|") . path
                            }
                            escapedOut := StrReplace(pathsStr, "\", "\\")
                            WebView.ExecuteScript("window.onDownloadComplete('" escapedOut "')")
                        } else {
                            WebView.ExecuteScript("window.onDownloadComplete()")
                        }
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
            UpdateLogConsole(WebView, tempLog)
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
