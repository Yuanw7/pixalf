from pathlib import Path
import shutil,zipfile,json,hashlib,datetime
root=Path(__file__).resolve().parents[1]
version=json.loads((root/'package.json').read_text())['version']
dest=root/'builds'/version
# Delivered snapshots are immutable; repeated builds get distinct directories.
if dest.exists():
 stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
 dest=root/'builds'/(version+'-'+stamp)
game=dest/'game';game.mkdir(parents=True)
for f in ['index.html','style.css','index.js','assets.js']:shutil.copy2(root/f,game/f)
(dest/'START_HERE.txt').write_text(f"""荆棘盟约 {version} · 全门洞穿越修复（迭代016）
打开 game/index.html；图片全部内嵌，无运行时下载。也可在项目根目录 npm start 后打开 http://127.0.0.1:5173 。
选择地图与主角，一名随从自动协战。WASD/方向键/点击地面移动，J攻击，K技能，空格冲刺，E跳跃，F按门边按钮，P暂停，M全图。
地牢五关：算术熔岩厅 → 摆锤长廊 → 横向木头人回廊 → 熔火试炼 → 熔岩独木桥。
每关必须主动按门旁按钮（靠近后 F 或点击）：本关通关，贴墙隔板用0.85秒向上收起；走入门内才进入下一关。最终出口同样按按钮再入门结算。算术关先完成全部题目才能启用按钮。
木头人关：左进右出，绿灯前进、红灯站住，穿过四道纵向火带；终点守卫使用原素材怪，抵达后变成3.5秒引信炸弹。红绿灯与火带停止，立即按右墙开关、穿过隔板撤离。爆炸半径150px、80伤害，开门后引信仍继续。
第一关两题，第四关三题；每题3秒，倒计时结束必须落地站在正确数字格，随后停留1.5秒等待地砖复原。
第五关沿24px木梁向左，E跳过三处断口、避开旋转锤；到西侧岸边按出口按钮。木梁外落地会坠入熔岩。
R重试当前关：恢复生命、清敌与增益、重置本关门和机关状态，保留总时间；暂停/结果页Esc返回选择。刷新后从第一关开始。
森林为150秒生存。血药最多+55HP，武力+60%持续18秒，速度+45%持续16秒；24秒刷新。同伴伤害50%。
记录：森林thornbound.v2，五关通关thornbound.trials.v3，旧键保留；仅结果记录，不保存中途进度。HTTP/file记录可能隔离。
验证：十一套Node模型测试，三主角正常属性、普通输入操作全部五个按钮并通关；浏览器证据见源码中的reports/016-acceptance.md。用户体验认可待反馈。
source.zip为源码，BUILD_MANIFEST.json为SHA256校验清单。旧快照保留；回退打开旧包，不删除浏览器记录。
本地非商业素材原型，未确认公开素材再分发许可。
""",encoding='utf-8')
with zipfile.ZipFile(dest/'source.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in root.rglob('*'):
  rel=p.relative_to(root)
  if p.is_file() and rel.parts[0] not in ['.git','.idea','builds'] and '.godot' not in rel.parts and '__pycache__' not in rel.parts and p.name != '.DS_Store':
   z.write(p,rel)
manifest={'version':version,'snapshot':dest.name,'deliveryStatus':'candidate / verify before acceptance','builtAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'platform':'Desktop browser / offline HTML','files':{}}
for p in dest.rglob('*'):
 if p.is_file():manifest['files'][str(p.relative_to(dest))]=hashlib.sha256(p.read_bytes()).hexdigest()
(dest/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(dest)
