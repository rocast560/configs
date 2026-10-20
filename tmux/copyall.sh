#!/bin/sh
# Copy the whole history of pane $1 to the clipboard. Bound to prefix + C.
text=$(tmux capture-pane -p -J -S - -t "$1")

# load-buffer -w sets the system clipboard through the terminal (OSC 52),
# which also works over SSH
printf '%s' "$text" | tmux load-buffer -w -

# terminals without OSC 52 (e.g. GNOME Terminal) need a clipboard tool
if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null; then
    printf '%s' "$text" | wl-copy
elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null; then
    # xclip stays running to own the selection; detach its output so run-shell returns
    printf '%s' "$text" | xclip -selection clipboard >/dev/null 2>&1
fi

if [ -n "$text" ]; then lines=$(printf '%s\n' "$text" | wc -l); else lines=0; fi
tmux display-message "Copied $lines lines to clipboard"
