# 新素材完整盘点 / 011
两包原样复制assets/originals；解压TopdownMonstersPart1Free与TrapAndWeapon；机关包内Rocket Bullet.zip也已展开，共{"monsters":13,"trapFiles":227}个文件条目，详见reports/011-audit/inventory.json（尺寸、字节与SHA256）。原图未编辑，无AI生成。

怪物包：Free/00–10共11张独立640×1440表，80×80帧格；Animation name.png明确idle/walk/attack等行；Preview GIF 144帧。已检查11种轮廓接触表monster-identities.png、全表monsters-0.png、animation-rows.png。不是旧主角复用或变色。
接入：00铁甲兽、01枯木守卫、02沼泽巨怪、03骨面斥候、09熔岩炎魔；其余04/05/06/07/08/10保留候选。Idle第0行6帧，Walk第1行8帧，Attack第5行6帧，Death第12行8帧；同一80px帧格，目标110×110、锚点(-55,-88)。行空白检查已执行，不截取空帧。

机关包：总览00 All、All_Rocket、Gun、00–32独立静态件；地刺、投射器、矛、锯轮、带刺球、风扇、弹板、移动/坍落平台、落石、火焰与链节等动画；嵌套包包含162种32×16弹丸与总览。全部尺寸与哈希已登记，选材依据总览和mechanism-strips、selected-traps接触表。
实际接入Spike_B(320×32，10格，使用收回/预警/伸出格)、Suriken(256×32，8格)、Shooter_Arrow_Trap(96×16，6格，发射器/箭分格)、FallingPlatfrom(256×16，8格)、SpikeBall(42×21，2格)。保留其余候选，不宣称全部已接入。

技术检查：011-corridor-live.png、011-lava-live.png；36个内嵌键加载，无运行时下载。旧血怪/游匪/生成火焰怪从运行索引移除，原始源文件与旧交付不删。史莱姆原图保留。新包未附单独许可文本，本次本地原型接入，不据此宣称公开再分发许可。用户美术认可待反馈。
