import {access,readFile} from "node:fs/promises";import {fileURLToPath} from "node:url";
const path=fileURLToPath(new URL("../data/quran.json",import.meta.url));
await access(path);const text=await readFile(path,"utf8");const data=JSON.parse(text);
if(!Array.isArray(data)||data.length!==114)throw new Error("Bundled Quran dataset must contain exactly 114 surahs.");
const verses=data.reduce((n,s)=>n+(Array.isArray(s.verses)?s.verses.length:0),0);
if(verses!==6236)throw new Error("Bundled Quran dataset must contain 6236 ayahs; found "+verses+".");
console.log("Validated bundled offline Quran dataset:",verses,"ayahs");