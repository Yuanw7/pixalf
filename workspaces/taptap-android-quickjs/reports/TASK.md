# 023 · QuickJS独立工作区搭建

用户授权：采用最省改动的QuickJS＋Godot GDExtension方案，先在明确标记的文件夹搭建。
范围：独立游戏副本、独立存档、QuickJS官方源码、便携运行器、Mac本机验证、Android构建脚手架。
验收：经典规则不改；QuickJS规则对照通过；Godot扩展实际调用通过；原工作区哈希不变。
不包含：安卓真机/完整APK交付、TapTap账号开通或上架、移动端UI完成。
状态：本次独立工作区搭建完成。
技术通过：Mac arm64 QuickJS编译；1270条跨引擎响应对照；Godot原1246项回归全部通过；原工作区哈希与规则字节一致。
限制：Android SDK/NDK未安装，Android原生库/APK与真机尚未验证；此次没有进行GUI视觉验收。
下一步：准备Android工具链，编译arm64库，配置APK导出并进行真机第一关验证。
