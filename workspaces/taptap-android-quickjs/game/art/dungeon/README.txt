0x72 DungeonTileset II v1.7 — 当前人物与怪物

来源：用户提供的 0x72_DungeonTilesetII_v1.7.zip，frames/ 原始 PNG，未修改。
作者：0x72。许可：CC0，作者页面 https://0x72.itch.io/dungeontileset-ii
于 2026-10-13 核实页面声明：You can use this tileset for whatever you like (CC-0).
压缩包自带 README 仅说明地图块布局，保存在 ORIGINAL-README.txt。
source-manifest.json 保存引入的每个 PNG 的 SHA-256。

应用范围：
- knight_m / elf_m：主角。按同步帧分离头部与躯干；皮甲、开面盔、圆盾、手部由 Canvas 按同一像素网格绘制。
- weapon_knife / regular_sword / double_axe / spear：独立主手层。以握柄点绑定手部；knife 同时用于实际飞行投射物。
- tiny_zombie / goblin / masked_orc / big_zombie / ogre / chort：替代六类旧怪外观，既有 AI、数值、碰撞不变。
- orc_warrior / imp：伙伴；ogre 同时替换工坊木头人守卫。
- 死亡残留使用同一新怪物的帧旋转倒下，再淡出。

这套原素材是侧视待机/跑步帧，左右镜像；上下移动保持侧视风格并改变持械前后层次，未冒充原生四方向素材。
攻击、倒地和胜利由游戏组合动画驱动。旧 LPC 文件仍保留用于历史兼容，当前可玩角色不再叠加 LPC 外观。

030 扩展应用范围：floor_* / wall_* 用于经典地宫和工坊的地板、墙面、旗帜；column / crate 为石柱和木箱，flask_* 为小型药瓶。引入原图总数更新为166张，新增素材仍逐张登记在 source-manifest.json。主角铠甲钢灰色在 Canvas 绘制层完成，原始 knight PNG 保持不变。原视频仅作动作节奏参考，不打包或截取视频画面作为游戏素材。
