#!/bin/zsh
set -eu
cd "$(dirname "$0")"
engine="${GODOT_BIN:-./runtime/Godot}"
if [[ ! -x "$engine" ]]; then
  print '未找到 Godot。请设置 GODOT_BIN 为 Godot 可执行文件路径，或用 Godot 打开 game/project.godot。'
  exit 1
fi
mkdir -p reports
if [[ "${1:-}" == "--check" ]]; then
  [[ -f game/project.godot && -f game/native/libclassic.dylib ]] || { print "游戏文件不完整。"; exit 1; }
  print "启动入口正常：$PWD/启动实验版.command"
  print "游戏目录：$PWD/game"
  exit 0
fi
print "正在启动荆棘盟约，请等待游戏窗口出现……"
if [[ ! -f game/native/libclassic.dylib ]]; then python3 scripts/build.py macos; fi
"$engine" --headless --editor --path "$PWD/game" --import > reports/import.log 2>&1
exec "$engine" --path "$PWD/game" "$@"
