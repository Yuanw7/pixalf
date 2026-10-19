# 当前验证状态

- Mac arm64 QuickJS 2026-06-04构建成功，原生库仅链接libc++与libSystem，无JavaScriptCore/Cocoa/WebKit依赖。
- 1270条QuickJS/Node响应对照通过，包括四关1200帧、LPC绘图命令、暂停/重试、森林重新启动；数值容差relative 1e-8。
- 原Godot回归1246项全部通过，经典换装/暂停/重试等21项包含在内。
- 本机测试中60次规则step均值约0.434毫秒；不代表手机帧率、完整绘制耗时或散热表现。
- 原workshop文件基线逐项核对无变动；实验区rules.js与原文件逐字节一致。
- Android构建入口已写，预检因缺少NDK明确退出，未生成.so/APK。尚未测试安卓真机或此次桌面GUI外观。

## 搭建时解决的问题

1. QuickJS源码需要GNU C语法，构建选择gnu11。
2. macOS大小写不敏感文件系统中的VERSION会遮蔽C++标准头version，使用-iquote隔离第三方头路径。
3. 规则里的window为全局词法变量，通过JS求值获取，不把它假定为globalThis属性。
4. 保留旧Godot调用方的invalid request/active错误响应约定，原回归无需放宽断言。
5. 森林重新开局对照必须同时重置参考引擎，避免把跨局残留camera误判为引擎差异。
6. 沙盒内Godot不能访问系统字体和实验存档，完成的测试使用正常本机权限，存档始终隔离。
