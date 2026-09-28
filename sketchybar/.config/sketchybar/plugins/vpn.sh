#!/bin/sh

sketchybar --set "$NAME" label="vpn $(scutil --nc status "incy" | grep -qE "^Connected\$" &&  echo '🟢' || echo '🔴')"
