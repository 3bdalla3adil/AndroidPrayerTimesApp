import AsyncStorage from "@react-native-async-storage/async-storage";
export type Preferences={progress:{surah:number;ayah:number};bookmarks:string[];fontSize:number;calculationMethod:"Qatar"|"MuslimWorldLeague"|"Egyptian"|"UmmAlQura";remindersEnabled:boolean;location:{latitude:number;longitude:number;label:string}|null};
const KEY="@quran-salawat/preferences-v2";
const defaults:Preferences={progress:{surah:1,ayah:1},bookmarks:[],fontSize:30,calculationMethod:"Qatar",remindersEnabled:false,location:null};
export async function loadPreferences():Promise<Preferences>{try{const raw=await AsyncStorage.getItem(KEY);return raw?{...defaults,...JSON.parse(raw)}:defaults}catch{return defaults}}
export async function savePreferences(value:Preferences){await AsyncStorage.setItem(KEY,JSON.stringify(value));}