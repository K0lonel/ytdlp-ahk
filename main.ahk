#Requires AutoHotkey v2.0+
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
EnvSet("PYTHONIOENCODING", "utf-8")

; Ensure the tools directory exists and extract pre-packaged binaries if compiled
DirCreate("lib/yt-dlp")
FileInstall("lib/yt-dlp/yt-dlp.exe", "lib/yt-dlp/yt-dlp.exe", 0)
FileInstall("lib/yt-dlp/ffmpeg.exe", "lib/yt-dlp/ffmpeg.exe", 0)

global updateLog := A_Temp "\ytdlp_update.log"
global updatePid := 0

; Run yt-dlp update check directly in the background at startup and write output to log
try {
    if FileExist(updateLog)
        FileDelete(updateLog)
    Run(A_ComSpec " /c `"" A_ScriptDir "\lib\yt-dlp\yt-dlp.exe`" -U > `"" updateLog "`" 2>&1", A_ScriptDir "\lib\yt-dlp", "Hide", &updatePid)
}


; Include WebViewToo and JSON library files
#Include lib/WebView2/WebViewToo.ahk
#Include lib/JSON.ahk
FileEncoding "UTF-8"

; Include modular code components
#Include lib/WindowControls.ahk
#Include lib/Updater.ahk
#Include lib/Renamer.ahk
#Include lib/Downloader.ahk
#Include lib/Converter.ahk

ScriptPID := DllCall("GetCurrentProcessId")
GroupAdd("ScriptGroup", "ahk_pid" ScriptPID)

; Create WebViewToo instance with a clean borderless window
global MyWindow := WebViewGui("-Caption +Resize", "YT-DLP & FFmpeg Tool",, { DataDir: A_ScriptDir "\.webview2-data" })
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
MyWindow.NavigationCompleted(OnNavigationCompleted)
MyWindow.Navigate("index.html")

; Show the window
MyWindow.Show("w1100 h750 Center")

; Standard hotkeys for debugging
F12::MyWindow.OpenDevToolsWindow()
$^t::ExitApp()
^r::Reload()
