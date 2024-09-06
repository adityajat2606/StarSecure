import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:home_security/model/push_notification.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
 List<String>? detail = [];
void main() async {
  runApp(MyApp());
}
getNotification() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  detail = await prefs.getStringList("notificationData");
  return detail;

}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        title: 'Home Security',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FirebaseMessaging _messaging;
  late int _totalNotifications;
  PushNotification? _notificationInfo;

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print(
            'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
        final title = message.notification?.title;
        final body = message.notification?.body;
        final data1 = message.data;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        detail = prefs.getStringList("notificationData") ?? [];
        final String notificationData = json.encode({"title":title,"body":body, "data":data1});
        detail!.add(notificationData);
        final data = prefs.setStringList('notificationData', detail!);
        setState(() { detail; });
        print("yopyo $data");
        Map<String, dynamic> info = jsonDecode(notificationData);
        String? url = "";
        if(info["data"] != null){
          url = info["data"]['url'];
        }
        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: url,
          dataBody: message.data['body'],
        );

        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });

        if (_notificationInfo != null) {
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(_notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: _totalNotifications),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.cyan.shade700,
            duration: Duration(seconds: 2),
          );
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    final FirebaseMessaging _messaging = await FirebaseMessaging.instance;
    _messaging.getToken().then((value) {
      print("Token ${value}");
    });

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['url'],
        dataBody: initialMessage.data['body'],
      );

      final title = initialMessage.notification?.title;
      final body = initialMessage.notification?.body;
      final data1 = initialMessage.data;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      detail = prefs.getStringList("notificationData") ?? [];
      final String notificationData = json.encode({"title":title,"body":body, "data":data1});
      detail!.add(notificationData);
      final data = prefs.setStringList('notificationData', detail!);
      setState(() { detail; });
      print("yopyo $data");

      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
        detail = detail;
      });
    }
  }

  @override
  void initState() {
    _totalNotifications = 0;
    registerNotification();
    checkForInitialMessage();


    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {

      final title = _notificationInfo!.title;
      final body = _notificationInfo!.body;
      final data1 = message.data;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      detail = prefs!.getStringList("notificationData");
      final String notificationData = json.encode({"title":title,"body":body, "data":data1});
      detail!.add(notificationData);
      final data = prefs.setStringList('notificationData', detail!);
      setState(() { detail; });
      print(data);

      Map<String, dynamic> info = jsonDecode(notificationData);
      String? url = "";
      if(info["data"] != null){
        url = info["data"]['url'];
      }
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        dataTitle: url,
        dataBody: message.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        detail = detail;
        _totalNotifications++;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? url = "";
    url = _notificationInfo!.dataTitle;
    if (_notificationInfo!.title.toString().toLowerCase() == "raghav" || _notificationInfo!.title.toString().toLowerCase() == "Raghav Sharma")
    {
      url = "https://yt3.googleusercontent.com/ytc/AL5GRJUQGOmeGTYa04xWTfuXXDRle47Zz7EegrJDr5fbog=s176-c-k-c0x00ffffff-no-rj";
    }
    if (_notificationInfo!.title.toString().toLowerCase() == "deepak" || _notificationInfo!.title.toString().toLowerCase() == "deepak tiwari")
    {
      url = "blob:https://teams.microsoft.com/82c61d58-0926-4dd5-ab1d-e208d37de3e6";
    }
    if (_notificationInfo!.title.toString().toLowerCase() == "elon" || _notificationInfo!.title.toString().toLowerCase() == "elon musk")
    {
      url = "https://www.theladders.com/wp-content/uploads/Elon_Musk_Bipolar_Controversy-1490x838.jpg";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Security'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'App for Home Security Project Exhibition 2',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 50.0),
         // NotificationBadge(totalNotifications: _totalNotifications),
          if(_notificationInfo != null)
            CircleAvatar(backgroundImage: NetworkImage(url ?? "",),radius: 100,),
          SizedBox(height: 16.0),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                if(_notificationInfo != null)
                Text(
                  'Name: ${_notificationInfo!.title}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25.0,
                  ),
                ),
                if(_notificationInfo != null)
                Text(
                  '${_notificationInfo!.body}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 100.0),

                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => visitingLogs()));
                  },
                  child: Container(
                    width: 230,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.greenAccent,
                    ),
                    child: Center(child: Text('Visitor History')),
                  ),
                )


              ],
            ),
          )

        ],

      ),
    );
  }
}

