import 'package:date_utils/date_utils.dart';
import 'package:flutter/material.dart';

typedef Widget DateBuilder(
    BuildContext context,
    DateTime date,
    bool isSelected,
    bool isToday,
    bool dayOfThisMonth,
    Widget Function(BuildContext context, DateTime date, bool isSelected, bool isToday, bool dayOfThisMonth)
        defaultBuilder);
typedef String WeekDayFromIndex(int dayIndex);
typedef void DateSelected(DateTime date);

String _customLayoutId(int index) {
  return "_customLayoutId$index";
}

const ROW_COUNT_IN_VIEW = 7;

class CalendarView extends StatelessWidget {
  final DateTime initialSelectedDate;
  final DateTime today = DateTime.now();
  final double minRowHeight;
  final DateBuilder dateBuilder;
  final DateSelected dateSelected;
  final WeekDayFromIndex weekDayFromIndex;
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
      this.dateBuilder,
      this.weekDayFromIndex})
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
    int selectedWeekIndex = (_firstDayOfWeek.difference(_firstDayOfMonthView).inDays / 7).round();
    return CustomMultiChildLayout(
      delegate: MultiCalendarTileLayoutDelegate(
        minRowHeight: minRowHeight,
        selectedWeekIndex: selectedWeekIndex,
      ),
      children: buildWidgets(context),
    );
  }

  List<Widget> buildWidgets(BuildContext context) {
    return List<Widget>.generate(ROW_COUNT_IN_VIEW * 7, (i) {
      if (i < 7) {
        return LayoutId(
          id: _customLayoutId(i),
          child: _buildWeekday(context, weekDayFromIndex == null ? _weekdays[i] : weekDayFromIndex(i)),
        );
      }
      return LayoutId(
        id: _customLayoutId(i),
        child: _parseAndBuildDate(context, _firstDayOfMonthView.add(Duration(days: i - 7))),
      );
    });
  }

  Widget _buildWeekday(BuildContext context, String weekday) => Center(
        child: Text(weekday),
      );
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
    return result;
  }
}

class MultiCalendarTileLayoutDelegate extends MultiChildLayoutDelegate {
  final double minRowHeight;
  final int selectedWeekIndex;

  MultiCalendarTileLayoutDelegate({this.minRowHeight, this.selectedWeekIndex});
  @override
  void performLayout(Size size) {
    final double width = size.width, height = size.height;
    final double tileWidth = width / 7, tileHeight = height / 7;
    final hasEnoughHeight = tileHeight > minRowHeight;
    final maxDateTilesHeight = height - (hasEnoughHeight ? tileHeight : minRowHeight);
    double lastBottom = 0;
    for (var i = 0; i < ROW_COUNT_IN_VIEW; i++) {
      double minHeight = hasEnoughHeight ? tileHeight : minRowHeight;
      if (!hasEnoughHeight && i != 0) {
        int weekIndex = i - 1;

        if (weekIndex != selectedWeekIndex) {
          int realIndexExcludeSelectedInLayout = weekIndex;
          if (realIndexExcludeSelectedInLayout < selectedWeekIndex) {
            realIndexExcludeSelectedInLayout++;
          }
          double top = minHeight * realIndexExcludeSelectedInLayout;
          double leftHeight = maxDateTilesHeight - top;
          if (leftHeight < minHeight) {
            minHeight = leftHeight;
          }
        }
      }
      final hasHeight = minHeight > 0;
      for (var j = 0; j < 7; j++) {
        int widgetIndex = (i * 7 + j);
        var layoutId = _customLayoutId(widgetIndex);
        if (hasHeight) {
          layoutChild(layoutId, BoxConstraints.loose(Size(tileWidth, minHeight)));
          positionChild(layoutId, Offset(j * tileWidth, lastBottom));
        } else {
          layoutChild(layoutId, BoxConstraints.loose(Size.zero));
          positionChild(layoutId, Offset.infinite);
        }
      }
      if (hasHeight) {
        lastBottom += minHeight;
      }
    }
  }

  @override
  bool shouldRelayout(MultiCalendarTileLayoutDelegate oldDelegate) {
    return minRowHeight != oldDelegate.minRowHeight || selectedWeekIndex != oldDelegate.selectedWeekIndex;
  }
}
