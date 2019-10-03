#!/usr/bin/env sh

killall -q conky

while pgrep -x conky > /dev/null; do sleep 1; done

conky -c ~/.config/conky/config &
