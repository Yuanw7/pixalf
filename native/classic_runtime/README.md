# ClassicRuntime · macOS应用内经典地图

自有Objective-C++ GDExtension，将Apple WKWebView作为子视图添加到现有Godot NSWindow；没有外部浏览器、第二个游戏窗口或网络服务。原0.8.0四个文件保持原样；注入只处理布局和记录存储。

构建：在macOS安装Xcode Command Line Tools后执行 `sh scripts/build-classic-runtime.sh`。输出arm64/x86_64通用libclassic.dylib。本机临时签名，不等于发行公证。当前Mac版本；其他平台明确提示不支持，不跳转外部浏览器。

GDExtension接口头文件来自Godot 4.4-stable官方源，保留MIT许可头：
https://github.com/godotengine/godot/blob/4.4-stable/core/extension/gdextension_interface.h
SHA256 `355ff4c6254fdd434ea16d9a8ef0f18e3f95aeb3e3f00d98db10769ece3c7fe5`。使用兼容的4.2类注册接口；本项目已验证Godot4.7.2。

原生窗口句柄：https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-window-get-native-handle
Apple原生视图：https://developer.apple.com/documentation/webkit/wkwebview

run_json仅提供open/status/inspect/close。inspect只读游戏状态，不提供修改游戏状态或执行任意脚本的接口。所有AppKit调用在主线程。关闭移除WebKit消息处理器与视图，释放运行实例；工坊草稿不变。返回后重新开始一局，已完成记录保留。

记录桥只接受主frame与两个允许的记录键，各16KB上限；写入user://classic080-records.json并保留.bak。采用非持久WebKit数据仓库，存档由本机原子文件管理，构建路径改变不会丢记录。不会读取或迁移外部浏览器记录。载入/运行中断有错误文案与返回入口。

## 022 当前游玩入口

现版不调用上面的WebView显示路径。simulation.mm使用系统JavaScriptCore运行legacy_rules/rules.js，只有计算和绘图指令；Godot legacy_game/legacy_canvas接管输入、CanvasItem绘制、HUD与LPC角色。

运行`python3 scripts/prepare-native-classic.py`从原0.8.0提取模块和43份原图（无历史build目录时使用随源码附带的workshop/demo080原文件），再执行上述native构建。`node tests/native-classic022.mjs`对照原版规则，`node tests/legacy-playthrough022.mjs`执行正常属性四关机器人。原图既有PNG也有JPEG，按原格式保留。
