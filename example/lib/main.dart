import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:flutter_swipeble_calendar/flutter_swipeble_calendar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SwipebleCalendar(
          weekDayFromIndex: (i) => const <String>["日", "一", "二", "三", "四", "五", "六"][i],
          eventListView: ListView.builder(
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.access_alarm),
                    Expanded(
                      child: Text("测试日历项$index"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
