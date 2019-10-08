import 'package:flutter/material.dart';

import 'package:flutter_paged_calendar/flutter_paged_calendar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class DateTimeEvent {
  final String title;
  final String description;

  DateTimeEvent(this.title, this.description);
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: PagedCalendar<DateTimeEvent>(
          weekDayFromIndex: (i) => const <String>["日", "一", "二", "三", "四", "五", "六"][i],
          eventBuilder: (date) => isSameDay(date, DateTime.now())
              ? <DateTimeEvent>[
                  DateTimeEvent("测试", "测试"),
                  DateTimeEvent("测试", "测试"),
                  DateTimeEvent("测试", "测试"),
                ]
              : null,
          eventWidgetBuilder: (context, eventData) => ListTile(
            trailing: Icon(Icons.access_alarm),
            title: Text(eventData.title), subtitle: Text(eventData.description),
            // child: Container(
            //   height: 80,
            //   child: Row(
            //     children: <Widget>[
            //       ,
            //       Expanded(
            //         child: Column(
            //           children: <Widget>[
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}
