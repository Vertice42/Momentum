import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'DrawWave.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

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
  static const platform =
      const MethodChannel('samples.flutter.dev/input_method');
  List<int> wave = new List(1);
  String text = "";
  int wavesize = 0;

  Future<void> _getSoundData(String path) async {
    /*
    PermissionStatus permissionResult =
        await SimplePermissions.requestPermission(
            Permission.WriteExternalStorage);
    if (permissionResult != PermissionStatus.authorized)
      return new Exception('Unauthorized PermissionStatus');*/

    ServicesBinding.instance.defaultBinaryMessenger
        .setMessageHandler('samples.flutter.dev/output', (bigdata) async {
      setState(() {
        this.text = bigdata.lengthInBytes.toString();
        this.wave = bigdata.buffer
            .asInt8List(bigdata.offsetInBytes, bigdata.lengthInBytes);

        wavesize += bigdata.lengthInBytes;

/*
        String data = "";
        for (var item in wave) {
          data += " " + item.toString();
        }
        developer.log('wave [0] ', name: data);
        */
      });
      return bigdata;
    });

    await platform.invokeMethod('getSoundData', [path]);
  }

  Future<void> _next() async {
    await platform.invokeMethod('dataConsumed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          RaisedButton(
              child: Text(text),
              onPressed: () => _getSoundData('/Download/a.mp3')),
          RaisedButton(child: Text("Next"), onPressed: () => _next())
        ]),
        body: Container(
            margin: EdgeInsets.symmetric(vertical: 20.0),
            height: 300.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                CustomPaint(
                    size: Size(10000, 10000),
                    painter: DrawWave(wave, wavesize),
                    child: Container(width: 5000))
              ],
            )));
  }
}
