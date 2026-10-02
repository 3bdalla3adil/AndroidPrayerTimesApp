import AsyncStorage from "@react-native-async-storage/async-storage";
export type ThemeMode="system"|"light"|"dark"|"sepia";export type Language="ar"|"en";export type Method="Qatar"|"MuslimWorldLeague"|"Egyptian"|"UmmAlQura";export type Location={latitude:number;longitude:number;label:string};
export type Preferences={progress:{surah:number;ayah:number};bookmarks:string[];fontSize:number;calculationMethod:Method;madhab:"Shafi"|"Hanafi";remindersEnabled:boolean;athanEnabled:boolean;preReminderMinutes:number;location:Location|null;theme:ThemeMode;language:Language;showTranslation:boolean;showTransliteration:boolean;mushafMode:boolean};
const KEY="@quran-salawat/preferences-v4";
export const defaults:Preferences={progress:{surah:1,ayah:1},bookmarks:[],fontSize:30,calculationMethod:"Qatar",madhab:"Shafi",remindersEnabled:false,athanEnabled:true,preReminderMinutes:10,location:null,theme:"system",language:"ar",showTranslation:true,showTransliteration:false,mushafMode:true};
export async function loadPreferences():Promise<Preferences>{try{const raw=await AsyncStorage.getItem(KEY);if(!raw)return defaults;const p=JSON.parse(raw);return {...defaults,...p,progress:{...defaults.progress,...p.progress}}}catch{return defaults}}
export async function savePreferences(value:Preferences){await AsyncStorage.setItem(KEY,JSON.stringify(value))}
