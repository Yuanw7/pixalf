# 018 最终交付复验

交付目录：`builds/workshop-018-20261010T073720Z/`。

- 从应用自身 `Contents/MacOS/Thornbound --headless -- --self-test` 运行：289 checks / PASS；日志 `018-package-tests.log`。
- BUILD_MANIFEST.json 内156个文件SHA256全部一致。
- 直接打开最终 `.app`，显示两张内置地图与此前通过UI创建的「错峰地刺 · 自建示例」；确认跨进程持久化及中文名称。
- 最终版本修复了截图中火焰白块，统一使用缓存纹理。最终截图见018-home.png与018-traps.png。
- 应用约336MB，自带官方Godot引擎；源码ZIP、地图JSON、操作指南、装备计划、测试报告在同一交付目录。

代码完成、技术通过、已交付；用户认可待反馈。应用源码快照中的任务卡记录的是打包前状态，最终交付状态以本文与工作区任务卡为准。
