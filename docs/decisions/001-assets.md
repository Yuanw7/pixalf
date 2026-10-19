# 素材与技术决策
来源：用户目录 /Users/kafufu/Desktop/素材 下三个ZIP。原始文件保存在 assets/originals，原始候选解压在 assets/packs。未使用生成式美术。
Tiny RPG：100×100帧，Idle/Walk/Attack01/Hurt/Death横向图集。绘制时以固定48×48区域取样并整数放大，保持原始像素风；原文件未修改。
Mystic Woods：grass.png为16×16地块；objects.png取(0,80,48,64)树木区域。技术检查发现部分格子带Premium Version文字，因此不使用那些格子，也不采用受污染骷髅图集。敌人统一使用血怪。
树木阻挡区以树干为中心，外围树木限制地图边界。篝火、路径、粒子和UI为代码绘制。

素材流程：需求（俯视森林、三主角、一怪物）→ 原图检查 → 小样( reports/asset-review.png ) → 接入场景 → 实机截图 → 本地交付。人工审美认可待用户确认。回退可重新从原始ZIP生成assets.js，交付版本固定快照。
Mystic Woods自带read_me.txt明确：仅非商业、允许修改、不允许再分发或转售。当前交付仅供素材持有者本地使用，不代表可公开发布。Tiny RPG包未附可核实的许可文本，商业/公开发行之前需要补齐许可来源。
选择原生Canvas和嵌入PNG：无框架、无需在线CDN、双击可运行。首版以完整战斗闭环为范围，不加入经济经营系统。
