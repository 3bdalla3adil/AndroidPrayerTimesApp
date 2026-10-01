import{ayahsInPage,getAyahMeta,findPage,getPartRange,getSurahMeta}from"quran-meta/hafs";import{findAyah,findSurah,type Ayah}from"./quran";
export type PartKind="page"|"juz"|"hizb"|"rubAlHizb";
export type PageAyah={surah:number;ayah:number;data:Ayah;meta:any};
export type MushafPage={page:number;ayahs:PageAyah[];juz:number;hizb:number;rub:number;startSurah:number;startAyah:number};
function ayahId(surah:number,ayah:number){let id=0;for(let s=1;s<surah;s++)id+=getSurahMeta(s).ayahCount;return id+ayah}
export function pageOf(surah:number,ayah:number){return findPage(surah,ayah)}
export function metaOf(surah:number,ayah:number){return getAyahMeta(ayahId(surah,ayah))}
export function pageData(page:number):MushafPage{const refs=[...ayahsInPage(page)];const ayahs=refs.map(([surah,ayah])=>({surah,ayah,data:findAyah(surah,ayah)!,meta:getAyahMeta(ayahId(surah,ayah))}));const m=ayahs[0]?.meta;return{page,ayahs,juz:m?.juz??1,hizb:m?.hizbId??1,rub:m?.rubAlHizbId??1,startSurah:ayahs[0]?.surah??1,startAyah:ayahs[0]?.ayah??1}}
export function rangeFor(kind:PartKind,n:number){return getPartRange(kind,n)}
export function partStartPage(kind:PartKind,n:number){const [s,a]=rangeFor(kind,n);return findPage(s,a)}
export function surahStartPage(surah:number){return findPage(surah,1)}
export function allSurahStarts(){return Array.from({length:114},(_,i)=>({id:i+1,name:findSurah(i+1)?.name??"",page:surahStartPage(i+1)}))}
export function allJuzStarts(){return Array.from({length:30},(_,i)=>({id:i+1,page:partStartPage("juz",i+1)}))}
export function allHizbStarts(){return Array.from({length:60},(_,i)=>({id:i+1,page:partStartPage("hizb",i+1)}))}
export function allRubStarts(){return Array.from({length:240},(_,i)=>({id:i+1,page:partStartPage("rubAlHizb",i+1)}))}
