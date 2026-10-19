extends RefCounted
const DEFAULT={"enabled":false,"seconds":600.0}
static func config(level: Dictionary) -> Dictionary:
 var c=DEFAULT.duplicate();c.merge(level.get("extraction",{}),true);return c
static func validate(value: Variant) -> String:
 if not value is Dictionary:return "撤离倒计时设置必须是对象"
 if not value.get("enabled",false) is bool:return "撤离倒计时开关无效"
 var n=value.get("seconds",600.0)
 if not (n is int or n is float) or not is_finite(float(n)) or n<10 or n>3600:return "撤离时长需10–3600秒"
 return ""
static func remaining(level: Dictionary,elapsed: float) -> float:return maxf(0,float(config(level).seconds)-elapsed)
static func text(seconds: float) -> String:
 var n=int(ceil(maxf(0,seconds)));return "%02d:%02d"%[int(n/60),n%60]
