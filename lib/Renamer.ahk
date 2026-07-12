RenameAllFilesIndex(dir, rulesList, tempLog) {
    renamedPaths := []
    Loop Files, dir "\*.*", "F" {
        filePath := A_LoopFileFullPath
        SplitPath(filePath, &name)
        
        finalPath := ApplyRenamingRules(filePath, rulesList)
        
        SplitPath(finalPath, &newName)
        if (finalPath != filePath) {
            FileAppend("[Renamer] Renamed: `"" name "`" -> `"" newName "`"`r`n", tempLog)
            renamedPaths.Push(finalPath)
        } else {
            renamedPaths.Push(filePath)
        }
    }
    return renamedPaths
}

ApplyRenamingRules(filePath, rulesList) {
    if (filePath == "" || !FileExist(filePath))
        return filePath

    SplitPath(filePath, &name, &dir, &ext, &nameNoExt)
    newFilename := nameNoExt
    
    for rule in rulesList {
        pattern := rule.pattern
        replacement := rule.replacement
        if (pattern == "")
            continue
        
        ; Convert \uXXXX to \x{XXXX} for PCRE regex compatibility
        pattern := RegExReplace(pattern, "\\u([0-9a-fA-F]{4})", "\x{$1}")
        
        if (!RegExMatch(pattern, "^[a-z]*\)")) {
            pattern := "i)" pattern
        }
        
        try {
            newFilename := RegExReplace(newFilename, pattern, replacement)
        }
    }
    
    newFilename := RegExReplace(newFilename, "\s+", " ")
    newFilename := RegExReplace(newFilename, "\s*(\(|\[)\s*", " $1")
    newFilename := RegExReplace(newFilename, "\s*(\)|\])\s*", "$1 ")
    newFilename := RegExReplace(newFilename, "\(\s*\)|\[\s*\]", "")
    
    ; Strip vertical bars
    newFilename := RegExReplace(newFilename, "[\|｜]", "")
    newFilename := RegExReplace(newFilename, "\s+", " ")
    newFilename := Trim(newFilename)
    
    ; Trim trailing/leading delimiters and dashes
    newFilename := RegExReplace(newFilename, "[\-\s]+$", "")
    newFilename := Trim(newFilename)
    
    ; Filter characters: keep only standard A-Z, a-z, 0-9, hyphen, comma, underscore, parens, brackets, and space
    newFilename := RegExReplace(newFilename, "[^A-Za-z0-9\-\,_\(\)\[\] ]", "")
    
    ; Re-run space and delimiter cleanups on the filtered string
    newFilename := RegExReplace(newFilename, "\s+", " ")
    newFilename := RegExReplace(newFilename, "[\-\s]+$", "")
    newFilename := Trim(newFilename)
    
    if (newFilename == "") {
        newFilename := nameNoExt
    }
    
    newPath := dir "\" newFilename "." ext
    if (newPath != filePath) {
        try {
            FileMove(filePath, newPath, 1)
            return newPath
        } catch {
            return filePath
        }
    }
    return filePath
}
