#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include "gdextension_interface.h"
#include <vector>

// A local-only runtime view attached to the existing Godot window; no browser launch.
@interface ClassicHost : NSObject <WKNavigationDelegate,WKScriptMessageHandler>
@property(strong) NSView *overlay;
@property(strong) WKWebView *web;
@property(weak) NSWindow *window;
@property(strong) NSString *root;
@property(strong) NSString *recordsPath;
@property(strong) NSMutableDictionary *records;
@property(strong) NSTextField *label;
@property(strong) NSString *error;
@property(strong) NSDictionary *gameState;
@property BOOL ready;
- (void)close:(id)sender;
- (NSString*)open:(NSDictionary*)args;
@end
@implementation ClassicHost
- (void)close:(id)sender {
 [self.web stopLoading];[self.web.configuration.userContentController removeScriptMessageHandlerForName:@"classicRecord"];
 self.web.navigationDelegate=nil;[self.overlay removeFromSuperview];self.overlay=nil;self.web=nil;self.ready=NO;self.gameState=nil;
 [self.window makeFirstResponder:self.window.contentView];
}
- (NSString*)open:(NSDictionary*)args {
 if(self.overlay)return @"经典地图已经打开";
 NSWindow *window=(__bridge NSWindow*)(void*)(uintptr_t)[args[@"window"] unsignedLongLongValue];
 NSString *root=args[@"root"],*records=args[@"records"];
 if(!window || ![root isKindOfClass:NSString.class] || ![records isKindOfClass:NSString.class])return @"缺少应用窗口或资源路径";
 NSURL *url=[NSURL fileURLWithPath:[root stringByAppendingPathComponent:@"index.html"]];
 if(![[NSFileManager defaultManager] fileExistsAtPath:url.path])return @"经典地图资源缺失";
 self.window=window;self.root=root;self.recordsPath=records;self.error=@"";self.ready=NO;
 NSData *saved=[NSData dataWithContentsOfFile:records];id decoded=saved?[NSJSONSerialization JSONObjectWithData:saved options:NSJSONReadingMutableContainers error:nil]:nil;
 self.records=[decoded isKindOfClass:NSMutableDictionary.class]?decoded:[NSMutableDictionary dictionary];
 NSView *content=window.contentView;CGFloat uiScale=1.0/window.backingScaleFactor;
 self.overlay=[[NSView alloc] initWithFrame:content.bounds];self.overlay.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;self.overlay.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];self.overlay.wantsLayer=YES;self.overlay.layer.backgroundColor=[NSColor colorWithRed:.09 green:.13 blue:.10 alpha:1].CGColor;
 NSButton *back=[NSButton buttonWithTitle:@"‹ 返回我的地图" target:self action:@selector(close:)];back.font=[NSFont systemFontOfSize:14*uiScale];back.bezelStyle=NSBezelStyleRounded;back.frame=NSMakeRect(12*uiScale,content.bounds.size.height-39*uiScale,145*uiScale,30*uiScale);back.autoresizingMask=NSViewMinYMargin;[self.overlay addSubview:back];
 self.label=[NSTextField labelWithString:@"经典冒险 · 0.8.0    正在载入…"];self.label.font=[NSFont systemFontOfSize:14*uiScale];self.label.frame=NSMakeRect(175*uiScale,content.bounds.size.height-32*uiScale,950*uiScale,22*uiScale);self.label.textColor=NSColor.whiteColor;self.label.autoresizingMask=NSViewMinYMargin|NSViewWidthSizable;[self.overlay addSubview:self.label];
 WKWebViewConfiguration *configuration=[WKWebViewConfiguration new];configuration.websiteDataStore=[WKWebsiteDataStore nonPersistentDataStore];
 [configuration.userContentController addScriptMessageHandler:self name:@"classicRecord"];
 NSData *json=[NSJSONSerialization dataWithJSONObject:self.records options:NSJSONWritingFragmentsAllowed error:nil];NSString *recordJSON=json?[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]:@"{}";
 NSString *script=[NSString stringWithFormat:@"(()=>{const saved=%@;const keys=['thornbound.v2','thornbound.trials.v2'];const get=Storage.prototype.getItem,set=Storage.prototype.setItem;for(const k of keys){if(typeof saved[k]==='string')try{set.call(localStorage,k,saved[k]);}catch(e){}}Storage.prototype.getItem=function(k){return keys.includes(k)?(saved[k]??null):get.call(this,k)};Storage.prototype.setItem=function(k,v){if(keys.includes(k)){saved[k]=String(v);window.webkit.messageHandlers.classicRecord.postMessage({key:k,value:String(v)});}else set.call(this,k,v);};})();",recordJSON];
 [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
 NSString *style=@"document.addEventListener('DOMContentLoaded',()=>{const s=document.createElement('style');s.textContent='header,.intro,footer{display:none!important}body{background:#141e17}main{max-width:none!important;padding:12px!important}.layout{grid-template-columns:minmax(0,1fr) 225px!important;gap:14px!important}aside{display:block!important;max-height:calc(100vh - 24px);overflow:auto}.viewport{width:100%}.arena-bottom{padding:8px}.section-title span{display:none}.section-title{display:block}.hero-name small{float:none;display:block}.overlay h2{margin:4px}.overlay .character-choice{min-height:100px}';document.head.appendChild(s);});";
 [configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:style injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
 self.web=[[WKWebView alloc] initWithFrame:NSMakeRect(0,0,content.bounds.size.width,content.bounds.size.height-44*uiScale) configuration:configuration];self.web.pageZoom=uiScale;self.web.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;self.web.navigationDelegate=self;
 [self.overlay addSubview:self.web];[content addSubview:self.overlay positioned:NSWindowAbove relativeTo:nil];
 [self.web loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:root isDirectory:YES]];[window makeFirstResponder:self.web];return @"";
}
- (void)webView:(WKWebView*)web didFinishNavigation:(WKNavigation*)navigation {
 self.ready=YES;self.label.stringValue=@"经典冒险 · 0.8.0    WASD 移动 · J 攻击 · K 技能 · E 跳跃 · P 暂停";
 [web evaluateJavaScript:@"document.querySelector('#game').focus();typeof gameStatus==='function'?gameStatus():null" completionHandler:^(id value,NSError *error){if([value isKindOfClass:NSDictionary.class])self.gameState=value;}];
}
- (void)webView:(WKWebView*)web didFailNavigation:(WKNavigation*)navigation withError:(NSError*)error {self.error=error.localizedDescription;self.label.stringValue=[@"载入失败：" stringByAppendingString:self.error];}
- (void)webView:(WKWebView*)web didFailProvisionalNavigation:(WKNavigation*)navigation withError:(NSError*)error {[self webView:web didFailNavigation:navigation withError:error];}
- (void)webViewWebContentProcessDidTerminate:(WKWebView*)web {self.error=@"经典地图运行已中断，请返回地图列表后重试";self.label.stringValue=self.error;}
- (void)webView:(WKWebView*)web decidePolicyForNavigationAction:(WKNavigationAction*)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
 NSURL *u=action.request.URL;BOOL local=u.isFileURL && [u.path.stringByStandardizingPath hasPrefix:[self.root.stringByStandardizingPath stringByAppendingString:@"/"]];handler(local?WKNavigationActionPolicyAllow:WKNavigationActionPolicyCancel);
}
- (void)userContentController:(WKUserContentController*)controller didReceiveScriptMessage:(WKScriptMessage*)message {
 if(!message.frameInfo.isMainFrame || ![message.body isKindOfClass:NSDictionary.class])return;
 id key=message.body[@"key"],value=message.body[@"value"];
 if(![@[@"thornbound.v2",@"thornbound.trials.v2"] containsObject:key] || ![value isKindOfClass:NSString.class] || [value length]>16384)return;
 if([[NSFileManager defaultManager] fileExistsAtPath:self.recordsPath]){
  NSData *previous=[NSData dataWithContentsOfFile:self.recordsPath];
  if(previous && ![previous writeToFile:[self.recordsPath stringByAppendingString:@".bak"] options:NSDataWritingAtomic error:nil]){self.label.stringValue=@"记录备份失败，保留上次存档";return;}
 }
 self.records[key]=value;NSData *data=[NSJSONSerialization dataWithJSONObject:self.records options:0 error:nil];
 if(![data writeToFile:self.recordsPath options:NSDataWritingAtomic error:nil])self.label.stringValue=@"本次记录保存失败；游玩仍可继续";
}
@end

