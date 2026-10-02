import{createAudioPlayer,setAudioModeAsync}from"expo-audio";
export type Reciter="Alafasy";
const RECITERS:Record<Reciter,{name:string;baseUrl:string;bitrate:string}>={Alafasy:{name:"Mishary Rashid Alafasy",baseUrl:"https://everyayah.com/data/Alafasy_128kbps/",bitrate:"128 kbps"}};
let player:ReturnType<typeof createAudioPlayer>|null=null;let currentKey="";
export function availableReciters(){return Object.entries(RECITERS).map(([id,v])=>({id:id as Reciter,...v}))}
export function ayahAudioUrl(surah:number,ayah:number,reciter:Reciter="Alafasy"){const r=RECITERS[reciter];return r.baseUrl+String(surah).padStart(3,"0")+String(ayah).padStart(3,"0")+".mp3"}
export async function playAyah(surah:number,ayah:number,title:string,reciter:Reciter="Alafasy"){await setAudioModeAsync({playsInSilentMode:true,shouldPlayInBackground:true,interruptionMode:"doNotMix"});const key=reciter+":"+surah+":"+ayah;if(!player)player=createAudioPlayer(null,{downloadFirst:true,updateInterval:500});if(currentKey!==key){player.replace(ayahAudioUrl(surah,ayah,reciter));currentKey=key}const r=RECITERS[reciter];player.setActiveForLockScreen(true,{title,artist:r.name,albumTitle:"Quran Salawat"});player.play()}
export function stopAudio(){player?.pause();player?.setActiveForLockScreen(false);currentKey=""}
export function releaseAudio(){player?.remove();player=null;currentKey=""}
