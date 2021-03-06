#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar -c $HOME/.config/polybar/config i3bar_left &
polybar -c $HOME/.config/polybar/config i3bar_center &
polybar -c $HOME/.config/polybar/config i3bar_right &
