import 'package:date_utils/date_utils.dart';
import 'package:flutter/material.dart';

typedef Widget WeekDayBuilder(BuildContext context, String weekday);
typedef Widget DefaultDateBuilder(BuildContext context, DateTime date,
    bool isSelected, bool isToday, bool dayOfThisMonth);
typedef Widget DateBuilder(BuildContext context, DateTime date, bool isSelected,
    bool isToday, bool dayOfThisMonth, DefaultDateBuilder defaultBuilder);
typedef String WeekDayFromIndex(int dayIndex);
typedef void DateSelected(DateTime date);

String _customLayoutId(int index) {
  return "_customLayoutId$index";
}

const ROW_COUNT_IN_VIEW = 7;

class CalendarView extends StatelessWidget {
  final DateTime initialSelectedDate;
  final DateTime today = DateTime.now();
  final double minItemHeight;
  final double minItemWidth;
  final WeekDayBuilder weekDayBuilder;
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
      @required DateTime initialSelectedDate,
      double minItemHeight,
      double minItemWidth,
      @required this.dateSelected,
      this.weekDayBuilder,
      this.dateBuilder,
      this.weekDayFromIndex})
      : assert(initialSelectedDate != null),
        initialSelectedDate = DateTime.utc(initialSelectedDate.year,
            initialSelectedDate.month, initialSelectedDate.day, 12),
        minItemHeight = minItemHeight ?? 40,
        minItemWidth = minItemWidth ?? 40,
        assert(dateSelected != null),
        _weekdays = Utils.weekdays,
        _firstDayOfMonth = Utils.firstDayOfMonth(initialSelectedDate),
        _lastDayOfMonth = Utils.lastDayOfMonth(initialSelectedDate),
        _firstDayOfMonthView =
            Utils.firstDayOfWeek(Utils.firstDayOfMonth(initialSelectedDate)),
        _firstDayOfWeek = Utils.firstDayOfWeek(initialSelectedDate),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    int selectedWeekIndex =
        (_firstDayOfWeek.difference(_firstDayOfMonthView).inDays / 7).round();
    int selectedDayIndexInWeek =
        (initialSelectedDate.difference(_firstDayOfWeek).inDays);
    return CustomMultiChildLayout(
      delegate: MultiCalendarTileLayoutDelegate(
        minItemHeight: minItemHeight,
        minItemWidth: minItemWidth,
        selectedWeekIndex: selectedWeekIndex,
        selectedDayIndexInWeek: selectedDayIndexInWeek,
      ),
      children: buildWidgets(context),
    );
  }

  List<Widget> buildWidgets(BuildContext context) {
    return List<Widget>.generate(ROW_COUNT_IN_VIEW * 7, (i) {
      if (i < 7) {
        return LayoutId(
          id: _customLayoutId(i),
          child: _buildWeekday(context,
              weekDayFromIndex == null ? _weekdays[i] : weekDayFromIndex(i)),
        );
      }
      return LayoutId(
        id: _customLayoutId(i),
        child: _parseAndBuildDate(
            context, _firstDayOfMonthView.add(Duration(days: i - 7))),
      );
    });
  }

  Widget _buildWeekday(BuildContext context, String weekday) =>
      weekDayBuilder != null
          ? weekDayBuilder(context, weekday)
          : Center(
              child: Text(
                weekday,
                softWrap: false,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            );
  Widget _parseAndBuildDate(BuildContext context, DateTime date) {
    bool isToday = Utils.isSameDay(date, today);
    bool isSelected = Utils.isSameDay(date, initialSelectedDate);
    bool dayOfThisMonth = (date.isAfter(_firstDayOfMonth) ||
            Utils.isSameDay(date, _firstDayOfMonth)) &&
        (date.isBefore(_lastDayOfMonth) ||
            Utils.isSameDay(date, _lastDayOfMonth));
    return dateBuilder == null
        ? _buildDate(context, date, isSelected, isToday, dayOfThisMonth)
        : dateBuilder(
            context, date, isSelected, isToday, dayOfThisMonth, _buildDate);
  }

  Widget _buildDate(BuildContext context, DateTime date, bool isSelected,
      bool isToday, bool dayOfThisMonth) {
    Widget result = Center(
      child: Text(
        date.day.toString(),
        softWrap: false,
        style: TextStyle(
          fontSize: 16,
          color: isToday
              ? (isSelected ? Colors.white : Colors.blue)
              : (dayOfThisMonth ? Colors.black : Colors.grey[400]),
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
  final double minItemHeight;
  final double minItemWidth;
  final int selectedWeekIndex;
  final int selectedDayIndexInWeek;

  MultiCalendarTileLayoutDelegate({
    this.minItemHeight,
    this.minItemWidth,
    this.selectedWeekIndex,
    this.selectedDayIndexInWeek,
  });
  @override
  void performLayout(Size size) {
    final double width = size.width, height = size.height;
    final double tileWidth = width / 7, tileHeight = height / 7;
    final hasEnoughHeight = tileHeight > minItemHeight;
    final hasEnoughWidth = tileWidth > minItemWidth;
    final selectWeekIndexInView = selectedWeekIndex + 1; //需加上第一行星期
    final widthOfTiles = List.generate(7, (j) {
      if (hasEnoughWidth) return tileWidth;
      double minWidth = minItemWidth;
      if (j != selectedDayIndexInWeek) {
        minWidth = (width - minItemWidth) / 6;
      }
      return minWidth.clamp(0.0, width).toDouble();
    });
    double lastBottom = 0;
    for (var i = 0; i < ROW_COUNT_IN_VIEW; i++) {
      double minHeight = hasEnoughHeight ? tileHeight : minItemHeight;
      if (!hasEnoughHeight) {
        if (i != selectWeekIndexInView) {
          int realIndexExcludeSelectedInLayout = i;
          if (realIndexExcludeSelectedInLayout < selectWeekIndexInView) {
            realIndexExcludeSelectedInLayout++;
          }
          double top = minHeight * realIndexExcludeSelectedInLayout;
          double heightLeft = height - top;
          if (heightLeft < minHeight) {
            minHeight = heightLeft;
          }
        }
      }
      minHeight = minHeight.clamp(0.0, height).toDouble();
      final hasHeight = minHeight > 0;
      double lastLeft = 0;
      for (var j = 0; j < 7; j++) {
        final widgetIndex = (i * 7 + j);
        final minWidth = widthOfTiles[j];
        final layoutId = _customLayoutId(widgetIndex);
        if (hasHeight && minWidth > 0) {
          layoutChild(
              layoutId, BoxConstraints.loose(Size(minWidth, minHeight)));
          positionChild(layoutId, Offset(lastLeft, lastBottom));
          lastLeft += minWidth;
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
    return minItemHeight != oldDelegate.minItemHeight ||
        minItemWidth != oldDelegate.minItemWidth ||
        selectedWeekIndex != oldDelegate.selectedWeekIndex;
  }
}
