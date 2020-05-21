import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

const String KEY = "";
const String DOC_KEY = "";
const String TABLE_NAME = "LandingItem";
const String TABLE_TYPE = "Grid view";


void main() => runApp(
  MaterialApp(
    home: SplashPage()
  )
);

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    Timer(Duration(seconds: 2), () => Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => MainPage())
    ));
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("소개 화면"),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  List data = [];
  String offsetId = "";

  Future fetch() async{
    try{
      var res = await http.get("https://api.airtable.com/v0/$DOC_KEY/$TABLE_NAME?api_key=$KEY&view=$TABLE_TYPE");
      final  _result = json.decode(res.body);
      final String _offsetId = _result['offset'];
      final List _value = _result['records'];
      this.offsetId = _offsetId;
      _value.forEach((element) {
        this.data.add(element);
      });
      return;
    }
    catch(e){
      print("NULL HTTP");
    }
  }
  Future nextFetch({@required String offsetId}) async{
    try{
      var res = await http.get("https://api.airtable.com/v0/$DOC_KEY/$TABLE_NAME?api_key=$KEY&view=$TABLE_TYPE&offset=$offsetId");
      final  _result = json.decode(res.body);
      final String _offsetId = _result['offset'];
      final List _value = _result['records'];
      if(this.offsetId == _offsetId){
        return;
      }
      this.offsetId = _offsetId;
      _value.forEach((element) {
        this.data.add(element);
      });
      return;
    }
    catch(e){
      print("NULL HTTP");
    }
  }

  ScrollController controller;
  @override
  void initState() {
    controller = new ScrollController()
    ..addListener(() async{
      if(this.controller.offset >= this.controller.position.maxScrollExtent){
        await this.nextFetch(offsetId: this.offsetId);
        setState(() {});
      }
    });
    Future.microtask(() async{
      await fetch();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: PageView.builder(
                  itemCount: 3,
                  controller: PageController(initialPage: 0,),
                  itemBuilder: (BuildContext context, int index) => Container(
                    color: Colors.red,
                    child: Center(
                      child: Text(index.toString()),
                    ),
                  )
                ),
              ),
              Expanded(
                flex: 7,
                child: this.data.isEmpty
                ? Center(
                    child: Text("Loading..."),
                  )
                : GridView.builder(
                  itemCount: this.data.length,
                  controller: controller,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: (BuildContext context, int index) => GridTile(
                    child: GestureDetector(
                      onTap: (){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => DetailPage(
                              data: this.data[index]['fields']
                            )
                          )
                        );
                      },
                      child: Container(
                        color: Colors.blue,
                        child: Center(
                          child: Text("$index : ${this.data[index]['fields']['item'].toString()}")
                        ),
                      ),
                    ),
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  dynamic data;
  DetailPage({@required this.data});
  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int currentIndex = 0;
  List images = [1,2,3];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['item'].toString(),style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PageView.builder(
                        itemCount: 3,
                        onPageChanged: (int index){
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        itemBuilder: (BuildContext context, int index) => CachedNetworkImage(
                          imageUrl: widget.data['imgs'][0]['url'].toString(),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 10.0,
                        child: Row(
                          children: images.map((e) =>
                          images.indexOf(e) == currentIndex
                            ? Icon(Icons.brightness_1,color: Colors.white,)
                            : Icon(Icons.brightness_1,color: Colors.grey,),).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(widget.data['item'].toString())
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(widget.data['price'].toString())
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: new List.from(widget.data['keyword']).toList().map((e) => Text(e.toString())).toList(),
                        )
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        child: Text(widget.data['des'].toString())
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
