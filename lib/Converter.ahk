; Run FFmpeg Process for Converting & Metadata Editing
ProcessFile(WebView, ConfigJson) {
    ; Parse parameters from the JSON string passed by frontend
    ; Format: { filePath: "...", action: "convert|metadata", format: "mp3|mp4|...", title: "...", artist: "...", album: "...", year: "...", genre: "...", coverPath: "...", outputDir: "..." }
    try {
        config := JSON.Load(ConfigJson)
        filePath := config.Has("filePath") ? config["filePath"] : ""
        action := config.Has("action") ? config["action"] : "convert"
        format := config.Has("format") ? config["format"] : "mp3"
        titleVal := config.Has("title") ? config["title"] : ""
        artistVal := config.Has("artist") ? config["artist"] : ""
        albumVal := config.Has("album") ? config["album"] : ""
        yearVal := config.Has("year") ? config["year"] : ""
        genreVal := config.Has("genre") ? config["genre"] : ""
        coverPath := config.Has("coverPath") ? config["coverPath"] : ""
        outputDir := config.Has("outputDir") ? config["outputDir"] : A_ScriptDir
        
        rules := []
        if (config.Has("rules") && IsObject(config["rules"])) {
            for r in config["rules"] {
                rules.Push({ pattern: r["pattern"], replacement: r["replacement"] })
            }
        }

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
        
        ; Copy streams or encode based on format and action
        if (action == "convert") {
            ; Convert actions (audio format conversion)
            if (format == "mp3") {
                cmdArgs .= " -c:a libmp3lame -q:a 2"
            } else if (format == "m4a") {
                cmdArgs .= " -c:a aac -b:a 192k"
            } else if (format == "wav") {
                cmdArgs .= " -c:a pcm_s16le"
            } else if (format == "flac") {
                cmdArgs .= " -c:a flac"
            } else if (format == "ogg") {
                cmdArgs .= " -c:a libvorbis -q:a 4"
            } else {
                cmdArgs .= " -c copy"
            }
        } else {
            ; For metadata edits without format changes, copy audio stream
            cmdArgs .= " -c:a copy"
        }
        
        ; Map streams (cover art requires mapping stream 0 and 1)
        if (coverIdx != -1) {
            cmdArgs .= " -map 0:a -map 1:v -disposition:v:0 attached_pic"
        } else {
            cmdArgs .= " -map 0:a?"
        }
        
        ; Apply Metadata Tags
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
            
        ; Output File
        cmdArgs .= " `"" outPath "`""
        
        ; Redirect output logs to temp file
        tempLog := A_Temp "\ffmpeg_proc_" A_TickCount ".log"
        if FileExist(tempLog)
            FileDelete(tempLog)
            
        ; Start background run
        pid := 0
        Run(A_ComSpec " /c `"" ffmpegPath cmdArgs " > `"" tempLog "`" 2>&1`"", A_ScriptDir "\lib\yt-dlp", "Hide", &pid)
        
        if (pid == 0) {
            MsgBox("Failed to start FFmpeg process.", "Error", 16)
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
            UpdateLogConsole(WebView, tempLog)
            
            ; Verify output file exists and has size > 0
            if (FileExist(outPath) && FileGetSize(outPath) > 0) {
                finalPath := ApplyRenamingRules(outPath, rules)
                escapedSource := StrReplace(filePath, "\", "\\")
                escapedOut := StrReplace(finalPath, "\", "\\")
                WebView.ExecuteScript("window.onProcessComplete('" escapedSource "|" escapedOut "')")
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
        } else {
            UpdateLogConsole(WebView, tempLog)
        }
    }
}
