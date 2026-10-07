import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../services/storage_service.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key,required this.surahNumber,this.startingAyah=1,this.startingPage});
  final int surahNumber, startingAyah; final int? startingPage;
  @override State<QuranReaderScreen> createState()=>_QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>{
  static const totalPages=604;
  final pc=PageController(); final storage=StorageService(); final cache=<int,Map<String,dynamic>>{};
  int page=1; double fontSize=29,lineSpacing=1.85; bool translation=false,tajweed=false,toolbar=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    final i=jsonDecode(await rootBundle.loadString('assets/quran/page-index.json')) as Map<String,dynamic>;
    final starts=(i['surahStartPages'] as Map?)?.cast<String,dynamic>()??{};
    final saved=await storage.loadQuranFontSize();
    final p=widget.startingPage??(starts[widget.surahNumber.toString()] as num?)?.toInt()??1;
    if(!mounted)return; setState((){page=p.clamp(1,totalPages);fontSize=saved;});
    WidgetsBinding.instance.addPostFrameCallback((_){if(pc.hasClients)pc.jumpToPage(page-1);});
  }
  Future<Map<String,dynamic>> _data(int p)async{
    if(cache[p]!=null)return cache[p]!;
    final d=jsonDecode(await rootBundle.loadString('assets/quran/pages/page-${p.toString().padLeft(3,'0')}.json')) as Map<String,dynamic>;
    cache[p]=d;return d;
  }
  Future<void> _go(int p)async{if(p<1||p>totalPages||!pc.hasClients)return;await pc.animateToPage(p-1,duration:const Duration(milliseconds:250),curve:Curves.easeOut);}
  void _jump(){final c=TextEditingController(text:'${page}');showDialog<void>(context:context,builder:(x)=>AlertDialog(
    title:const Text('الانتقال إلى صفحة'),content:TextField(controller:c,keyboardType:TextInputType.number),
    actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:(){final p=int.tryParse(c.text);Navigator.pop(x);if(p!=null)_go(p);},child:const Text('انتقال'))]));}
  void _settings(){showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(x)=>StatefulBuilder(builder:(x,set)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,4,20,30),child:ListView(shrinkWrap:true,children:[
      const Text('إعدادات القراءة',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
      Text('حجم الخط: ${fontSize.round()}'),Slider(min:22,max:42,value:fontSize,onChanged:(v){set(()=>fontSize=v);setState((){});storage.saveQuranFontSize(v);}),
      Text('تباعد الأسطر: ${lineSpacing.toStringAsFixed(2)}'),Slider(min:1.4,max:2.4,value:lineSpacing,onChanged:(v){set(()=>lineSpacing=v);setState((){});}),
      SwitchListTile(value:translation,onChanged:(v){set(()=>translation=v);setState((){});},title:const Text('عرض الترجمة')),
      SwitchListTile(value:tajweed,onChanged:(v){set(()=>tajweed=v);setState((){});},title:const Text('ألوان التجويد')),
    ]))));
  }
  @override Widget build(BuildContext context){final t=Theme.of(context);return Scaffold(
    appBar:AppBar(leading:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new,size:19)),
      title:Column(children:[const Text('القرآن الكريم',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),Text('صفحة ${page} من ${totalPages}',style:TextStyle(fontSize:11,color:t.colorScheme.onSurfaceVariant))]),centerTitle:true,
      actions:[IconButton(onPressed:_jump,icon:const Icon(Icons.find_in_page_outlined)),IconButton(onPressed:()=>setState(()=>toolbar=!toolbar),icon:Icon(toolbar?Icons.visibility_off_outlined:Icons.visibility_outlined))]),
    body:Column(children:[
      if(toolbar)Row(children:[_Tool(Icons.text_fields,'Aa',_settings),_Tool(Icons.palette_outlined,'تجويد',()=>setState(()=>tajweed=!tajweed),active:tajweed),const Spacer(),IconButton(onPressed:_settings,icon:const Icon(Icons.tune))]),
      Expanded(child:PageView.builder(controller:pc,reverse:true,itemCount:totalPages,onPageChanged:(p)=>setState(()=>page=p+1),itemBuilder:(c,i)=>FutureBuilder<Map<String,dynamic>>(future:_data(i+1),builder:(c,s)=>s.hasData?_Page(page:i+1,data:s.data!,fontSize:fontSize,lineSpacing:lineSpacing,translation:translation,tajweed:tajweed):const Center(child:CircularProgressIndicator())))),
      SafeArea(top:false,child:Row(children:[IconButton(onPressed:page>1?()=>_go(page-1):null,icon:const Icon(Icons.chevron_left)),Expanded(child:Center(child:InkWell(onTap:_jump,child:Text('${page} / ${totalPages}',style:const TextStyle(fontWeight:FontWeight.w800)))),IconButton(onPressed:page<totalPages?()=>_go(page+1):null,icon:const Icon(Icons.chevron_right))]))
    ]));}
      SafeArea(top:false, child: Row(children:[
        IconButton(onPressed:page>1 ? ()=>_go(page-1) : null, icon:const Icon(Icons.chevron_left)),
        Expanded(child:Center(child:InkWell(onTap:_jump,child:Padding(padding:const EdgeInsets.all(8),child:Text('$'+'{page} / $'+'{totalPages}',style:const TextStyle(fontWeight:FontWeight.w800)))))),
        IconButton(onPressed:page<totalPages ? ()=>_go(page+1) : null, icon:const Icon(Icons.chevron_right)),
      ]))

