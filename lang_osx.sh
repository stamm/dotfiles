#!/bin/sh
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' | cut -f2 -d= | tr -d '" ;' | head -c 2
