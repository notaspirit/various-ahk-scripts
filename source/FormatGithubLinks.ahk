#Requires AutoHotkey v2.0
; Hotkey: Win + Shift + Q
#+q:: {
    clip := A_Clipboard
    url := Trim(clip)

    if RegExMatch(url, "https://github\.com/([^/]+)/([^/]+)/(issues|pull)/(\d+)", &m) {
        ; Issue or PR link
        owner := m[1]
        repo := m[2]
        number := m[4]

        title := ""
        try {
            apiUrl := "https://api.github.com/repos/" . owner . "/" . repo . "/issues/" . number

            req := ComObject("WinHttp.WinHttpRequest.5.1")
            req.Open("GET", apiUrl, false)
            req.SetRequestHeader("User-Agent", "AHK-Script")
            req.SetRequestHeader("Accept", "application/vnd.github+json")
            req.SetTimeouts(3000, 3000, 3000, 3000)
            req.Send()

            if (req.Status = 200) {
                body := req.ResponseText
                if RegExMatch(body, '"title"\s*:\s*"((?:[^"\\]|\\.)*)"', &tm) {
                    rawTitle := tm[1]
                    rawTitle := StrReplace(rawTitle, '\"', '"')
                    rawTitle := StrReplace(rawTitle, "\\", "\")
                    rawTitle := StrReplace(rawTitle, "\/", "/")
                    title := Trim(rawTitle)
                }
            }
        } catch {
            title := ""
        }

        if (title != "")
            formatted := "[#" . number . ": " . title . "](<" . url . ">)"
        else
            formatted := "[#" . number . "](<" . url . ">)"

        A_Clipboard := formatted
        ToolTip("✓ Transformed to: " . formatted)

    } else if RegExMatch(url, "https://github\.com/([^/]+)/([^/]+)/blob/[^/]+/(.+?)/?$", &m) {
        ; File link: {username}/{repo}: {filename}
        owner := m[1]
        repo := m[2]
        path := m[3]

        ; Filename is the last segment of the path
        parts := StrSplit(path, "/")
        filename := parts[parts.Length]

        formatted := "[" . owner . "/" . repo . ": " . filename . "](<" . url . ">)"
        A_Clipboard := formatted
        ToolTip("✓ Transformed to: " . formatted)

    } else if RegExMatch(url, "https://github\.com/([^/]+)/([^/]+)/?$", &m) {
        ; Repo link: {username}/{reponame}
        owner := m[1]
        repo := m[2]
        formatted := "[" . owner . "/" . repo . "](<" . url . ">)"
        A_Clipboard := formatted
        ToolTip("✓ Transformed to: " . formatted)

    } else if RegExMatch(url, "https://github\.com/([^/]+)/?$", &m) {
        ; Profile link: username
        username := m[1]
        formatted := "[" . username . "](<" . url . ">)"
        A_Clipboard := formatted
        ToolTip("✓ Transformed to: " . formatted)

    } else {
        ToolTip("✗ Not a GitHub link")
    }

    SetTimer(() => ToolTip(), -2000)
}