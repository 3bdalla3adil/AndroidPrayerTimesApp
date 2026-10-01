import {mkdir,writeFile} from "node:fs/promises";import {createWriteStream} from "node:fs";import {pipeline} from "node:stream/promises";import {Readable} from "node:stream";
const url="https://raw.githubusercontent.com/risan/quran-json/master/dist/quran_en.json";
await mkdir(new URL("../data/",import.meta.url),{recursive:true});
const response=await fetch(url);if(!response.ok)throw new Error("Unable to download Quran dataset: "+response.status);
const text=await response.text();JSON.parse(text);await writeFile(new URL("../data/quran.json",import.meta.url),text,"utf8");
console.log("Prepared offline Quran dataset:",text.length,"bytes");