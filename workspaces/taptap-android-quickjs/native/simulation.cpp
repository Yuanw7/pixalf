#include "simulation.h"
#include <stdexcept>
int Simulation::interrupted(JSRuntime *,void *opaque){return std::chrono::steady_clock::now()>static_cast<Simulation*>(opaque)->deadline;}
Simulation::Simulation(){reset();}
Simulation::~Simulation(){if(context)JS_FreeContext(context);if(runtime)JS_FreeRuntime(runtime);}
void Simulation::reset(){
 if(context)JS_FreeContext(context);if(runtime)JS_FreeRuntime(runtime);
 runtime=JS_NewRuntime();context=nullptr;booted=false;
 if(!runtime)throw std::runtime_error("QuickJS allocation failed");
 JS_SetMemoryLimit(runtime,128*1024*1024);JS_SetMaxStackSize(runtime,1024*1024);
 JS_SetInterruptHandler(runtime,interrupted,this);
 context=JS_NewContext(runtime);if(!context)throw std::runtime_error("QuickJS context allocation failed");
}
std::string Simulation::string(JSValueConst v){const char *s=JS_ToCString(context,v);if(!s)return "";std::string result(s);JS_FreeCString(context,s);return result;}
std::string Simulation::error(const std::string &message){
 JSValue obj=JS_NewObject(context);JS_SetPropertyStr(context,obj,"active",JS_FALSE);JS_SetPropertyStr(context,obj,"error",JS_NewString(context,message.c_str()));
 JSValue json=JS_JSONStringify(context,obj,JS_UNDEFINED,JS_UNDEFINED);std::string result=string(json);JS_FreeValue(context,json);JS_FreeValue(context,obj);
 return result.empty()?"{\"error\":\"QuickJS allocation failure\"}":result;
}
std::string Simulation::failure(){JSValue exception=JS_GetException(context);std::string message=string(exception);JS_FreeValue(context,exception);return error(message);}
std::string Simulation::command(const std::string &input){
 deadline=std::chrono::steady_clock::now()+std::chrono::seconds(5);
 if(input.size()>4*1024*1024)return error("Request exceeds 4 MiB");
 JSValue request=JS_ParseJSON(context,input.data(),input.size(),"request.json");
 if(JS_IsException(request)){failure();return error("invalid request");}
 if(!JS_IsObject(request)){JS_FreeValue(context,request);return error("Invalid request");}
 JSValue opValue=JS_GetPropertyStr(context,request,"op");std::string op=string(opValue);JS_FreeValue(context,opValue);
 JSValue payload=JS_GetPropertyStr(context,request,"payload"),sourceValue=JS_GetPropertyStr(context,request,"source");
 bool validSource=JS_IsString(sourceValue),validPayload=JS_IsObject(payload)&&!JS_IsArray(context,payload);
 std::string source=validSource?string(sourceValue):"";
 JSValue encoded=JS_JSONStringify(context,payload,JS_UNDEFINED,JS_UNDEFINED);std::string payloadJSON=string(encoded);
 JS_FreeValue(context,encoded);JS_FreeValue(context,sourceValue);JS_FreeValue(context,payload);JS_FreeValue(context,request);
 if(op=="sim_close"||op=="close"){reset();return "{\"closed\":true,\"active\":false}";}
 if(op!="sim_boot"&&op!="sim_step")return error("Unsupported operation");
 if(!validPayload)return error("Invalid payload");
 if(op=="sim_boot"){
  reset();if(!validSource||source.empty())return error("Missing rules source");
  JSValue evaluated=JS_Eval(context,source.data(),source.size(),"rules.js",JS_EVAL_TYPE_GLOBAL);
  if(JS_IsException(evaluated))return failure();JS_FreeValue(context,evaluated);booted=true;
 }
 if(!booted)return error("Simulation is not running");
 JSValue window=JS_Eval(context,"window",6,"bridge.js",JS_EVAL_TYPE_GLOBAL);
 JSValue bridge=JS_GetPropertyStr(context,window,"nativeBridge");
 JSValue args=JS_ParseJSON(context,payloadJSON.data(),payloadJSON.size(),"payload.json");
 JSValue result=JS_Call(context,bridge,window,1,&args);
 JS_FreeValue(context,args);JS_FreeValue(context,bridge);JS_FreeValue(context,window);
 if(JS_IsException(result))return failure();
 JSValue json=JS_JSONStringify(context,result,JS_UNDEFINED,JS_UNDEFINED);JS_FreeValue(context,result);
 if(JS_IsException(json))return failure();std::string output=string(json);JS_FreeValue(context,json);
 return output.empty()?error("Empty simulation response"):output;
}
