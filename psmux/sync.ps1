$state = (psmux display-message -p "#{pane_synchronized}").Trim()
if ($state -eq '1') {
    psmux set-window-option synchronize-panes off
    psmux display-message "SYNC OFF"
} else {
    psmux set-window-option synchronize-panes on
    psmux display-message "SYNC ON"
}
