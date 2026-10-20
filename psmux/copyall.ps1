$tmp = Join-Path $HOME '.psmux\copyall.txt'
# capture via cmd so the UTF-8 bytes land on disk untouched (PS 5.1 would decode them as OEM)
cmd /c "psmux capture-pane -p -J -S - > `"$tmp`""
$text = [IO.File]::ReadAllText($tmp, [Text.Encoding]::UTF8).TrimEnd()
[IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding $false))
psmux load-buffer -w $tmp
$lines = if ($text) { ($text -split "`n").Count } else { 0 }
psmux display-message "Copied $lines lines to clipboard"
