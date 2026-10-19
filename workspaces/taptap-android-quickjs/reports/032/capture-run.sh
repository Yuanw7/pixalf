#!/bin/zsh
set -eu
cd /Users/kafufu/pixalf
workspaces/taptap-android-quickjs/runtime/Godot --path workspaces/taptap-android-quickjs/game -- --capture-032 > workspaces/taptap-android-quickjs/reports/032/capture-editor.log 2>&1
workspaces/taptap-android-quickjs/runtime/Godot --path workspaces/taptap-android-quickjs/game -- --capture-032 --play > workspaces/taptap-android-quickjs/reports/032/capture-play.log 2>&1
