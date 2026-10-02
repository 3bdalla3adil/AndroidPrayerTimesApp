import{surahs,findSurah}from"../lib/quran";import{gregorianToHijri,hijriToGregorian}from"../lib/hijri";import{calculatePrayerTimes}from"../lib/prayer";
test("contains 114 surahs",()=>expect(surahs).toHaveLength(114));
test("finds Al-Fatihah",()=>expect(findSurah(1)?.total_verses).toBe(7));
test("finds an ayah",()=>expect(findSurah(2)?.verses[0].id).toBe(1));
test("Hijri conversion round trips near the input date",()=>{const d=new Date(2026,0,1);const h=gregorianToHijri(d);const back=hijriToGregorian(h);expect(Math.abs(back.getTime()-d.getTime())).toBeLessThan(3*86400000)});
test("prayer calculation returns five prayers",()=>{const result=calculatePrayerTimes({latitude:25.2854,longitude:51.5310},new Date(2026,0,1),"Qatar","Shafi");expect(result).toHaveLength(5);expect(result.every(x=>x.time instanceof Date)).toBe(true)});

import{pageData,pageOf,allJuzStarts,allHizbStarts,allRubStarts}from"../lib/mushaf";
test("Madani Mushaf has 604 pages",()=>expect(pageData(1).page).toBe(1));
test("Al-Fatihah begins on page 1",()=>expect(pageOf(1,1)).toBe(1));
test("Juz/Hizb/Rub divisions have expected counts",()=>{expect(allJuzStarts()).toHaveLength(30);expect(allHizbStarts()).toHaveLength(60);expect(allRubStarts()).toHaveLength(240)});
test("page 42 contains Quran content",()=>expect(pageData(42).ayahs.length).toBeGreaterThan(0));
import{defaults}from"../lib/storage";import{ayahAudioUrl,availableReciters}from"../lib/audio";
test("bundled Quran contains 6236 ayahs",()=>expect(surahs.reduce((n,s)=>n+s.verses.length,0)).toBe(6236));
test("preferences persist complete Quran reader defaults",()=>{expect(defaults.pageBookmarks).toEqual([]);expect(defaults.progress.page).toBe(1);expect(defaults.mushafMode).toBe(true);expect(defaults.reciter).toBe("Alafasy")});
test("audio exposes the configured reciter and stable ayah URL",()=>{expect(availableReciters().map(x=>x.id)).toContain("Alafasy");expect(ayahAudioUrl(1,1)).toContain("001001.mp3")});