extern NSString *simulationCommand(NSDictionary *args);
static ClassicHost *host;
static GDExtensionInterfaceGetProcAddress getProc;
static GDExtensionClassLibraryPtr library;
static uint64_t className=0,parentName=0;
template<typename T> static T api(const char *name){return (T)getProc(name);}
static NSString *stringValue(GDExtensionConstTypePtr value){auto convert=api<GDExtensionInterfaceStringToUtf8Chars>("string_to_utf8_chars");int64_t n=convert(value,nullptr,0);std::vector<char> bytes(n+1);convert(value,bytes.data(),n);return [NSString stringWithUTF8String:bytes.data()];}
static NSString *run(NSString *input){
 NSDictionary *args=[NSJSONSerialization JSONObjectWithData:[input dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
 if(![args isKindOfClass:NSDictionary.class])return @"{\"error\":\"invalid request\"}";
 if([args[@"op"] isKindOfClass:NSString.class] && [args[@"op"] hasPrefix:@"sim_"])return simulationCommand(args);
 if(!host)host=[ClassicHost new];
 NSString *op=args[@"op"],*error=@"";
 if([op isEqual:@"open"])error=[host open:args];
 else if([op isEqual:@"close"])[host close:nil];
 else if([op isEqual:@"inspect"] && host.web){[host.web evaluateJavaScript:@"typeof gameStatus==='function'?gameStatus():null" completionHandler:^(id v,NSError *e){if([v isKindOfClass:NSDictionary.class])host.gameState=v;}];}
 else if(![op isEqual:@"status"])error=@"unknown operation";
 NSDictionary *result=@{@"active":@(host.overlay!=nil),@"ready":@(host.ready),@"error":error.length?error:(host.error?:@""),@"game":host.gameState?:@{}};
 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:result options:0 error:nil] encoding:NSUTF8StringEncoding];
}
static void ptrcall(void*,void*,const GDExtensionConstTypePtr *args,GDExtensionTypePtr out){api<GDExtensionInterfaceStringNewWithUtf8Chars>("string_new_with_utf8_chars")(out,[run(stringValue(args[0])) UTF8String]);}
static void call(void*,void*,const GDExtensionConstVariantPtr *args,GDExtensionInt count,GDExtensionVariantPtr out,GDExtensionCallError *error){
 if(count!=1){error->error=count<1?GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS:GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;return;}
 if(api<GDExtensionInterfaceVariantGetType>("variant_get_type")(args[0])!=GDEXTENSION_VARIANT_TYPE_STRING){error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;error->argument=0;error->expected=GDEXTENSION_VARIANT_TYPE_STRING;return;}
 uint64_t input=0,output=0;
 api<GDExtensionInterfaceGetVariantToTypeConstructor>("get_variant_to_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(&input,(void*)args[0]);
 const void *values[]={&input};ptrcall(nullptr,nullptr,values,&output);
 api<GDExtensionInterfaceGetVariantFromTypeConstructor>("get_variant_from_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(out,&output);
 auto destroy=api<GDExtensionInterfaceVariantGetPtrDestructor>("variant_get_ptr_destructor")(GDEXTENSION_VARIANT_TYPE_STRING);destroy(&input);destroy(&output);error->error=GDEXTENSION_CALL_OK;
}
static GDExtensionObjectPtr create(void*){auto object=api<GDExtensionInterfaceClassdbConstructObject>("classdb_construct_object")(&parentName);api<GDExtensionInterfaceObjectSetInstance>("object_set_instance")(object,&className,calloc(1,1));return object;}
static void release(void*,void *instance){free(instance);}
static void init(void*,GDExtensionInitializationLevel level){
 if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
 auto sn=api<GDExtensionInterfaceStringNameNewWithUtf8Chars>("string_name_new_with_utf8_chars");sn(&className,"ClassicRuntime");sn(&parentName,"RefCounted");
 GDExtensionClassCreationInfo2 info={};info.is_exposed=true;info.create_instance_func=create;info.free_instance_func=release;
 api<GDExtensionInterfaceClassdbRegisterExtensionClass2>("classdb_register_extension_class2")(library,&className,&parentName,&info);
 uint64_t method=0,argname=0,empty=0,hint=0;sn(&method,"run_json");sn(&argname,"request");sn(&empty,"");api<GDExtensionInterfaceStringNewWithUtf8Chars>("string_new_with_utf8_chars")(&hint,"");
 GDExtensionPropertyInfo arg={GDEXTENSION_VARIANT_TYPE_STRING,&argname,&empty,0,&hint,6};GDExtensionPropertyInfo ret=arg;ret.name=&empty;
 GDExtensionClassMethodArgumentMetadata metadata=GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
 GDExtensionClassMethodInfo mi={};mi.name=&method;mi.call_func=call;mi.ptrcall_func=ptrcall;mi.method_flags=GDEXTENSION_METHOD_FLAG_NORMAL;mi.has_return_value=true;mi.return_value_info=&ret;mi.argument_count=1;mi.arguments_info=&arg;mi.arguments_metadata=&metadata;
 api<GDExtensionInterfaceClassdbRegisterExtensionClassMethod>("classdb_register_extension_class_method")(library,&className,&mi);
 auto destroy=api<GDExtensionInterfaceVariantGetPtrDestructor>("variant_get_ptr_destructor");destroy(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&method);destroy(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&argname);destroy(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&empty);destroy(GDEXTENSION_VARIANT_TYPE_STRING)(&hint);
}
static void deinit(void*,GDExtensionInitializationLevel level){if(level==GDEXTENSION_INITIALIZATION_SCENE){if(host)[host close:nil];host=nil;api<GDExtensionInterfaceClassdbUnregisterExtensionClass>("classdb_unregister_extension_class")(library,&className);auto destroy=api<GDExtensionInterfaceVariantGetPtrDestructor>("variant_get_ptr_destructor")(GDEXTENSION_VARIANT_TYPE_STRING_NAME);destroy(&className);destroy(&parentName);}}
extern "C" GDExtensionBool classic_init(GDExtensionInterfaceGetProcAddress proc,GDExtensionClassLibraryPtr lib,GDExtensionInitialization *initialization){getProc=proc;library=lib;initialization->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;initialization->initialize=init;initialization->deinitialize=deinit;return true;}
