// Rendering command recorder. No browser, DOM engine, HTML, or timers are used.
const noop=()=>{};
const multiply=(m,n)=>[m[0]*n[0]+m[2]*n[1],m[1]*n[0]+m[3]*n[1],m[0]*n[2]+m[2]*n[3],m[1]*n[2]+m[3]*n[3],m[0]*n[4]+m[2]*n[5]+m[4],m[1]*n[4]+m[3]*n[5]+m[5]];
class Recorder {
 constructor(){this.commands=[];this.stack=[];this.state={m:[1,0,0,1,0,0],fillStyle:'#fff',strokeStyle:'#fff',globalAlpha:1,lineWidth:1,font:'12px sans-serif',textAlign:'left',clip:null};this.path=[];}
 reset(){this.commands=[];this.stack=[];this.state.m=[1,0,0,1,0,0];this.state.clip=null;this.state.globalAlpha=1;}
 emit(kind,args,color=null){this.commands.push([kind,this.state.m.slice(),this.state.globalAlpha,color,...args,this.state.clip]);}
 save(){this.stack.push({...this.state,m:this.state.m.slice()});}restore(){if(this.stack.length)this.state=this.stack.pop();}
 translate(x,y){this.state.m=multiply(this.state.m,[1,0,0,1,x,y]);}scale(x,y){this.state.m=multiply(this.state.m,[x,0,0,y,0,0]);}rotate(a){this.state.m=multiply(this.state.m,[Math.cos(a),Math.sin(a),-Math.sin(a),Math.cos(a),0,0]);}
 clearRect(){}fillRect(x,y,w,h){this.emit('rect',[x,y,w,h,true,0],this.fillStyle);}strokeRect(x,y,w,h){this.emit('rect',[x,y,w,h,false,this.lineWidth],this.strokeStyle);}
 beginPath(){this.path=[];}moveTo(x,y){this.path.push([x,y]);}lineTo(x,y){this.path.push([x,y]);}
 rect(x,y,w,h){this.path=[[x,y],[x+w,y],[x+w,y+h],[x,y+h]];this.pendingClip=[x,y,w,h];}
 clip(){this.state.clip=this.pendingClip?{r:this.pendingClip,m:this.state.m.slice()}:null;}
 arc(x,y,r,a,b){this.ellipse(x,y,r,r,0,a,b);}
 ellipse(x,y,rx,ry,rotation,a,b){const span=Math.min(Math.PI*2,b-a),count=Math.max(8,Math.ceil(Math.abs(span)*8));for(let i=0;i<=count;i++){const t=a+span*i/count,dx=Math.cos(t)*rx,dy=Math.sin(t)*ry;this.path.push([x+dx*Math.cos(rotation)-dy*Math.sin(rotation),y+dx*Math.sin(rotation)+dy*Math.cos(rotation)]);}}
 fill(){if(this.path.length>=3)this.emit('poly',[this.path.slice(),true,0],this.fillStyle);}stroke(){if(this.path.length>=2)this.emit('poly',[this.path.slice(),false,this.lineWidth],this.strokeStyle);}
 fillText(text,x,y){this.emit('text',[String(text),x,y,Number((this.font.match(/([\d.]+)px/)||[])[1])||12,this.textAlign],this.fillStyle);}
 createRadialGradient(...parameters){return {gradient:parameters,stops:[],addColorStop(at,color){this.stops.push([at,color]);}};}
 drawImage(image,...p){if(!image)return;let src=[0,0,image.width,image.height],dst;
  if(p.length===2)dst=[...p,image.width,image.height];else if(p.length===4)dst=p;else {src=p.slice(0,4);dst=p.slice(4);}
  this.emit('image',[image.id,src,dst]);
 }
 lpc(h,fall,height,facing,clock){this.emit('lpc',[h.x,h.y,height,fall,h.hp,h.inv,h.moving,h.attack,facing,clock]);}
}
for(const key of ['fillStyle','strokeStyle','globalAlpha','lineWidth','font','textAlign'])Object.defineProperty(Recorder.prototype,key,{get(){return this.state[key]},set(v){this.state[key]=v}});
const records={},listeners={},nodes=new Map();let backgroundSerial=0;
function node(id=''){const c=new Recorder();return {id,width:960,height:600,textContent:'',innerHTML:'',style:{},dataset:{},classList:{add:noop,remove:noop,toggle:noop},setAttribute:noop,focus:noop,getContext:()=>c,context:c,querySelector(){return this},addEventListener(k,f){listeners['canvas:'+k]=f},getBoundingClientRect(){return {left:0,top:0,width:960,height:600}}};}
const document={hidden:false,createElement(){return node('surface'+(++backgroundSerial))},querySelector(s){if(!nodes.has(s))nodes.set(s,node(s));return nodes.get(s)},querySelectorAll(){return []},addEventListener(k,f){listeners[k]=f}};
const window={addEventListener(k,f){listeners[k]=f}};
const localStorage={getItem:k=>records[k]??null,setItem(k,v){records[k]=String(v)}};
const requestAnimationFrame=noop;
