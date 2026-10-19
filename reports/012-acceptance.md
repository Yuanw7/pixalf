# 0.8.0验收

## 版本与快照
THORNBOUND 0.8.0，快照 `builds/0.8.0`（`npm run build` 输出目录为准），SHA256 见其 `BUILD_MANIFEST.json`。上一可用版本 0.7.0 保留未覆盖。

## 环境
macOS 桌面；Node v24.21.0 跑模型测试；Chrome 经 HTTP `http://127.0.0.1:5173` 跑浏览器验收。未测 file:// 与其它浏览器。

## 素材
- 来源校验：`assets/originals/Trap and Weapon.zip` 与用户桌面同名包 SHA256 一致，属同一包，本轮未新增外部包。
- 新增内嵌 7 键：TrapFireBox / TrapFire / TrapFan / TrapBomb / TrapRock / TrapBrick / TrapWall；原 36 键字节未变（逐键比对），共 43。
- 帧格契约：FireBox 16×32×13、Fire 16×16×4、Fan 32×16×8、Bomb 32×32×5、FallingRock 32×32×12、Brick1 32×32×8、Trap_Spike 三件套。原图不裁剪不改色。
- 选型理由与淘汰项见 [ADR-012](../docs/decisions/012-trap-gauntlet.md)。

## 模型测试
`reports/012-tests.log`：`npm test` exit=0，8 项全过（语法、森林回归、地牢规则、跳跃击退、火球火梁、随从熔岩、怪物机关、机关复杂度、三角色闯关）。

`reports/012-complexity.json`（新增）验证：
- 43 资源、6 类新机关均已布置；每关机关数 5/9/9/5；第1关 4 只摆锤、第3关 3 把旋转锤。
- 周期机关休止期 ≥ 周期 1/3；flame/bomb/rockfall 前置预警 ≥0.8s。
- **公平性不变量**：任何机关的伤害或风压区域都不覆盖四个检查点出生点（144,752 / 816,752 / 1520,752 / 2112,1264），也不覆盖两块题板共 18 个数字格中心。
- 逐类行为：火焰点火→喷火→灼伤击退且跳跃可躲；鼓风机吹动位移且零伤害；炸弹接触点燃 1.1s 引信、半径内爆炸、离开半径可免；墙刺 收起→预警→弹出 定向伤害；连排地刺相位错开且踩中受伤；塌落拱顶 待机→裂缝→落石，看到裂缝可走开。
- 暂停冻结全部新机关状态；R 重试清掉已点引信；`muteTraps` 关卡门控仍可隔离机关。

## 完整闯关
`reports/012-normal-play.json`：三名主角正常属性、普通输入（攻击/技能/点击寻路 + 依据只读状态躲摆锤与弹丸），无传送、无加血、无静音机关，均首次通过四关：53.0s / 53.5s / 46.0s，访问关卡 [0,1,2,3]，刷怪 123 / 129 / 108。

## 浏览器实测
被工具限制：CDP `Page.captureScreenshot` 在本环境超时（连 example.com 亦失败），故 DOM 层截图缺失；标签页被节流（rAF≈1Hz），无法用墙钟实时游玩。改用两条替代证据：

1. **出货入口真实输入**：`index.html` → 点击"开始远征" → 真实键盘 `d`/`j`，以注入的确定性帧推进驱动同一 `loop()`。结果 mode=playing、time=2.06s、stage 0、trial=question（"5 + 3 = ?" 剩 2.7 秒）、43 资源、2 只怪已刷出；画面 `012-live-run.png` 同时可见题板、正在喷火的火箱、两处连排地刺（相位不同）、墙刺与地刺。
2. **独立场景取景**：`scripts/preview-levels.py` 生成 5 张场景页，各自把该关机关置于可读相位后暂停取景：
   - `012-hall-live.png`：第0关题板 + 喷火火箱 + 竖排地刺 + 墙刺 + 引爆中的炸弹；
   - `012-corridor-live.png`：第1关 4 只摆锤 + 锯轮 + 箭弩 + 炸弹引信 + 裂缝预警 + 墙刺 + 连排地刺 + 鼓风机风线；
   - `012-trials-live.png`：第2关题板 + 两处火焰喷射器（喷火/预警）+ 落石（裂缝/落石）+ 连排地刺 + 墙刺；
   - `012-beam-live.png`：第4关木梁 + 塌板裂缝 + 梁上炸弹 + 旋转锤 + 入口西向风门风线 + 楼梯锯轮；
   - `012-lava-live.png`：第4关西段 + 塌板崩裂 + 摆锤 + 敌人。
   场景页为显式隔离夹具，仅用于取景，不作为正式入口随包发布；其运行态关卡与机关相位在取景时逐项打印核对。

## 本轮修掉的既有问题
- 摆锤在全部关卡绘制（第4关顶部会看到第1/2关的锤头）：改为只绘制当前关卡的锤头，与新机关的门控一致。
- `index.html` footer 仍写 BUILD 0.7.0；`tests/trials.mjs` 输出仍写 version 0.7.0；`docs/project/workflow.md` 仍写"当前游戏版本0.2.0"：一并更正。

## 限制
- 用户试玩难度与视觉认可待反馈；现有技术通过不代表用户认可。
- 触控、联网、原生安装器、中途持久存档仍暂缓；存档格式未变，`thornbound.trials.v2`/`thornbound.v2` 继续兼容。
- 第4关木梁致死强度按"公平"档位冻结在 0.7.0 水平，未进一步加码，理由见 ADR-012。

## 交付快照核对
`builds/0.8.0`（`npm run build` 输出目录）：BUILD_MANIFEST.json 中 6 个文件 SHA256 全部重算一致；`game/` 四个文件与工作区源文件逐字节相同；`source.zip` 含 647 条，包含本轮新增的 `tests/level-complexity.mjs`、`scripts/preview-levels.py`、`docs/decisions/012-trap-gauntlet.md`、`reports/012-acceptance.md`。0.7.0 快照仍为 6 个文件，未被覆盖。
包入口实测 `http://127.0.0.1:5173/builds/0.8.0/game/index.html`：footer 显示 BUILD 0.8.0，`gameStatus().assets=43`，开始远征后 mode=playing、真实键盘 d/j 驱动下时间前进、trial 进入 prepare，画面导出 `reports/012-delivery-live.png`。
说明：首次构建的 0.8.0 目录在随后修正 `scripts/build.py` 内的 START_HERE 文案与测试死代码后被重新生成；该版本此前从未标记交付或验收，因此未按"重复构建不覆盖"规则另开时间戳目录，保持 `builds/0.8.0` 唯一。
