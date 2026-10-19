#!/bin/zsh
set -eu
cd /Users/kafufu/pixalf
for mode in wood math multi; do
  args=(--capture-031)
  [[ "$mode" == math ]] && args+=(--math --play)
  [[ "$mode" == multi ]] && args+=(--multi)
  [[ "$mode" == wood ]] && args+=(--play)
  workspaces/taptap-android-quickjs/runtime/Godot --path workspaces/taptap-android-quickjs/game -- "${args[@]}" > "workspaces/taptap-android-quickjs/reports/031/capture-$mode.log" 2>&1
done
