from pathlib import Path
import shutil,json
root=Path(__file__).resolve().parents[1];packs=root/'assets/packs'
specs={
'CompleteUI':('Complete_UI_Essential_Pack_Free.7z','UI按钮、槽位、勾选、展开/收起与播放图标；本次使用按钮背景、播放和折叠图标。','不用于地形或角色。仅选择一套Flat样式，避免混用多套UI。'),
'FantasyUI':('FantasyUIfree.zip','木质幻想菜单、龙形血条；候选用于以后角色/首领血条。','本次不混入工坊工具界面；整张图集需定义切片，不能直接当角色或装备。'),
'PixelUI3':('Pixel UI pack 3.zip','像素边框、状态条、进度/选中效果；候选用于装备稀有度框和技能冷却。','偏高饱和/科幻。当前地牢主题暂不混搭，后续限定状态提示。'),
'RavenIcons':('Free - Raven Fantasy Icons.zip','2192个独立16×16图标，同时有32/64倍图。本次用于地图大厅、保存/帮助；武器与装备图标预留给后续装备界面。','图标不是角色动作或可穿戴分层贴图；不同尺寸不能算不同道具。'),
'CyberpunkMelee':('Free-Melee-Weapon-Pixel-Icons-for-Cyberpunk.zip','40个32×32近战武器图标和预览/源文件。本次只用于装备规划预览；后续用于背包、物品定义、拾取。','不是完整挥舞动画；赛博色彩先划为独立装备组。角色持握需锚点/方向/动作帧，不能用图标替代全部动作。'),
'Icons':('Icons.rar','原项目血药、增益和HUD图标，保留既有用途。','无动作帧，不作为敌人或完整角色。'),
'RF_Catacombs_v1.0':('RF_Catacombs_v1.0.zip','地牢地面/墙体/装饰、烛火、地刺帧；本次继续作为房间绘制基底。','地刺帧与专用陷阱包归同类，不重复计为新机关。材质样式作为一致性基准。'),
'Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc':('Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc.zip','士兵和兽人主角动画。本次保持第一位士兵作为工坊角色，未来装备计划以士兵体型为基准。','原角色武器/盾牌已画入帧；未提供裸模和全套分层护甲。自由换装需重新分层/补帧。'),
'Tiny RPG Character Asset Pack 02 v1.01-Free Demon_A&Blood Monster_A':('Tiny RPG Character Asset Pack 02 v1.01-Free Demon_A&Blood Monster_A.zip','恶魔主角与血怪动画；原网页主角/怪物沿用。','不将换色或同一人物改名统计成独立怪物；本次不扩展工坊角色阵容。'),
'TopdownMonstersPart1Free':('Topdown Monsters Part 1 Free.rar','俯视怪物动画，原网页独立敌人与终点守卫。','本次仍不迁移完整战斗系统；不当作装备人物底模。'),
'TrapAndWeapon':('Trap and Weapon.zip','14类独立陷阱/机关资产。本次工坊使用12类：地刺、炸弹、旋转刺阵、锯轮、摆动刺球、伸缩长矛、箭塔、火焰箱、风扇、落石、塌落平台、弹簧。','保留移动平台和碎裂砖为后续。弹簧/风扇属辅助机关。链条、底座、方向帧、发射物不单独计数。Root数字PNG和Rocket Bullet为弹药/武器/特效图，不虚报为独立机关。'),
'mystic_woods_free_2.2':('mystic_woods_free_2.2.zip','森林地形、草木与角色；原网页森林地图沿用。','本次工坊保持地牢地面，不混入树林材质。'),
'pixel_16_woods v2 free':('pixel_16_woods v2 free.zip','16px森林装饰/瓦片，原网页环境辅助。','保持对应像素比例，不用作陷阱动画或装备动作。')}
records=[]
for key,(archive,scope,limits) in specs.items():
 p=packs/key;files=[x for x in p.rglob('*') if x.is_file() and x.name!='README.md' and x.name!='.DS_Store']
 texts=[str(x.relative_to(p)) for x in files if x.suffix.lower() in ['.txt','.pdf']]
 body=f'# {key} · 工坊应用范围\n\n登记：迭代018 / 2026-10-10。原包：`{archive}`。\n\n## 可用于什么\n\n{scope}\n\n## 使用边界\n\n{limits}\n\n## 素材清点\n\n本解压目录{len(files)}个文件，PNG {sum(x.suffix.lower()==".png" for x in files)}张。张数不是角色/陷阱类型数，包含动画帧、预览和分辨率副本。\n\n## 许可与来源记录\n\n保留原文件；此README只说明项目用途，不改变素材许可，也不代表已获得公开再分发授权。'
 body+='包内文本/许可线索：'+('、'.join('`'+x+'`' for x in texts) if texts else '未找到独立许可文本')+'。使用范围为持有者本地原型；对外发行需核对原作者条款。\n'
 (p/'README.md').write_text(body)
 records.append({'pack':key,'archive':archive,'files':len(files),'png':sum(x.suffix.lower()=='.png' for x in files),'scope':scope,'limits':limits})
(root/'docs/assets/018-inventory.json').write_text(json.dumps(records,ensure_ascii=False,indent=2))
# Copy only selected source images needed at runtime; originals stay untouched.
traproot=packs/'TrapAndWeapon/Trap and Weapon'
for name in ['Trap_Spike_Run.png','Suriken.png','SpikeBall.png','Spear.png','Shooter_Arrow_Trap.png','FireBox.png','Fire.png','Fan.png','FallingRock.png','FallingPlatfrom.png','Jumper.png']:
 shutil.copy2(traproot/name,root/'workshop/art/traps'/name)
ui=packs/'CompleteUI/Complete_UI_Essential_Pack_Free/01_Flat_Theme/Sprites'
for name in ['UI_Flat_Button01a_1.png','UI_Flat_Button01a_2.png','UI_Flat_Button01a_3.png','UI_Flat_IconPlay01a.png','UI_Flat_IconDropdown01a.png','UI_Flat_IconCheck01a.png']:
 shutil.copy2(ui/name,root/'workshop/art/ui'/name)
icons=packs/'RavenIcons/Free - Raven Fantasy Icons/Separated Files/32x32'
for id in [8,10,13,16,664,671]:shutil.copy2(icons/f'fb{id}.png',root/'workshop/art/icons'/f'fa{id}.png')
shutil.copy2(packs/'CyberpunkMelee/1 Icons/Icon28_21.png',root/'workshop/art/icons/weapon_plan.png')
print('Registered',len(records),'packs; copied runtime assets.')
