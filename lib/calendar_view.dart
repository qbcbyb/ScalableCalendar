import 'package:date_utils/date_utils.dart';
import 'package:flutter/material.dart';

typedef Widget _SingleBuilder<T>(BuildContext context, T date);
typedef Widget DateBuilder(
    BuildContext context,
    DateTime date,
    bool isSelected,
    bool isToday,
    bool dayOfThisMonth,
    Widget Function(BuildContext context, DateTime date, bool isSelected, bool isToday, bool dayOfThisMonth)
        defaultBuilder);
typedef void DateSelected(DateTime date);

class CalendarView extends StatelessWidget {
  final DateTime initialSelectedDate;
  final DateTime today = DateTime.now();
  final double minRowHeight;
  final DateBuilder dateBuilder;
  final DateSelected dateSelected;
  final List<String> _weekdays;
  final DateTime _firstDayOfMonthView;
  final DateTime _firstDayOfMonth;
  final DateTime _lastDayOfMonth;
  final DateTime _firstDayOfWeek;

  CalendarView(
      {Key key,
      @required this.initialSelectedDate,
      @required this.minRowHeight,
      @required this.dateSelected,
      this.dateBuilder})
      : assert(initialSelectedDate != null),
        assert(minRowHeight != null),
        assert(dateSelected != null),
        _weekdays = Utils.weekdays,
        _firstDayOfMonth = Utils.firstDayOfMonth(initialSelectedDate),
        _lastDayOfMonth = Utils.lastDayOfMonth(initialSelectedDate),
        _firstDayOfMonthView = Utils.firstDayOfWeek(Utils.firstDayOfMonth(initialSelectedDate)),
        _firstDayOfWeek = Utils.firstDayOfWeek(initialSelectedDate),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int selectedWeekIndex = (_firstDayOfWeek.difference(_firstDayOfMonthView).inDays / 7).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: List<Widget>.generate(7, (i) {
          if (i == 0) {
            return _DateOrDayRow<String>(
              height: minRowHeight,
              dateList: _weekdays,
              dateBuilder: _buildWeekday,
            );
          }
          return buildWeekByIndex(i - 1, selectedWeekIndex, constraints.maxHeight - minRowHeight);
        }),
      );
    });
  }

  Widget _buildWeekday(BuildContext context, String weekday) => Center(
        child: Text(weekday),
      );

  Widget buildWeekByIndex(int weekIndex, int selectedWeekIndex, double maxHeight) {
    final dateList = List<DateTime>.generate(7, (j) => _firstDayOfMonthView.add(Duration(days: j + (weekIndex) * 7)));
    final hasDateSelected = dateList[0] == _firstDayOfWeek;

    double minHeight = minRowHeight;

    int realIndexExcludeSelectedInLayout = weekIndex;
    if (!hasDateSelected) {
      if (realIndexExcludeSelectedInLayout < selectedWeekIndex) {
        realIndexExcludeSelectedInLayout++;
      }
      double top = minHeight * realIndexExcludeSelectedInLayout;
      double leftHeight = maxHeight - top;
      if (leftHeight < 0) {
        return Container();
      } else if (leftHeight < minHeight) {
        minHeight = leftHeight;
      }
    }
    return _DateOrDayRow<DateTime>(
      height: minHeight,
      dateList: dateList,
      dateBuilder: _parseAndBuildDate,
    );
  }

  Widget _parseAndBuildDate(BuildContext context, DateTime date) {
    bool isToday = Utils.isSameDay(date, today);
    bool isSelected = Utils.isSameDay(date, initialSelectedDate);
    bool dayOfThisMonth = (date.isAfter(_firstDayOfMonth) || Utils.isSameDay(date, _firstDayOfMonth)) &&
        (date.isBefore(_lastDayOfMonth) || Utils.isSameDay(date, _lastDayOfMonth));
    return dateBuilder == null
        ? _buildDate(context, date, isSelected, isToday, dayOfThisMonth)
        : dateBuilder(context, date, isSelected, isToday, dayOfThisMonth, _buildDate);
  }

  Widget _buildDate(BuildContext context, DateTime date, bool isSelected, bool isToday, bool dayOfThisMonth) {
    Widget result = Center(
      child: Text(
        date.day.toString(),
        style: TextStyle(
          fontSize: 16,
          color:
              isToday ? (isSelected ? Colors.white : Colors.blue) : (dayOfThisMonth ? Colors.black : Colors.grey[400]),
        ),
      ),
    );
    result = FlatButton(
      onPressed: () {
        dateSelected(date);
      },
      shape: CircleBorder(),
      color: isSelected ? Colors.blue[100] : null,
      child: result,
    );
    // result = InkWell(
    //   customBorder: CircleBorder(),
    //   onTap: () {
    //     dateSelected(date);
    //   },
    //   //   decoration: BoxDecoration(
    //   //     shape: BoxShape.circle,
    //   //     color: isSelected ? Colors.blue[100] : null,
    //   //   ),
    //   child: result,
    // );
    return result;
  }
}

class _DateOrDayRow<T> extends StatelessWidget {
  final double height;
  final List<T> dateList;
  final _SingleBuilder<T> dateBuilder;

  _DateOrDayRow({
    Key key,
    @required this.height,
    @required this.dateList,
    @required this.dateBuilder,
  })  : assert(height != null),
        assert(dateList != null),
        assert(dateBuilder != null),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: dateList
            .map(
              (date) => Expanded(
                child: dateBuilder(context, date),
              ),
            )
            .toList(),
      ),
    );
  }
}
