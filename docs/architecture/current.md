# 当前架构 · 0.9.0 重做 / 迭代015

根目录 README 为当前玩法定义。旧迭代与 ADR 保留历史，当前架构以本文为准。

## 运行与状态
HTML/CSS 负责入口、队伍与说明；assets.js 内嵌 43 个资源；index.js 的 IIFE 包含配置、模型、输入、Canvas 渲染。requestAnimationFrame 的 dt 上限 .04 秒；仅 playing 更新，draw 始终运行。暂停、失焦和全图冻结模型。

|状态|写入入口|用途|
|---|---|---|
|地图、障碍、网格|applyMap/rebuildNavigation|碰撞、BFS流场、静态背景|
|英雄/敌人、生命、技能、跳跃、击退|update/hurt/damage/move|战斗与HUD|
|trial 题目、阶段、就绪、检查点|newTrial/askQuestion/updateTrial/retryTrial|挑战与重试|
|trial.exit / open / completed|interactExit/updateExit|按钮、开门动画、入门切关|
|mechanismState|resetMechanisms/updateMechanisms|机关状态机|
|结果记录|end/finishTrial|localStorage|

## 地牢与门
世界 2880×1440，CELL=32。关卡编号 0算术、1摆锤、2木头人、3熔火、4木梁。

木头人房间为 x1440–2080 / y576–928，640×352；左侧检查点 (1488,784)，素材守卫 (1968,752)，右墙隔板出口 (2080,768)。四道纵向火带 x1568/1664/1760/1856，贯穿房间高352，偏移依次1.8/1.2/.6/0。固定镜头 (1280,416) 显示整间房，左上角小型红绿灯不遮挡终点。

CAMP 定义五关入口：(144,752)、(816,752)、(1488,784)、(2150,752)、(2112,1264)。进门切关统一定位下一入口，恢复最多55HP，清除上一关敌人、弹丸、路径、跳跃和击退。

EXIT_DOORS 为五个出口及按钮的唯一配置，供碰撞、绘制、交互与诊断使用：

|关|门|按钮|
|---|---|---|
|0|(720,768)|(664,808)|
|1|(1408,768)|(1376,688)|
|2 隔板|(2080,768)|(2032,816)|
|3|(2760,752)|(2704,816)|
|4 最终门|(160,1264)|(224,1296)|

`trial.ready` 表示挑战允许按按钮；算术关解完全部题才为 true，行走关到终点按钮旁才能实际交互。`canReachExitButton` 限定游玩中、主角活着、落地、无击退、非坠落、距离≤44且视线可达。F 或近距离 Canvas 按钮点击调用 `interactExit`；远处点击按钮只设置寻路目标。

按按钮设置 activated=true、completed=stage+1，清移动输入，当前机关停止结算并开始 .85 秒开门。`updateExit` 在动画结束后设置 open=true 并重建导航；门打开之前碰撞继续阻挡。主角前缘穿过门平面且身体位于门洞内即可 advanceTrial；move 子步记录 crossed 防止冲刺跳过，跳跃可穿越已开门；最终门调用 end(true)。按按钮与进入下一关是两个独立动作。重试恢复本关未开门状态，completed 回到本关之前。

## 模型约定
- heroes 保留三个索引，仅主角与指定随从 active；随从死亡不换领队。
- move 以最多8px子步执行墙体、门禁、熔岩落脚检查；flow 使用四邻 BFS，门变化重建网格。
- hurt 统一英雄生命、.5秒无敌、.2秒衰减击退与跳跃避伤；damage 统一敌人伤害与同伴倍率。
- 跳跃持续.9秒、冷却1.05秒、正弦高度64；跳跃不越墙，算术结算要求落地。
- 题目 prepare→question(3秒)→collapse(1.5秒)→rest / ready。ready 不等于通关，仍须按钮。
- 时间型机关相位由总游戏时间推导；状态型机关由 mechanismState.timer 更新。R 重置状态型机关，保留总时间，因此周期机关相位不归零。
- 木头人 green3.4→turn.6→red2.6；红期主动位移>12触发.35秒锁定和激光。被击退重取锚点；随从同步停步；按钮后停止判定。
- BEAM_GAPS/BEAM_SEGMENTS/BEAM_LAND 共享木梁绘制与碰撞；随从自动跳并在落空后回主角旁。
- ENEMY_UNLOCKS 随总时间生效；stage2 不刷普通怪。炎魔只在 stage4 熔岩驻点出现。

