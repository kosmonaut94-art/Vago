
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class Wagon {

  int? id;
  String number;
  String type;
  String status;
  String startDate;
  String endDate;
  String place;

  Wagon({
    this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.place
  });

  Map<String, dynamic> toMap(){

    return {
      "id":id,
      "number":number,
      "type":type,
      "status":status,
      "startDate":startDate,
      "endDate":endDate,
      "place":place
    };

  }

}

class DB {

  static Database? _db;

  static Future<Database> get db async{

    if(_db!=null) return _db!;

    _db = await openDatabase(

      join(await getDatabasesPath(),"wagons.db"),

      onCreate:(db,version){

        return db.execute("""

        CREATE TABLE wagons(

        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        type TEXT,
        status TEXT,
        startDate TEXT,
        endDate TEXT,
        place TEXT

        )

        """);

      },

      version:1

    );

    return _db!;

  }

}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner:false,

      home:Home(),

    );

  }

}

class Home extends StatefulWidget {

  @override
  _HomeState createState()=>_HomeState();

}

class _HomeState extends State<Home>{

  List<Wagon> wagons=[];

  TextEditingController search=TextEditingController();

  Future load() async{

    var db = await DB.db;

    var data = await db.query("wagons");

    wagons = data.map((e)=>Wagon(

      id:e["id"] as int,
      number:e["number"] as String,
      type:e["type"] as String,
      status:e["status"] as String,
      startDate:e["startDate"] as String,
      endDate:e["endDate"] as String,
      place:e["place"] as String

    )).toList();

    setState(() {});

  }

  @override
  void initState(){

    load();

    super.initState();

  }

  Color color(String s){

    switch(s){

      case "В ремонте":
        return Colors.orange;

      case "Ожидает запчасти":
        return Colors.red;

      case "На испытаниях":
        return Colors.amber;

      case "Ремонт завершён":
        return Colors.green;

      default:
        return Colors.grey;

    }

  }

  int count(String s){

    return wagons.where((e)=>e.status==s).length;

  }

  addDialog(){

    TextEditingController number=TextEditingController();
    TextEditingController place=TextEditingController();

    String type="Цистерна";
    String status="В ремонте";

    showDialog(

      context: context,

      builder:(c){

        return AlertDialog(

          title:Text("Добавить вагон"),

          content:Column(

            mainAxisSize:MainAxisSize.min,

            children:[

              TextField(controller:number,decoration:InputDecoration(labelText:"номер")),

              DropdownButton(

                value:type,

                items:["Цистерна","Полувагон","Крытый","Платформа"]
                    .map((e)=>DropdownMenuItem(child:Text(e),value:e))
                    .toList(),

                onChanged:(v){type=v!;}

              ),

              DropdownButton(

                value:status,

                items:[

                  "В ремонте",
                  "Ожидает запчасти",
                  "На испытаниях",
                  "Ремонт завершён"

                ]
                    .map((e)=>DropdownMenuItem(child:Text(e),value:e))
                    .toList(),

                onChanged:(v){status=v!;}

              ),

              TextField(controller:place,decoration:InputDecoration(labelText:"депо")),

            ],

          ),

          actions:[

            TextButton(

              onPressed:() async{

                var db = await DB.db;

                await db.insert("wagons",

                  Wagon(

                    number:number.text,
                    type:type,
                    status:status,
                    startDate:DateTime.now().toString(),
                    endDate:"",
                    place:place.text

                  ).toMap()

                );

                Navigator.pop(context);

                load();

              },

              child:Text("сохранить")

            )

          ],

        );

      }

    );

  }

  @override
  Widget build(BuildContext context){

    var filtered = wagons.where(

          (w)=>w.number.contains(search.text)

    ).toList();

    return Scaffold(

      appBar:AppBar(

        title:Text("Учёт вагонов"),

        actions:[

          IconButton(

            icon:Icon(Icons.add),

            onPressed:addDialog

          )

        ],

      ),

      body:Column(

        children:[

          Padding(

            padding:EdgeInsets.all(10),

            child:TextField(

              controller:search,

              onChanged:(v){setState((){});},

              decoration:InputDecoration(

                hintText:"поиск номера",

                prefixIcon:Icon(Icons.search),

                border:OutlineInputBorder()

              ),

            ),

          ),

          Row(

            mainAxisAlignment:MainAxisAlignment.spaceAround,

            children:[

              stat("ремонт",count("В ремонте"),Colors.orange),

              stat("ожидание",count("Ожидает запчасти"),Colors.red),

              stat("испытания",count("На испытаниях"),Colors.amber),

              stat("готово",count("Ремонт завершён"),Colors.green),

            ],

          ),

          Expanded(

            child:ListView.builder(

              itemCount:filtered.length,

              itemBuilder:(c,i){

                var w = filtered[i];

                return Card(

                  child:ListTile(

                    title:Text("№ "+w.number),

                    subtitle:Text(w.type+" | "+w.place),

                    trailing:Container(

                      padding:EdgeInsets.all(6),

                      decoration:BoxDecoration(

                        color:color(w.status),

                        borderRadius:BorderRadius.circular(8)

                      ),

                      child:Text(

                        w.status,

                        style:TextStyle(color:Colors.white),

                      ),

                    ),

                  ),

                );

              }

            )

          )

        ],

      )

    );

  }

  Widget stat(String name,int count,Color c){

    return Container(

      padding:EdgeInsets.all(8),

      decoration:BoxDecoration(

        color:c,

        borderRadius:BorderRadius.circular(10)

      ),

      child:Column(

        children:[

          Text(name,style:TextStyle(color:Colors.white)),

          Text(count.toString(),

            style:TextStyle(

                color:Colors.white,
                fontSize:18,
                fontWeight:FontWeight.bold
            ),

          )

        ],

      ),

    );

  }

}
