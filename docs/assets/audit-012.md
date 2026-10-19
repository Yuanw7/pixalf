# 012 素材盘点 · Trap and Weapon 新增机关

版本 0.8.0。本文件只记录本轮新增接入的原图与淘汰理由；已有六包盘点见 [006 清单](complete-audit-006.md)，011 敌人与机关盘点见 [011 清单](audit-011.md)。

## 来源校验
`assets/originals/Trap and Weapon.zip` 与用户提供路径 `/Users/kafufu/Desktop/素材/Trap and Weapon.zip` 的 SHA256 完全一致：

```
c0c5bfe3897b1fcc8f083675bec30484d92e5a5fa42f36937e57006b3cb89c4c
```

属同一素材包，本轮**没有新增外部包**，只是把包内此前未使用的图接入运行时。逐文件哈希见 `reports/012-audit/inventory.json`；包内共 227 个文件，全部为原样保存，未裁剪、未改色、未重绘。

## 新增内嵌键（7）
| 键 | 原文件 | 尺寸与帧格 | 接入用途 |
|---|---|---|---|
| TrapFireBox | FireBox.png | 208×32 → 16×32×13 帧 | 火焰喷射器本体：帧 8–12 关闭态，帧 0–7 点火序列 |
| TrapFire | Fire.png | 64×16 → 16×16×4 帧 | 火柱段，按 16px 步长沿喷射方向平铺 |
| TrapFan | Fan.png | 256×16 → 32×16×8 帧 | 鼓风机，按方向旋转绘制，吹风时叠加代码风线 |
| TrapBomb | Bomb.png | 160×32 → 32×32×5 帧 | 炸弹：帧 0 待机，帧 1–4 引信/爆炸 |
| TrapRock | FallingRock.png | 384×32 → 32×32×12 帧 | 塌落拱顶：岩石开裂到碎裂 |
| TrapBrick | Brick1.png | 256×32 → 32×32×8 帧 | 塌落后的碎石残留 |
| TrapWall | Trap_Spike.png | 80×32，三个不连续部件 | 定向墙刺：四向 32×32(0,0)、竖向 16×32(32,0)、横向 32×16(48,0) |

`Trap_Spike.png` 是**非等宽部件条**而非等距动画条，这是本轮唯一按子矩形使用的图，已在 index.js 顶部注释固定其裁剪契约。

## 复用的旧键（不新增）
`TrapSpikes`(Spike_B 32×32×10) 用于新的连排地刺；`TrapSaw`/`TrapBow`/`TrapPlatform`/`TrapMace` 沿用 0.7.0 用途。

## 淘汰与理由
按**俯视角可读性**逐个排除，非遗漏：

| 未接入 | 原因 |
|---|---|
| Jumper.png、Arrow_Double_Jump.png | 横版弹跳台，俯视无对应语义 |
| Spear.png、Be_Spear.png、Be_Xich.png | 横版长矛穿刺，俯视无法表达纵深 |
| Moving Platfrom_A/C/D/G/H.png | 8–16px 薄横版平台，俯视会成为无意义细线 |
| 00–32.png、00 All.png | 吊顶/绞盘/绳段/吊笼机关，属侧视天花板装置 |
| Rocket Bullet/ 160 帧、00 Gun.png、00 All_Rocket.png | 枪械与火箭弹序列，与近战机关风格不符 |
| Wood.png、Matxich*.png | 4×4–16×16 装饰小块，不足以构成机关 |
| Brick1 的独立碎块帧 | 已由 TrapBrick 整条覆盖 |

## 状态
技术检查：帧格与内嵌均已由 `tests/level-complexity.mjs` 断言（43 资源、6 类机关布置、预警与休止期）。
用户认可：待反馈。
回退：删除 `scripts/prepare_assets.py` 中新增的 7 个键并重新生成 `assets.js`，游戏自动回到 0.7.0 行为；原包与旧交付快照均未改动。
