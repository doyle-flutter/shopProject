import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';



const String USER_INFO_UID = "123";
const String USER_INFO_TYPE = "0";

const String KEY = "";
const String DOC_KEY = "";
const String TABLE_NAME = "Matching";

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
  List data;
  int currentIndex = 0;

  Future fetch() async{


    try{
      var res = await http.get("https://api.airtable.com/v0/$DOC_KEY/$TABLE_NAME?api_key=$KEY");
      final List<dynamic> _result = json.decode(res.body)['records'];
      List<dynamic> _value = _result.map((dynamic e){
        if(e['fields'].isEmpty || e['fields']['Uid'] == USER_INFO_UID) return;
        return e;
      }).toList();
      _value.removeWhere((element) => element == null);
      this.data = _value;
      return;
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
    return;
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
      socket.on("REC_ITEM", (data) => flutterLocalNotificationsPlugin.show(0, "주문이 확인되었습니다", "감사합니다", notificationDetails));
      await fetch();
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("사용자"),
      ),
      body: this.data == null || this.data.isEmpty
        ? Text("Loding...")
        : ListView.builder(
            itemCount: this.data.length,
            itemBuilder: (BuildContext context, int index) => ListTile(
              title: Text(this.data[index]['fields']['Name'].toString()),
              subtitle: Text(this.data[index]['fields']['Info'].toString()),
              trailing: Icon(Icons.arrow_right),
              onTap: () async{
                bool _check = await showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text("주문하시겠습니까?"),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("주문하기"),
                        textColor: Colors.blue,
                        onPressed: () async{
                          try{
                            print("SEND");
                            socket.emit("SEND", this.data[index]['fields']['Uid'].toString());
                            await patch(value: USER_INFO_UID, fieldsKey: this.data[index]['id'].toString());
                            Navigator.of(context).pop(true);
                          }
                          catch(e){
                            print("NULL");
                          }
                        },
                      ),
                      FlatButton(
                        child: Text("취소"),
                        textColor: Colors.grey,
                        onPressed: () => Navigator.of(context). pop(),
                      )
                    ],
                  )
                ) ?? false;
                if(_check) showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => BottomSheet(
                    onClosing: (){},
                    builder: (BuildContext context) => Container(
                      child: Center(
                        child: Text("주문 완료!"),
                      ),
                    ),
                  )
                );
              },
            )
          ),
    );
  }
}
