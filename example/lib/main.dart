import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:flutter_scalable_calendar/flutter_scalable_calendar.dart';

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
  ValueNotifier<DateTime> selectedDate;
  @override
  void initState() {
    super.initState();
    selectedDate = ValueNotifier<DateTime>(DateTime.now());
  }

  @override
  void dispose() {
    selectedDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:
          //   ValueListenableProvider<DateTime>(
          //     builder: (_) => selectedDate,
          //     child:
          Scaffold(
        appBar: AppBar(
          // title: Consumer<DateTime>(
          //   builder: (context, value, child) => Text("${value.year}年${value.month}月${value.day}日"),
          // ),
          title: ValueListenableBuilder<DateTime>(
            valueListenable: selectedDate,
            builder: (context, value, child) {
              return Text("${value.year}年${value.month}月${value.day}日");
            },
          ),
        ),
        body: ScalableCalendar<DateTimeEvent>(
          selectedDate: selectedDate,
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
      //   ),
    );
  }
}