class visitingLogs extends StatefulWidget {
  @override
  State<visitingLogs> createState() => _visitingLogsState();
}

class _visitingLogsState extends State<visitingLogs> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Security'),
        brightness: Brightness.dark,
      ),
      body:
          FutureBuilder(
            future: getNotification(),
            builder: (context, notificationSnapshot) {
              if (!notificationSnapshot.hasData) {
                return const Text("Loading");
              }
              else {
                print(detail);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("  Visiter's Log", style: TextStyle(fontSize: 30, color: Colors.redAccent, fontWeight: FontWeight.w800),),
                        GestureDetector(
                          onTap: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            final data = prefs.setStringList('notificationData', []);
                            setState(() { detail = []; });
                          },
                          child: Container(
                            width: 100,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.greenAccent,
                            ),
                            child: Center(child: Text('Clear')),
                          ),
                        )

                      ],
                    ),
                    SizedBox(height: 5,),
                    Expanded(
                      child: ListView.builder(
                        itemCount: detail?.length,
                        prototypeItem: const ListTile(
                          title: Text("No Visitor"),
                        ),
                        itemBuilder: (context, index) {

                          Map<String, dynamic> info = jsonDecode(detail![index]);
                          print(info);
                          String? url = "";
                          if(info["data"] != null){

                            url = info["data"]['url'];
                          }
                          else{url = "https://www.nicepng.com/png/detail/933-9332131_profile-picture-default-png.png";}
                          if (info['title'].toString().toLowerCase() == "raghav" || info['title'].toString().toLowerCase() == "Raghav Sharma")
                            {
                              url = "https://yt3.googleusercontent.com/ytc/AL5GRJUQGOmeGTYa04xWTfuXXDRle47Zz7EegrJDr5fbog=s176-c-k-c0x00ffffff-no-rj";
                            }
                          if (info['title'].toString().toLowerCase() == "deepak" || info['title'].toString().toLowerCase() == "deepak tiwari")
                          {
                            url = "blob:https://teams.microsoft.com/82c61d58-0926-4dd5-ab1d-e208d37de3e6";
                          }
                          if (info['title'].toString().toLowerCase() == "elon" || info['title'].toString().toLowerCase() == "elon musk")
                          {
                            url = "https://www.theladders.com/wp-content/uploads/Elon_Musk_Bipolar_Controversy-1490x838.jpg";
                          }

                          return ListTile(
                            horizontalTitleGap: 25,
                            leading: CircleAvatar(backgroundImage: NetworkImage(url ?? "https://www.nicepng.com/png/detail/933-9332131_profile-picture-default-png.png"),),
                            title: Text(info['title']),
                            subtitle: Text(info['body']),
                            onTap: () {
                              showCustomDialog(context, info['title'], info['body'], url);

                            },

                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          )


    );
  }

// ···
}
void showCustomDialog(BuildContext context, title, body, url) {
  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: Duration(milliseconds: 700),
    pageBuilder: (_, __, ___) {
      return Center(
        child: Container(
          height: 500,
          child: SizedBox.expand
            (child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [CircleAvatar(
                backgroundImage: NetworkImage(url), radius: 150,),
              SizedBox(height: 20,),
              Text(title, style: TextStyle(fontSize: 30), textAlign: TextAlign.center,),
              SizedBox(height: 20,),
              Text(body, style: TextStyle(fontSize: 20),)],
          ),
          ),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      Tween<Offset> tween;
      if (anim.status == AnimationStatus.reverse) {
        tween = Tween(begin: Offset(-1, 0), end: Offset.zero);
      } else {
        tween = Tween(begin: Offset(1, 0), end: Offset.zero);
      }

      return SlideTransition(
        position: tween.animate(anim),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}


class NotificationBadge extends StatelessWidget {
  final int totalNotifications;

  const NotificationBadge({required this.totalNotifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: new BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$totalNotifications',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}