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
        playlistItems := config.Has("playlistItems") ? config["playlistItems"] : ""
        outputDir := config.Has("outputDir") ? config["outputDir"] : A_ScriptDir
        embedThumbnail := config.Has("embedThumbnail") ? config["embedThumbnail"] : false
        addMetadata := config.Has("addMetadata") ? config["addMetadata"] : false
        enableSection := config.Has("enableSection") ? config["enableSection"] : false
        sectionRange := config.Has("sectionRange") ? config["sectionRange"] : [0, 0]
        
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
            if (playlistItems != "") {
                fullCmd .= " --playlist-items `"" playlistItems "`""
            } else if (!playlistAll) {
                fullCmd .= " --playlist-items `"" playlistRange[1] "-" playlistRange[2] "`""
            }
        } else {
            fullCmd .= " --no-playlist"
        }
        
        ; Section Download Options (only for non-playlist videos)
        if (!isPlaylist && enableSection && sectionRange.Length >= 2) {
            startSec := sectionRange[1]
            endSec := sectionRange[2]
            fullCmd .= ' --download-sections "*' startSec '-' endSec '"'
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

; Get video info (duration & title) asynchronously
GetVideoInfo(WebView, Url) {
    try {
        ytdlpPath := A_ScriptDir "\lib\yt-dlp\yt-dlp.exe"
        tempLog := A_Temp "\ytdlp_info_" A_TickCount ".log"
        tempErr := A_Temp "\ytdlp_info_err_" A_TickCount ".log"
        if FileExist(tempLog)
            FileDelete(tempLog)
        if FileExist(tempErr)
            FileDelete(tempErr)
            
        ; Print duration first, then title. Redirect stdout to tempLog, stderr to tempErr.
        fullCmd := "`"" ytdlpPath "`" --print `"duration`" --print `"title`" --no-playlist `"" Url "`""
        
        pid := 0
        Run(A_ComSpec " /c `"" fullCmd " 1> `"" tempLog "`" 2> `"" tempErr "`"", A_ScriptDir "\lib\yt-dlp", "Hide", &pid)
        
        if (pid == 0) {
            WebView.ExecuteScript("window.onVideoInfoError('Failed to start yt-dlp info process.')")
            return
        }
        
        SetTimer(CheckInfo, 100)
    } catch Error as err {
        WebView.ExecuteScript("window.onVideoInfoError('" StrReplace(err.Message, "'", "\'") "')")
    }
    
    CheckInfo() {
        if (!ProcessExist(pid)) {
            SetTimer(, 0)
            infoStr := ""
            errStr := ""
            if FileExist(tempLog) {
                try {
                    infoStr := FileRead(tempLog)
                    infoStr := Trim(infoStr, "`r`n`t ")
                }
            }
            if FileExist(tempErr) {
                try {
                    errStr := FileRead(tempErr)
                    errStr := Trim(errStr, "`r`n`t ")
                }
            }
            
            try {
                if FileExist(tempLog)
                    FileDelete(tempLog)
                if FileExist(tempErr)
                    FileDelete(tempErr)
            }
            
            if (infoStr == "") {
                errMsg := (errStr != "") ? errStr : "Failed to fetch video details."
                WebView.ExecuteScript("window.onVideoInfoError('" StrReplace(errMsg, "'", "\'") "')")
            } else {
                ; Parse duration (first line) and title (remaining lines)
                firstNewline := InStr(infoStr, "`n")
                if (firstNewline) {
                    duration := SubStr(infoStr, 1, firstNewline - 1)
                    title := SubStr(infoStr, firstNewline + 1)
                    
                    duration := Trim(duration, "`r`n`t ")
                    title := Trim(title, "`r`n`t ")
                    
                    escapedTitle := StrReplace(title, "\", "\\")
                    escapedTitle := StrReplace(escapedTitle, "'", "\'")
                    escapedTitle := StrReplace(escapedTitle, "`r", "")
                    escapedTitle := StrReplace(escapedTitle, "`n", "\n")
                    
                    WebView.ExecuteScript("window.onVideoInfoSuccess('" escapedTitle "', '" duration "')")
                } else {
                    WebView.ExecuteScript("window.onVideoInfoError('Failed to parse video info')")
                }
            }
        }
    }
}

; Get playlist videos metadata asynchronously
GetPlaylistInfo(WebView, Url) {
    try {
        ytdlpPath := A_ScriptDir "\lib\yt-dlp\yt-dlp.exe"
        tempLog := A_Temp "\ytdlp_playlist_" A_TickCount ".log"
        tempErr := A_Temp "\ytdlp_playlist_err_" A_TickCount ".log"
        if FileExist(tempLog)
            FileDelete(tempLog)
        if FileExist(tempErr)
            FileDelete(tempErr)
            
        ; Flat playlist dump JSON.
        fullCmd := "`"" ytdlpPath "`" --flat-playlist --dump-json `"" Url "`""
        
        pid := 0
        Run(A_ComSpec " /c `"" fullCmd " 1> `"" tempLog "`" 2> `"" tempErr "`"", A_ScriptDir "\lib\yt-dlp", "Hide", &pid)
        
        if (pid == 0) {
            WebView.ExecuteScript("window.onPlaylistInfoError('Failed to start yt-dlp playlist process.')")
            return
        }
        
        SetTimer(CheckPlaylistInfo, 100)
    } catch Error as err {
        WebView.ExecuteScript("window.onPlaylistInfoError('" StrReplace(err.Message, "'", "\'") "')")
    }
    
    CheckPlaylistInfo() {
        if (!ProcessExist(pid)) {
            SetTimer(, 0)
            infoStr := ""
            errStr := ""
            if FileExist(tempLog) {
                try {
                    infoStr := FileRead(tempLog)
                    infoStr := Trim(infoStr, "`r`n`t ")
                }
            }
            if FileExist(tempErr) {
                try {
                    errStr := FileRead(tempErr)
                    errStr := Trim(errStr, "`r`n`t ")
                }
            }
            
            try {
                if FileExist(tempLog)
                    FileDelete(tempLog)
                if FileExist(tempErr)
                    FileDelete(tempErr)
            }
            
            if (infoStr == "") {
                errMsg := (errStr != "") ? errStr : "Failed to fetch playlist details."
                WebView.ExecuteScript("window.onPlaylistInfoError('" StrReplace(errMsg, "'", "\'") "')")
            } else {
                ; Split by newline and combine into a JSON array string
                lines := StrSplit(infoStr, "`n", "`r")
                jsonArrayStr := "["
                loop lines.Length {
                    line := Trim(lines[A_Index], "`r`n`t ")
                    if (line != "") {
                        if (jsonArrayStr != "[")
                            jsonArrayStr .= ","
                        jsonArrayStr .= line
                    }
                }
                jsonArrayStr .= "]"
                
                ; Send JSON array directly to JS
                WebView.ExecuteScript("window.onPlaylistInfoSuccess(" jsonArrayStr ")")
            }
        }
    }
}
