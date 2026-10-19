// Presentation only: original enemy stats, AI, collision and level geometry stay intact.
const dungeonPreviousSprite=sprite;
sprite=function(h,asset){
 if(h.id===selected){dungeonPreviousSprite(h,asset);return;}
 ctx.emit('dungeon_actor',[asset,h.x,h.y-(h.id!==undefined?jumpHeight(h):0),!!h.moving,h.anim||0,h.face||1,h.attack||h.windup||0,h.hp<=0,h.combatFlash||0,h.scale||1]);
};
