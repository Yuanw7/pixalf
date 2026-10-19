#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p workshop/native
xcrun clang++ -std=c++17 -fobjc-arc -dynamiclib -arch arm64 -arch x86_64 -mmacosx-version-min=12.0 -framework Cocoa -framework WebKit -framework JavaScriptCore native/classic_runtime/classic.mm native/classic_runtime/simulation.mm -o workshop/native/libclassic.dylib
codesign --force --sign - workshop/native/libclassic.dylib
