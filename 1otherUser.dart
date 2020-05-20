import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String KEY = "";
const String DOC_KEY = "";
const String TABLE_NAME = "Matching";

const String USER_INFO_UID = "321";
const String USER_INFO_TYPE = "1";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  IO.Socket socket;

  Future<List> fetch() async{
    try{
      var res = await http.get("https://api.airtable.com/v0/$DOC_KEY/$TABLE_NAME?api_key=$KEY");
      final List<dynamic> _result = json.decode(res.body)['records'];
      List<dynamic> _value = _result.map((dynamic e){
        if(e['fields'].isEmpty || e['fields']['Uid'] != USER_INFO_UID) return ;
        return e;
      }).toList();
      _value.removeWhere((element) => element == null);
      return _value;
    }
    catch(e){
      print("NULL HTTP");
    }
  }

  socketFetch(){
    try{
      socket = IO.io('http://127.0.0.1:8808/',<String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      socket.connect();
    }
    catch(e){
      print("NULL Socket");
    }
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  AndroidNotificationDetails androidNotificationDetails;
  IOSNotificationDetails iosNotificationDetails;
  NotificationDetails notificationDetails;

  AndroidInitializationSettings androidInitializationSettings;
  IOSInitializationSettings iosInitializationSettings;
  InitializationSettings initializationSettings;

  Future onDidReceiveLocalNotification(int id, String title, String body, String payload) async {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Ok'),
                onPressed: () async {
//              Navigator.of(context, rootNavigator: true).pop();
//              await Navigator.push(
//                context,
//                MaterialPageRoute(
//                  builder: (context) => SecondScreen(payload),
//                ),
//              );
                },
              )
            ],
          ),
    );
  }

  Future selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
//    await Navigator.push(
//      context,
//      MaterialPageRoute(builder: (context) => SecondScreen(payload)),
//    );
  }

  @override
  void initState() {

    Future.microtask(() async{
      await socketFetch();
      socket.on("REC", (data) async{
        print("REC data : $data");
        await flutterLocalNotificationsPlugin.show(
          0, "주문이 들어왔어요", "확인해주세요", notificationDetails
        );
        setState(() {});
      });
      // await fetch();
      return;
    }).then((_) async{
      flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

      androidInitializationSettings = new AndroidInitializationSettings('app_icon');
      iosInitializationSettings = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification,);
      initializationSettings = new InitializationSettings(androidInitializationSettings, iosInitializationSettings);

      androidNotificationDetails = new AndroidNotificationDetails("chid", "chname", "chdes",);
      iosNotificationDetails = new IOSNotificationDetails();
      notificationDetails = new NotificationDetails(androidNotificationDetails, iosNotificationDetails);

      flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: selectNotification);
      return;
    });

    super.initState();
  }

  Future patch({@required String value, @required String fieldsKey}) async{
    final Map<String, dynamic> _data = {
      "records": [
        {
          "id": fieldsKey,
          "fields": {
            "Connect" : value
          }
        }
      ]
    };
    var res = await http.patch("https://api.airtable.com/v0/$DOC_KEY/$TABLE_NAME?api_key=$KEY",
        headers: {
          "Content-Type":"application/json",
          // "Authorization" : "Bearer $KEY"
        },
        body: json.encode(_data));
    print(res.body);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("가맹점"),
      ),
      body: FutureBuilder(
        future: fetch(),
        builder: (BuildContext context, AsyncSnapshot<List> snap){
          if(!snap.hasData) return CircularProgressIndicator();
          return snap.data[0]['fields']['Connect'] == null || snap.data[0]['fields']['Connect'].toString() == ""
            ? Center(child: Text("주문이 없습니다"),)
            : ListView.builder(
                itemCount: snap.data.length,
                itemBuilder: (BuildContext context, int index) => ListTile(
                  title: Text("주문자 : ${snap.data[index]['fields']['Connect'].toString()}"),
                  onTap: () async{
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text("전달하였나요?"),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("네"),
                            textColor: Colors.blue,
                            onPressed: () async{
                              await patch(
                                value: null,
                                fieldsKey: snap.data[index]['id'].toString()
                              );
                              socket.emit("SEND_ITEM", "감사합니다");
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                            child: Text("아니오"),
                            textColor: Colors.grey,
                            onPressed: (){
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      )
                    );
                    setState(() {});
                  },
                )
              );
        },
      ),
    );
  }
}
