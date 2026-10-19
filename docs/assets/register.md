# 素材登记与审核

原始包及SHA256见sources.json。已有素材直接制作接入小样；未经历占位制作阶段，不追写不存在的历史。后续新增素材先用占位验证占地与动作，再制作正式版本。

|资源|尺寸契约与参数|小样/技术检查|人工审核|接入/发布版本|回退|
|---|---|---|---|---|---|
|Soldier / Orc / Demon_A|100×100横向帧；固定裁剪(28,24,48,48)，Canvas目标120×120；保持像素采样|asset-review.png；原图透明范围已检查|技术视觉检查已有；用户审美待认可|index.js / assets.js；0.1.0本地|原包→prepare_assets.py；或旧交付包|
|Blood Monster_A|同上；Idle/Walk/Attack01/Death|asset-review及实际战斗截图|用户待认可|0.1.0本地怪物|同上|
|grass / objects树木|16×16→32×32；树木(0,80,48,64)→76×102|避免Premium文字格；delivery.png|用户待认可|0.1.0地图|同上|
|合成路径/篝火/粒子|index.js代码参数|实际场景截图|用户待认可|0.1.0|恢复旧index.js|

原始候选保留在assets/packs；运行索引由scripts/prepare_assets.py生成；无AI生成提示词。许可证信息以docs/decisions/001-assets.md及原包为准，不把待核实许可写成已许可。

替换记录必须填写：资源ID、需求和尺寸、原候选位置与校验值、制作工具/参数、技术结果、人工审核人/日期/结论、场景截图、发布快照、上一版本位置、回退步骤。技术检查、人工认可与发布三个状态独立。

## 迭代003 / 0.2.0素材接入
- Slime：使用原32×32图集，idle第0行4帧、walk第3行6帧、attack第6行7帧，目标80×80；原图检查见003-assets-review.png。
- 敌对兽人/恶魔：复用原100×100帧素材、相同裁剪契约；由模型类别决定战斗差异，以红圈区别伙伴，不重新绘制角色。
- 石块：objects(0,16,16,16)→52×52；遗迹墙：objects(32,0,16,16)→38×38；花草：decor(0,0,16,16)→32×32。已检查这些区域，不使用带Premium文字的格子；技术小样见003-terrain-review.png。
- 水面、古桥、帐篷、路径、标签和小地图为代码绘制；未使用带付费提示的water图集。
- 场景技术审核：003-character-select.png、003-map-overview.png及003-live-combat.png。用户美术认可仍待反馈。
- 原始包与候选未修改；参数见index.js、生成工具prepare_assets.py；发布候选0.2.0。回退直接使用旧0.1.0/assets.js及游戏目录，不覆盖原包。

## 迭代004 / 0.3.0
- 新原包RF_Catacombs_v1.0.zip、Icons.rar完整保存在assets/originals；解压候选在assets/packs。哈希见sources.json；工具prepare_assets.py，仅复制及嵌入，无AI生成。
- 地宫mainlevbuild 1024×640：地板(736,208,32,32)、墙(80,144,32,32)、柱(400,112,32,80)→46×96；torch_1 16×16→32×32。房间/走廊按32像素网格拼接。
- Icons32×32：icon1血药、icon13武力、icon5速度。原图/图集技术检查004-asset-review.png、004-catacomb-grid.png；实际接入004-power-pickup.png和004-speed-effect.png。
- 像素爆发、十字回血粒子、橙色武力光环、绿色速度拖尾为代码绘制；敌人变色/缩放来自缓存Canvas参数，原图不覆盖。
- Szadi art原包public-license.txt允许使用修改但不得转售素材包；Icons未附许可。原有非商业/不可再分发限制继续适用。
- 技术视觉检查已完成，用户审美审核待反馈。发布0.3.0本地候选；回退打开保留的0.2.0完整包，不覆盖原始候选。

## 迭代005检查
pixel_16_woods v2 free.zip已原样保留，图集352×192，仅树木/地面/装饰，没有六种敌人；不从地形裁剪冒充角色。旧版“十种变体”被用户否定，现已移除主角复用和变色变体。六个新敌人尚无独立素材，等待来源或制作决定。

迭代006：全面盘点见complete-audit-006.md；补接入Mystic Woods/player.png（288×480，48帧格），不是现有三主角资源；运行时名林地游匪。原始图不修改、不变色；本地非商业许可沿用。技术视觉证据006-new-enemy-live.png，用户认可待反馈。