class _Tool extends StatelessWidget{
  const _Tool(this.icon,this.label,this.onTap,{this.active=false});final IconData icon;final String label;final VoidCallback onTap;final bool active;
  @override Widget build(BuildContext c){final col=active?Theme.of(c).colorScheme.primary:Theme.of(c).colorScheme.onSurfaceVariant;return InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.all(8),child:Column(children:[Icon(icon,size:20,color:col),Text(label,style:TextStyle(fontSize:9,color:col))])));}
}

class _Page extends StatelessWidget{
  const _Page({required this.page,required this.data,required this.fontSize,required this.lineSpacing,required this.translation,required this.tajweed});
  final int page;final Map<String,dynamic>data;final double fontSize,lineSpacing;final bool translation,tajweed;
  List<Map<String,dynamic>> get vs=>((data['verses']as List?)??const[]).whereType<Map>().map((v)=>v.cast<String,dynamic>()).toList();
  String txt(Map<String,dynamic>v){final s=((v['words']as List?)??const[]).whereType<Map>().map((w)=>(w['text']??'').toString()).where((x)=>x.isNotEmpty).join(' ');return s.isEmpty?(v['text']??'').toString():s;}
  @override Widget build(BuildContext c){final t=Theme.of(c);final ink=t.brightness==Brightness.dark?const Color(0xFFE8E4D8):const Color(0xFF17231D);final first=vs.isEmpty?1:(vs.first['surah_number']as num?)?.toInt()??1;
    return Container(color:t.colorScheme.surface,padding:const EdgeInsets.all(10),child:Material(color:t.brightness==Brightness.dark?const Color(0xFF121B17):const Color(0xFFFFFDF5),child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,18,20,28),child:Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('الجزء',style:TextStyle(fontSize:10,color:t.colorScheme.onSurfaceVariant)),Text('${page}',style:TextStyle(fontSize:11,color:t.colorScheme.onSurfaceVariant))]),
      const SizedBox(height:10),if(vs.isNotEmpty)Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:10),decoration:BoxDecoration(border:Border.all(color:t.colorScheme.primary.withValues(alpha:.25)),borderRadius:BorderRadius.circular(12)),child:Column(children:[Text(quran.getSurahNameArabic(first),textDirection:TextDirection.rtl,style:TextStyle(fontFamily:'serif',fontSize:23,color:t.colorScheme.primary,fontWeight:FontWeight.w700)),Text(quran.getSurahName(first),style:TextStyle(fontSize:11,color:t.colorScheme.onSurfaceVariant))])),
      const SizedBox(height:14),if(vs.isNotEmpty)Text.rich(TextSpan(children:[for(final v in vs)...[
        TextSpan(text:'${txt(v)} ',style:TextStyle(fontSize:fontSize,height:lineSpacing,color:ink,fontFamily:'serif')),
        WidgetSpan(child:Container(width:29,height:29,margin:const EdgeInsets.symmetric(horizontal:3),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:t.colorScheme.primary.withValues(alpha:.5))),alignment:Alignment.center,child:Text('${v['ayah_number']??''}',style:TextStyle(fontSize:9,color:t.colorScheme.primary)))),
        if(translation)TextSpan(text:'\\n${_translation(v)}\\n',style:TextStyle(fontSize:13,height:1.5,color:t.colorScheme.onSurfaceVariant))
      ]]),textDirection:TextDirection.rtl,textAlign:TextAlign.right) else if(page==604)const _Dua(),
      if(page==604)const _Dua(),if(tajweed)Padding(padding:const EdgeInsets.only(top:12),child:Text('ألوان التجويد تُطبق عند توفر العلامات في البيانات.',style:TextStyle(fontSize:10)))
    ]))); }
  String _translation(Map<String,dynamic>v){try{return quran.getVerseTranslation((v['surah_number']as num).toInt(),(v['ayah_number']as num).toInt());}catch(_){return '';}}
}

class _Dua extends StatelessWidget{
  const _Dua();
  @override Widget build(BuildContext c)=>Container(margin:const EdgeInsets.only(top:24),padding:const EdgeInsets.all(18),decoration:BoxDecoration(border:Border.all(color:Theme.of(c).colorScheme.primary.withValues(alpha:.25)),borderRadius:BorderRadius.circular(14)),child:const Column(children:[
    Text('✦  دُعَاءُ خَتْمِ الْقُرْآنِ  ✦',textDirection:TextDirection.rtl,style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
    SizedBox(height:12),Text('اللهم ارحمني بالقرآن، واجعله لي إماماً ونوراً وهدىً ورحمة. اللهم ذكّرني منه ما نسيت، وعلّمني منه ما جهلت، وارزقني تلاوته آناء الليل وأطراف النهار، واجعله لي حجة يا رب العالمين. اللهم أصلح لي ديني ودنياي وآخرتي، واجعل القرآن ربيع قلبي ونور صدري وجلاء حزني وذهاب همي.',textDirection:TextDirection.rtl,textAlign:TextAlign.right,style:TextStyle(fontSize:18,height:1.8))
  ]));
}
