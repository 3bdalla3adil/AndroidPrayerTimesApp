import{access,readFile,writeFile}from"node:fs/promises";import{fileURLToPath}from"node:url";import{ayahsInPage,findJuz,findPage}from"quran-meta/hafs";
const dataPath=fileURLToPath(new URL("../data/quran.json",import.meta.url));const pagesPath=fileURLToPath(new URL("../data/quran-pages.json",import.meta.url));
await access(dataPath);const data=JSON.parse(await readFile(dataPath,"utf8"));if(!Array.isArray(data)||data.length!==114)throw new Error("Bundled Quran dataset must contain exactly 114 surahs.");
const verses=data.reduce((n,s)=>n+(Array.isArray(s.verses)?s.verses.length:0),0);if(verses!==6236)throw new Error("Bundled Quran dataset must contain 6236 ayahs; found "+verses+".");
const pages=Array.from({length:604},(_,i)=>{const page=i+1;const refs=[...ayahsInPage(page)];return{page,juz:refs.length?findJuz(refs[0][0],refs[0][1]):null,verses:refs.map(([surah,ayah])=>({surah,ayah}))}});
await writeFile(pagesPath,JSON.stringify(pages));console.log("Prepared Madinah 604-page Hafs/Uthmani layout:",pages.length,"pages,",verses,"ayahs");