迭代007：地牢砖面、角色和药水继续使用已审核原素材；数字地板边框、熔岩像素、落砖缩放、摆锤链条与锤头、门符由Canvas代码绘制。无新增外部素材或修改原图。实际技术画面见007-equation、007-lava-collapse、007-pendulum-corridor，用户认可待反馈。

迭代008：木梁、熔岩、旋转锤和跳跃投影继续代码像素绘制，未覆盖原始角色图。跳跃复用原角色动作、升高绘制位置，影子留地面。截图008-jump-live和008-landing-live为独立场景技术审核，用户视觉认可待反馈。

## 迭代009 / 0.6.0
- 用户两张附件原样保存assets/custom/009/{fire-reference,lava-reference}.png；熔岩原图直接作为192px平铺纹理，1.5px/s漂移。
- FireElemental：使用内置imagegen参照用户火焰怪生成独立透明单图；原始输出复制为fire-elemental.png，完整提示词/来源/哈希见同目录manifest.json。真实alpha，运行58×70px最近邻采样，浮动±3px、蓄力扩6px。未复用主角或给旧怪变色。
- 技术画面009-fire-lava-scene.png与009-three-gaps-overview.png；代码与视觉技术检查通过，用户审核待反馈。公开发布许可未另行判定，沿用本地原型范围。回退旧0.5.0完整游戏。

迭代010：沿用009火元素原图与熔岩纹理，无生成/修改图片。火怪模型改为熔岩驻点小范围移动；用户手感认可待反馈。

## 迭代011 / 0.7.0
两新包原样备份与SHA256登记sources.json；全量审阅audit-011.md。接入Monster00/01/02/03/09五表（80px格、6/8/6待机/行走/攻击、目标110px），保留原Slime。旧WoodsBandit/Blood Monster_A/生成FireElemental从运行索引移除，原图保留。
接入Spike_B/Suriken/Shooter_Arrow_Trap/FallingPlatfrom/SpikeBall，尺寸和帧契约见audit-011.md；prepare_assets.py可复建内嵌索引。技术截图011-corridor-live与011-lava-live通过；无新生成或改图。用户美术认可待反馈；回退0.6.1完整包。

## 迭代012 / 0.8.0
Trap and Weapon包（assets/originals，SHA256 c0c5bfe3…，与用户桌面同名包一致）本轮不再整包接入，只补7张此前未使用的原图：FireBox(16×32×13)、Fire(16×16×4)、Fan(32×16×8)、Bomb(32×32×5)、FallingRock(32×32×12)、Brick1(32×32×8)、Trap_Spike(三部件非等宽条：四向32×32/竖向16×32/横向32×16)。全部原样内嵌，不裁剪不改色；逐文件哈希见reports/012-audit/inventory.json，选型与淘汰理由见audit-012.md。
连排地刺复用已内嵌的Spike_B，不新增键。淘汰Jumper/Spear/Moving Platform/00–32吊顶件/Rocket Bullet等横版机关，理由为俯视角无对应语义。
内嵌资源36→43，原36键字节未变（逐键比对）。技术画面012-hall/corridor/trials/beam/lava-live.png为独立场景取景，012-live-run.png为出货入口真实输入画面；用户美术认可待反馈。回退：删除prepare_assets.py中新增7键并重新生成assets.js，或直接打开0.7.0完整包。

## 迭代013 / 0.9.0
本轮**不新增原图**：boss 按用户指示直接复用已内嵌的 Monster01（枯木守卫）并按 3.4 倍放大绘制，属运行时缩放，原图不修改、不变色、不重新导出。内嵌资源仍为 43 键。
新增机关为纯代码：木头人红绿灯状态机与眼部激光、`BEAM_LAND` 实体登陆台、火带沿用已内嵌的 TrapFire 原图（Fire.png 4 帧）平铺。技术画面 013-doll-live.png（巨像红眼 + 三条喷发火带 + 一条预警火带 + 队伍站在空档 + 右上角红灯）、013-trials-live.png、013-beam-live.png、013-live-run.png。用户美术认可待反馈。回退直接打开 0.8.0 完整包。


016 工坊复用 RF_Catacombs mainlevbuild、Tiny RPG Soldier_Idle、TrapAndWeapon Spike_B/Bomb，复制为 workshop/art 四张 PNG。未新增 AI 图像。Godot 4.7.2 引擎许可见 workshop/GODOT-LICENSE.txt 与 GODOT-COPYRIGHT.txt；素材仍限持有者本地原型。
