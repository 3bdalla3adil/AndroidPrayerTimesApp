import{createAudioPlayer,setAudioModeAsync}from"expo-audio";
let player:ReturnType<typeof createAudioPlayer>|null=null;let currentKey="";
export function ayahAudioUrl(surah:number,ayah:number){return"https://everyayah.com/data/Alafasy_128kbps/"+String(surah).padStart(3,"0")+String(ayah).padStart(3,"0")+".mp3"}
export async function playAyah(surah:number,ayah:number,title:string){await setAudioModeAsync({playsInSilentMode:true,shouldPlayInBackground:true,interruptionMode:"doNotMix"});const key=surah+":"+ayah;if(!player)player=createAudioPlayer(null,{downloadFirst:true,updateInterval:500});if(currentKey!==key){player.replace(ayahAudioUrl(surah,ayah));currentKey=key}player.setActiveForLockScreen(true,{title,artist:"Mishary Rashid Alafasy",albumTitle:"Quran Salawat"});player.play()}
export function stopAudio(){player?.pause();player?.setActiveForLockScreen(false);currentKey=""}
export function releaseAudio(){player?.remove();player=null;currentKey=""}
