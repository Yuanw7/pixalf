#!/usr/bin/env python3
"""Build only inside this isolated workspace. Android requires an installed NDK."""
from pathlib import Path
import subprocess,sys,os,platform,json,hashlib
root=Path(__file__).resolve().parents[1]
mode=sys.argv[1] if len(sys.argv)>1 else 'macos'
if mode not in ('macos','android'):raise SystemExit('Usage: build.py macos|android')
vendor=root/'vendor/quickjs-2026-06-04';out=root/'build'/mode;out.mkdir(parents=True,exist_ok=True)
lock=json.loads((root/'vendor/SOURCE.json').read_text())
if hashlib.sha256((root/'vendor/quickjs-2026-06-04.tar.xz').read_bytes()).hexdigest()!=lock['sha256']:raise SystemExit('QuickJS archive hash mismatch')
if mode=='android':
 ndk=os.environ.get('ANDROID_NDK_HOME') or os.environ.get('ANDROID_NDK_ROOT')
 if not ndk:raise SystemExit('Missing Android NDK: set ANDROID_NDK_HOME. No Android build has been produced.')
 host='darwin-x86_64' if platform.system()=='Darwin' else 'linux-x86_64'
 bin=Path(ndk)/'toolchains/llvm/prebuilt'/host/'bin'
 cc=str(bin/'aarch64-linux-android24-clang');cxx=cc+'++'
 flags=['-fPIC'];link=['-shared','-static-libstdc++','-Wl,-z,max-page-size=16384'];target=root/'game/native/libclassic.android.arm64.so'
else:
 cc='clang';cxx='clang++';flags=['-fPIC','-mmacosx-version-min=12.0'];link=['-dynamiclib'];target=root/'game/native/libclassic.dylib'
def run(args):subprocess.run(args,cwd=root,check=True)
objects=[]
for name in ['quickjs','dtoa','libregexp','libunicode','cutils']:
 obj=out/(name+'.o');run([cc,'-O2','-std=gnu11','-D_GNU_SOURCE','-DCONFIG_VERSION="2026-06-04"',*flags,'-iquote',str(vendor),'-c',str(vendor/(name+'.c')),'-o',str(obj)]);objects.append(str(obj))
common=[cxx,'-O2','-std=c++17',*flags,'-iquote',str(vendor),'-I'+str(root/'native'),str(root/'native/simulation.cpp')]
run([*common,str(root/'native/extension.cpp'),*objects,*link,'-o',str(target)])
if mode=='macos':
 run(['codesign','--force','--sign','-',str(target)])
 run([*common,str(root/'native/cli.cpp'),*objects,'-o',str(out/'runtime-cli')])
print('BUILT',target)
