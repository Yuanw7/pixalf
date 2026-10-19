#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
static JSContext *simulation;
static NSString *lastError;
NSString *simulationCommand(NSDictionary *args){
 NSString *op=args[@"op"];
 if([op isEqual:@"sim_close"]){simulation=nil;return @"{\"closed\":true}";}
 if([op isEqual:@"sim_boot"]){
  NSString *root=args[@"root"];
  if(![root isKindOfClass:NSString.class])return @"{\"error\":\"Missing rules path\"}";
  NSString *source=[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"rules.js"] encoding:NSUTF8StringEncoding error:nil];
  if(!source)return @"{\"error\":\"Missing rules module\"}";
  simulation=[JSContext new];lastError=nil;
  simulation.exceptionHandler=^(JSContext *context,JSValue *exception){lastError=[exception toString];};
  [simulation evaluateScript:source];
 }
 if(!simulation)return @"{\"error\":\"Simulation is not running\"}";
 NSDictionary *payload=args[@"payload"];
 if(![payload isKindOfClass:NSDictionary.class])return @"{\"error\":\"Invalid command\"}";
 NSData *json=[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
 NSString *input=[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
 JSValue *result=[simulation evaluateScript:[NSString stringWithFormat:@"JSON.stringify(window.nativeBridge(%@))",input]];
 if(lastError)return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"error":lastError} options:0 error:nil] encoding:NSUTF8StringEncoding];
 return [result toString]?:@"{\"error\":\"Empty simulation response\"}";
}
