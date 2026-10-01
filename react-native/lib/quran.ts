import data from "../data/quran.json";
export type Ayah={id:number;text:string;translation:string};
export type Surah={id:number;name:string;transliteration:string;translation:string;type:"meccan"|"medinan";total_verses:number;verses:Ayah[]};
export const surahs=data as Surah[];
export function findSurah(id:number){return surahs.find(s=>s.id===id)}
export function findAyah(surah:number,ayah:number){return findSurah(surah)?.verses.find(v=>v.id===ayah)}
export function searchQuran(query:string){const q=query.trim().toLowerCase();if(!q)return[];return surahs.flatMap(s=>s.verses.filter(v=>v.text.includes(query)||v.translation.toLowerCase().includes(q)).slice(0,20).map(v=>({surah:s,ayah:v})))} 