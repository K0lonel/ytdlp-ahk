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

; Shared Utility: Update Output Console log in WebView
UpdateLogConsole(WebView, logPath) {
    if FileExist(logPath) {
        try {
            logText := FileRead(logPath)
            escapedLog := StrReplace(logText, "\", "\\")
            escapedLog := StrReplace(escapedLog, "'", "\'")
            escapedLog := StrReplace(escapedLog, "`"", "\`"")
            escapedLog := StrReplace(escapedLog, "`r`n", "\n")
            escapedLog := StrReplace(escapedLog, "`n", "\n")
            escapedLog := StrReplace(escapedLog, "`r", "\n")
            
            WebView.ExecuteScriptAsync("if(window.onLogUpdate) { window.onLogUpdate('" escapedLog "'); }")
        }
    }
}
