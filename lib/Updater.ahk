OnNavigationCompleted(WebView, Args) {
    global updatePid
    defaultDir := A_ScriptDir "\yt-download"
    DirCreate(defaultDir)
    escapedPath := StrReplace(defaultDir, "\", "\\")
    js := "if (window.setInitialDir) { window.setInitialDir('" escapedPath "'); } else { window.initialDir = '" escapedPath "'; }"
    WebView.ExecuteScriptAsync(js)
    
    ; Start monitoring the startup update check process logs
    if (updatePid) {
        SetTimer(MonitorUpdateLog.Bind(WebView), 200)
    }
}

MonitorUpdateLog(WebView) {
    global updatePid, updateLog
    static lastSize := 0
    if (updatePid && !ProcessExist(updatePid)) {
        ; Update check finished, stop timer
        SetTimer(, 0)
        
        ; One last read
        if FileExist(updateLog) {
            UpdateLogConsole(WebView, updateLog)
            try {
                FileDelete(updateLog)
            }
        }
        updatePid := 0
        return
    }
    
    if FileExist(updateLog) {
        try {
            currentSize := FileGetSize(updateLog)
            if (currentSize != lastSize) {
                lastSize := currentSize
                UpdateLogConsole(WebView, updateLog)
            }
        }
    }
}
