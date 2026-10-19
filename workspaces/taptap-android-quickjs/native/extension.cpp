#include "gdextension_interface.h"
#include "simulation.h"
#include <vector>
static GDExtensionInterfaceGetProcAddress getProc;
static GDExtensionClassLibraryPtr library;
static uint64_t className=0,parentName=0;
template<typename T> static T api(const char *name){return (T)getProc(name);}
static std::string stringValue(GDExtensionConstTypePtr value){auto convert=api<GDExtensionInterfaceStringToUtf8Chars>("string_to_utf8_chars");int64_t n=convert(value,nullptr,0);std::vector<char> bytes(n+1);convert(value,bytes.data(),n);return std::string(bytes.data(),n);}
static void ptrcall(void*,void *instance,const GDExtensionConstTypePtr *args,GDExtensionTypePtr out){auto result=static_cast<Simulation*>(instance)->command(stringValue(args[0]));api<GDExtensionInterfaceStringNewWithUtf8Chars>("string_new_with_utf8_chars")(out,result.c_str());}
static void call(void*,void *instance,const GDExtensionConstVariantPtr *args,GDExtensionInt count,GDExtensionVariantPtr out,GDExtensionCallError *error){
 if(count!=1){error->error=count<1?GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS:GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;return;}
 if(api<GDExtensionInterfaceVariantGetType>("variant_get_type")(args[0])!=GDEXTENSION_VARIANT_TYPE_STRING){error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;error->argument=0;error->expected=GDEXTENSION_VARIANT_TYPE_STRING;return;}
 uint64_t input=0,output=0;
 api<GDExtensionInterfaceGetVariantToTypeConstructor>("get_variant_to_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(&input,(void*)args[0]);
 const void *values[]={&input};ptrcall(nullptr,instance,values,&output);
 api<GDExtensionInterfaceGetVariantFromTypeConstructor>("get_variant_from_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(out,&output);
 auto destroy=api<GDExtensionInterfaceVariantGetPtrDestructor>("variant_get_ptr_destructor")(GDEXTENSION_VARIANT_TYPE_STRING);destroy(&input);destroy(&output);error->error=GDEXTENSION_CALL_OK;
}
static GDExtensionObjectPtr create(void*){auto object=api<GDExtensionInterfaceClassdbConstructObject>("classdb_construct_object")(&parentName);api<GDExtensionInterfaceObjectSetInstance>("object_set_instance")(object,&className,new Simulation());return object;}
static void release(void*,void *instance){delete static_cast<Simulation*>(instance);}
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
static void deinit(void*,GDExtensionInitializationLevel level){if(level==GDEXTENSION_INITIALIZATION_SCENE){api<GDExtensionInterfaceClassdbUnregisterExtensionClass>("classdb_unregister_extension_class")(library,&className);auto destroy=api<GDExtensionInterfaceVariantGetPtrDestructor>("variant_get_ptr_destructor")(GDEXTENSION_VARIANT_TYPE_STRING_NAME);destroy(&className);destroy(&parentName);}}
extern "C" GDExtensionBool classic_init(GDExtensionInterfaceGetProcAddress proc,GDExtensionClassLibraryPtr lib,GDExtensionInitialization *initialization){getProc=proc;library=lib;initialization->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;initialization->initialize=init;initialization->deinitialize=deinit;return true;}
