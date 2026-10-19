"""Bundle the official macOS Godot binary with the local workshop project."""
from pathlib import Path
import argparse, datetime, hashlib, json, plistlib, shutil, subprocess, zipfile
p=argparse.ArgumentParser();p.add_argument('engine',type=Path);args=p.parse_args()
root=Path(__file__).resolve().parents[1]
stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
dest=root/'builds'/('workshop-022-'+stamp);app=dest/'Thornbound Workshop.app'
mac=app/'Contents/MacOS';res=app/'Contents/Resources';mac.mkdir(parents=True);res.mkdir()
shutil.copy2(args.engine/'Contents/MacOS/Godot',mac/'Godot')
shutil.copy2(args.engine/'Contents/Resources/GodotLG.icns',res/'GodotLG.icns')
shutil.copytree(root/'workshop',res/'game',ignore=shutil.ignore_patterns('.DS_Store','editor','shader_cache'))
launcher=mac/'Thornbound';launcher.write_text('#!/bin/sh\nbase=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)\nexec "$base/MacOS/Godot" --path "$base/Resources/game" "$@"\n');launcher.chmod(0o755)
info={'CFBundleName':'Thornbound Workshop','CFBundleDisplayName':'Thornbound Workshop','CFBundleIdentifier':'local.thornbound.workshop.v022','CFBundleExecutable':'Thornbound','CFBundlePackageType':'APPL','CFBundleIconFile':'GodotLG.icns','CFBundleShortVersionString':'0.6.0','CFBundleVersion':'22','NSHighResolutionCapable':True,'LSMinimumSystemVersion':'12.0'}
with (app/'Contents/Info.plist').open('wb') as f:plistlib.dump(info,f)
subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
(dest/'START_HERE.txt').write_text('THORNBOUND 房间工坊 · 022 / 0.6.0\n\n双击 Thornbound Workshop.app，无需另装Godot。\n主界面选择地图开始游戏，或进入工坊编辑。\n搭建完成：保存草稿 → 从第1关试玩 → Esc编辑 → 加入游玩列表 → 主界面选地图 → 开始游戏。\nWASD移动，F开关，R重试，M总览暂停，Esc返回。\n机关选择框可折叠；选择单个机关调整延迟、周期、生效时长。\n搭建房屋 / M：点击房间边缘加号添加；拖动吸附连接，双击编辑内部。已连接房间整组移动，单独移动先解除拼接。\n在「我的地图」选择「经典地宫 · 0.8.0 / 新版角色」或「低语森林 · 0.8.0 / 新版角色」。Godot绘制旧关卡与LPC主角，可在角色衣柜换装；原版机关、碰撞、战斗数值保留，经典布局暂不支持房屋编辑。\n完整操作见 OPERATION_GUIDE.md；角色衣柜可预览与保存装备外观；后续装备方案见 EQUIPMENT_PLAN.md。\n本机maps目录持久保存自建作品；保存草稿不会自动更新已加入的地图。\n官方Godot 4.7.2本地包装，未做公开发行签名/公证。原网页五关战斗未全部移植。\n')
shutil.copy2(root/'docs/WORKSHOP_GUIDE.md',dest/'OPERATION_GUIDE.md')
shutil.copy2(root/'docs/EQUIPMENT_PLAN.md',dest/'EQUIPMENT_PLAN.md')
shutil.copy2(root/'docs/assets/018-materials.md',dest/'MATERIALS.md')
shutil.copytree(root/'workshop/maps',dest/'maps')
shutil.copy2(root/'reports/022-acceptance.md',dest/'TEST_REPORT.md')
shutil.copy2(root/'reports/022-native.png',dest/'CLASSIC_NATIVE.png')
shutil.copy2(root/'reports/022-tests.log',dest/'TEST_LOG.txt')
with zipfile.ZipFile(dest/'source.zip','w',zipfile.ZIP_DEFLATED) as z:
 for base in [root/'workshop',root/'scripts'/'build-workshop.py',root/'README.md',root/'reports'/'022-acceptance.md',root/'reports'/'022-tests.log',root/'reports'/'022-native.png',root/'docs/WORKSHOP_GUIDE.md',root/'docs/EQUIPMENT_PLAN.md',root/'docs/assets',root/'docs/tasks/022-native-classic.md',root/'docs/decisions/022-native-classic.md',root/'scripts/fetch-lpc019.py',root/'scripts/build-classic-runtime.sh',root/'native',root/'scripts/prepare-native-classic.py',root/'scripts/legacy',root/'tests/native-classic022.mjs',root/'tests/native-harness022.mjs',root/'tests/legacy-playthrough022.mjs',root/'reports/022-differential.log',root/'reports/022-playthrough.log']:
  paths=base.rglob('*') if base.is_dir() else [base]
  for f in paths:
   if f.is_file() and '.godot' not in f.parts and f.suffix!='.import':z.write(f,f.relative_to(root))
manifest={'engine':'Godot 4.7.2 official macOS universal','files':{str(f.relative_to(dest)):hashlib.sha256(f.read_bytes()).hexdigest() for f in dest.rglob('*') if f.is_file()}}
(dest/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(dest)
