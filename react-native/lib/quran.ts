import data from "../data/quran.json";import pagesData from "../data/quran-pages.json";
export type Ayah={id:number;text:string;translation:string};export type Surah={id:number;name:string;transliteration:string;translation:string;type:"meccan"|"medinan";total_verses:number;verses:Ayah[]};export type MushafPage={page:number;juz:number|null;verses:{surah:number;ayah:number}[]};
export const surahs=data as Surah[];export const mushafPages=pagesData as MushafPage[];
export function findSurah(id:number){return surahs.find(s=>s.id===id)}export function findAyah(surah:number,ayah:number){return findSurah(surah)?.verses.find(v=>v.id===ayah)}
export function searchQuran(query:string){const q=query.trim().toLowerCase();if(!q)return[];return surahs.flatMap(s=>s.verses.filter(v=>v.text.includes(query)||v.translation.toLowerCase().includes(q)).slice(0,20).map(v=>({surah:s,ayah:v})))}
export function pageForAyah(surah:number,ayah:number){const i=mushafPages.findIndex(p=>p.verses.some(v=>v.surah===surah&&v.ayah===ayah));return i<0?0:i}
export function pageText(page:number){const p=mushafPages[page];return p?.verses.map(v=>({surah:findSurah(v.surah)!,ayah:findAyah(v.surah,v.ayah)!})).filter(x=>x.surah&&x.ayah)||[]}
export function pageForJuz(juz:number){const i=mushafPages.findIndex(p=>p.juz===juz);return i<0?0:i}
