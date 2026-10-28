sh <<'TMUX_SETUP'
# Sets up tmux with the bindings from github.com/rocast560/configs.
#
# Paste this whole file into a terminal, or run:
#   curl -fsSL https://raw.githubusercontent.com/rocast560/configs/main/tmux/setup.sh | sh
#
# It installs tmux if it's missing, writes ~/.config/tmux/tmux.conf and
# copyall.sh, then reloads the config if you're inside tmux, or starts tmux
# if you're not.
#
# The script runs inside a heredoc so pasting it into bash or zsh is safe:
# set -e and exit end this child shell, not your terminal. For the same
# reason the file has no exclamation marks (history expansion) and no tabs
# (tab completion).

set -eu

say() { printf 'tmux-setup: %s\n' "$*"; }
die() { say "$*" >&2; exit 1; }

install_tmux() {
    if [ "$(id -u)" -eq 0 ]; then
        as_root=
    elif command -v sudo >/dev/null 2>&1; then
        as_root=sudo
    elif command -v doas >/dev/null 2>&1; then
        as_root=doas
    else
        die "installing tmux needs root. Run this as root or install tmux first."
    fi

    # stdin is this script, so package managers read /dev/null instead.
    # sudo still asks for a password through the terminal.
    if command -v apt-get >/dev/null 2>&1; then
        $as_root apt-get update -qq
        $as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tmux
    elif command -v dnf >/dev/null 2>&1; then
        $as_root dnf install -y tmux
    elif command -v yum >/dev/null 2>&1; then
        $as_root yum install -y tmux
    elif command -v pacman >/dev/null 2>&1; then
        # refresh the package list only if it's too old to find tmux
        $as_root pacman -S --needed --noconfirm tmux ||
            $as_root pacman -Sy --needed --noconfirm tmux
    elif command -v zypper >/dev/null 2>&1; then
        $as_root zypper --non-interactive install tmux
    elif command -v apk >/dev/null 2>&1; then
        $as_root apk add --update-cache tmux
    elif command -v xbps-install >/dev/null 2>&1; then
        # xbps won't install anything while xbps itself is out of date
        $as_root xbps-install -Syu xbps
        $as_root xbps-install -y tmux
    else
        die "no supported package manager (apt, dnf, yum, pacman, zypper, apk, xbps). Install tmux and run this again."
    fi </dev/null
}

if command -v tmux >/dev/null 2>&1; then
    say "found $(tmux -V)"
else
    say "tmux not found, installing it"
    install_tmux
    command -v tmux >/dev/null 2>&1 || die "tmux still isn't on PATH after installing it"
fi

version=$(tmux -V | sed -n 's/^tmux [^0-9]*\([0-9]*\)\.\([0-9]*\).*/\1 \2/p')
# builds with no number, like "tmux master", count as new
version=${version:-99 0}
major=${version% *}
minor=${version#* }
if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 2 ]; }; then
    say "tmux $major.$minor is older than 3.2, which this config is written for. prefix + C can only copy through xclip or wl-copy."
fi

dir="$HOME/.config/tmux"
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$dir"

# Writes stdin to the file $1. A different existing file is kept as
# $1.bak-<time>, not overwritten.
put() {
    new="$1.new"
    cat > "$new"
    if [ -f "$1" ] && [ "$(cat "$1")" = "$(cat "$new")" ]; then
        rm -f "$new"
        say "$1 is already up to date"
        return
    fi
    if [ -e "$1" ]; then
        mv "$1" "$1.bak-$stamp"
        say "kept your old $1 as $1.bak-$stamp"
    fi
    mv "$new" "$1"
    say "wrote $1"
}

put "$dir/tmux.conf" <<'CONF'
# --- history ---
set -g history-limit 100000

# --- splits ---
bind v split-window -h -c "#{pane_current_path}"
bind s split-window -v -c "#{pane_current_path}"

# --- pane navigation (vim) ---
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# --- pane resize (shift + vim) ---
bind-key -r H resize-pane -L 5
bind-key -r J resize-pane -D 5
bind-key -r K resize-pane -U 5
bind-key -r L resize-pane -R 5

# --- sync panes (single-key toggle) ---
# tmux toggles an on/off option when no value is given, so this needs no script
bind-key y set-window-option synchronize-panes \; display-message "SYNC #{?pane_synchronized,ON,OFF}"
bind-key Y set-window-option synchronize-panes off

# --- copy all pane output since last clear to clipboard ---
bind-key C run-shell -b "sh ~/.config/tmux/copyall.sh '#{pane_id}'"

# --- visual indicator ---
set -g status-right "#{?pane_synchronized,#[bg=red] SYNC ,}"

# --- reload ---
bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "config reloaded"

# --- session/window chooser (moved, since s, l and L are taken above) ---
bind S choose-tree -s
bind Tab last-window

# 1-n index
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
CONF

# \041 is the shebang's exclamation mark, written by printf to keep it out
# of this file
{ printf '#\041/bin/sh\n'; cat; } <<'COPYALL' | put "$dir/copyall.sh"
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
COPYALL
chmod +x "$dir/copyall.sh"

# tmux 3.1+ loads ~/.tmux.conf as well as ~/.config/tmux/tmux.conf, which
# would mix old settings into these, so the old file is moved aside. Older
# tmux reads only ~/.tmux.conf, so it gets a one-line pointer instead.
if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 1 ]; }; then
    put "$HOME/.tmux.conf" <<'OLDTMUX'
# tmux before 3.1 reads only this file
source-file ~/.config/tmux/tmux.conf
OLDTMUX
elif [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak-$stamp"
    say "moved ~/.tmux.conf to ~/.tmux.conf.bak-$stamp"
fi

conf="$dir/tmux.conf"
if [ -n "${TMUX:-}" ]; then
    tmux source-file "$conf"
    tmux display-message "tmux config reloaded"
    say "reloaded the config in this tmux session"
    if [ -e "$HOME/.tmux.conf.bak-$stamp" ]; then
        say "bindings from the old ~/.tmux.conf stay until every tmux session is closed"
    fi
    exit 0
fi

# detached sessions pick up the new bindings too
if tmux has-session 2>/dev/null; then
    tmux source-file "$conf"
fi

# tmux needs the terminal on stdin, but stdin here is the script, and tmux
# refuses /dev/tty, so open the terminal's real device (/dev/pts/N)
if [ -t 2 ]; then
    term=$(tty <&2)
    say "starting tmux"
    exec tmux new-session -A -s main <"$term"
fi
say "done. Run tmux to start it."
TMUX_SETUP
