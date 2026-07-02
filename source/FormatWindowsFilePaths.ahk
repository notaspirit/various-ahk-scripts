#Requires AutoHotkey v2.0
#SingleInstance Force

#+a::FormatClipboardPath()

FormatClipboardPath() {
    clip := A_Clipboard
    if (clip = "") {
        ToolTip("✗ Not a Windows path")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    if !RegExMatch(clip, "^[A-Za-z]:\\"){
        ToolTip("✗ Not a Windows path")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    
    envNames := [
        "LOCALAPPDATA",
        "APPDATA",
        "TEMP",
        "TMP",
        "ONEDRIVECONSUMER",
        "ONEDRIVE",
        "USERPROFILE",
        "PROGRAMFILES(X86)",
        "PROGRAMFILES",
        "PROGRAMDATA",
        "PUBLIC",
        "ALLUSERSPROFILE",
        "SYSTEMROOT",
        "WINDIR",
        "HOMEDRIVE"
    ]

    entries := []
    for name in envNames {
        val := EnvGet(name)
        ; Strip a trailing backslash if present, for consistent matching
        if (val != "") && (SubStr(val, -1) = "\")
            val := SubStr(val, 1, StrLen(val) - 1)
        if (val != "")
            entries.Push({name: name, value: val})
    }

    ; --- Sort candidates by path length, longest first ---------------
    ; This guarantees the most specific match wins, e.g. APPDATA
    ; (…\AppData\Roaming) is tried before the shorter USERPROFILE
    ; (…\Users\name) which would otherwise match first.
    n := entries.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (StrLen(entries[j].value) < StrLen(entries[j + 1].value)) {
                tmp := entries[j]
                entries[j] := entries[j + 1]
                entries[j + 1] := tmp
            }
        }
    }

    ; --- Find first (longest) matching prefix and replace it ---------
    result := clip
    for entry in entries {
        needle := entry.value
        len := StrLen(needle)
        if (len = 0)
            continue
        ; String "=" comparison in AHK v2 is case-insensitive by default,
        ; which matches Windows' case-insensitive filesystem paths.
        if (StrLen(result) >= len) && (SubStr(result, 1, len) = needle) {
            result := "%" StrLower(entry.name) "%" SubStr(result, len + 1)
            break
        }
    }

    A_Clipboard := result

    ToolTip("✓ Transformed to: " . result)
    SetTimer(() => ToolTip(), -1500)
}