## 绘制与工具
paintBackground/paintDungeon 缓存静态地图；draw 绘制可见区域、按 y 排序角色/障碍、机关、特效、HUD。drawKeeper 复用 Monster01/TrapBomb 素材；drawExitDoor 用简单竖向隔板填满128px墙洞，上下墙段复用catTiles，wallTop/wallBottom与碰撞共用。updateDollBomb 在普通机关提前返回之前更新，因此开门不清引信；抵达终点→fuse3.5→blast.45→spent，爆炸伤害走hurt，重试/切关清除。

window.gameStatus/mapStatus 为只读诊断副本，含当前出口信息。测试在 Node VM 副本注入 fixture；生产入口不提供写状态接口。scripts/preview-doors.py 生成 reports 下的独立浏览器取景场景；它们不是实际游戏入口。

森林结果 thornbound.v2，地牢结果 thornbound.trials.v3，旧键保留。检查点只在内存。Python 构建拷贝四个运行文件，并生成源码ZIP与校验清单，旧快照不覆盖。

## 016 本地工坊
`workshop/` 是独立 Godot 项目，复用地牢、士兵、地刺和炸弹原图。`level` 保存 JSON schema 1 房间图（walls/spawn/objects，门 target 与开关 link 为稳定 ID）；`runtime` 独立保存每房间计时、门动画和炸弹引信。预创建全部 runtime，只有活动房间 tick，cross_door 切换目标。Godot CanvasItem 绘制32px网格，移动4px子步与网格墙碰撞。试玩不修改 level。保存 temp→bak→rename，读取结构/坐标/ID校验后才替换，JSON 坐标归一为整数。编辑历史最多80步，载入亦可撤销。

## 017 可变房型和配对门
工坊schema 2为每房间增加width/height/shape/rotation/position；map_model.gd为统一几何来源（inside/boundary/door_side）。main绘制通过视图变换适配，物理始终32px；四向子步碰撞，穿越配对门从对应门内一格落脚，入口重试。join在深拷贝上移连通分组、校验重叠、寻找共享墙段、生成配对门/自动开关，成功后才提交到编辑历史。全地图状态预创建，只有当前房间tick。总览暂停。validate分结构与试玩两层，试玩还验证静态道路及沿出口可到达所有房间/终点。旧schema1迁移保留legacy传送连接，重拼后获得空间语义。tests.gd从UI拆出；export_map.gd用同一模型导出four-rooms.json。


## 工坊018补充
trap_catalog.gd统一12类、参数缺省值、相位与范围校验；trap_runtime.gd更新每房间独立运行状态。main.gd提供可折叠工具、逐对象属性、地图大厅、草稿备份和正式游玩HUD。map_library.gd管理user://maps/原子快照及两个内置示例。tests018.gd追加52检查。装备系统尚未实装。

## 工坊019模块化角色
character_catalog.gd统一LPC图层、动作时钟和装备互斥，bake_lpc.gd调用固定版本LPCAnimatedSprite2D生成SpriteFrames。outfit_panel.gd采用草稿预览，保存才更新appearance-v1.json和全地图外观；窗口开启暂停模拟。main沿用原坐标与碰撞，仅替换人物绘制及方向/动作状态。衣柜攻击为预览，没有伤害判定。018的“装备尚未实装”指当时状态，019外观部分已完成。


## 020
visual_rooms.gd负责复制式添加/组移动与吸附候选；main.gd在总览处理按下/拖动/释放，固定预览坐标，提交时snapshot。复用原Model.join及连接组件，地图schema2不变。


## 021
classic_runtime.gd分派原生ClassicRuntime扩展；macOS WKWebView挂载现有窗口，Godot轮询active且屏蔽底层输入。返回释放WebKit，列表与草稿保持。经典记录独立原子JSON，普通地图schema未改。


## 022
022经典入口改由legacy_game/legacy_canvas.gd负责输入和Godot渲染；native simulation.mm运行无页面JavaScriptCore规则，固定60Hz计算，视图指令交给Godot。原背景SubViewport缓存，LPC主角共享character_catalog。衣柜冻结计算，关闭同步外观。原地图数据及普通工坊逻辑不变。
