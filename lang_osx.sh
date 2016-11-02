#!/bin/sh

defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | egrep -w 'KeyboardLayout Name' | cut -f2 -d= | cut -f2 -d'"' | cut -f1 -d" "
