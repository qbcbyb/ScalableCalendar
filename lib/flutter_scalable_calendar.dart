import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scalable_calendar/calendar_view.dart';

import 'utils.dart';

export 'calendar_view.dart';
export 'utils.dart';

const START_PAGE = 10000;

typedef List<T> EventBuilder<T>(DateTime selectedDate);
typedef Widget EventWidgetBuilder<T>(BuildContext context, T eventData);

class _BaseSelectedDateAndPageIndex {
  final int page;
  final DateTime date;

  _BaseSelectedDateAndPageIndex(this.page, this.date);

  @override
  String toString() {
    return "_BaseSelectedDateAndPageIndex: { page: $page, date: $date }";
  }
}

class ScalableCalendar<T> extends StatefulWidget {
  static ScalableCalendarState of(BuildContext context) =>
      context.findAncestorStateOfType<_ScalableCalendarState>();

  final double minItemHeight;
  final double minItemWidth;
  final EdgeInsetsGeometry paddingOfCalendarView;
  final Decoration decorationOfCalendarView;

  final WeekDayFromIndex weekDayFromIndex;
  final WeekDayBuilder weekDayBuilder;
  final DateBuilder dateBuilder;

  final EventBuilder<T> eventBuilder;
  final EventWidgetBuilder<T> eventWidgetBuilder;
  final ValueNotifier<DateTime> selectedDate;
  final ValueNotifier<bool> isInMonthView;

  final Color defaultColor;
  final Color selectedColor;
  final Color disabledColor;
  final Color weekdayTextColor;
  final Color defaultTextColor;
  final Color selectedTextColor;
  final Color disabledTextColor;
  final Color todayTextColor;
  final Color todaySelectedTextColor;

  ScalableCalendar._({
    Key key,
    this.selectedDate,
    this.minItemHeight,
    this.minItemWidth,
    this.paddingOfCalendarView,
    this.decorationOfCalendarView,
    this.weekDayFromIndex,
    this.weekDayBuilder,
    this.dateBuilder,
    this.eventBuilder,
    this.eventWidgetBuilder,
    this.isInMonthView,
    this.defaultColor,
    this.selectedColor,
    this.disabledColor,
    this.weekdayTextColor,
    this.defaultTextColor,
    this.selectedTextColor,
    this.disabledTextColor,
    this.todayTextColor,
    this.todaySelectedTextColor,
  })  : assert(paddingOfCalendarView == null ||
            paddingOfCalendarView.isNonNegative),
        super(key: key);
  factory ScalableCalendar({
    Key key,
    ValueNotifier<DateTime> selectedDate,
    ValueNotifier<bool> isInMonthView,
    double minItemHeight = 40.0,
    double minItemWidth = 40.0,
    EdgeInsetsGeometry paddingOfCalendarView,
    Color bgColorOfCalendarView,
    Decoration decorationOfCalendarView,
    WeekDayFromIndex weekDayFromIndex,
    WeekDayBuilder weekDayBuilder,
    DateBuilder dateBuilder,
    EventBuilder<T> eventBuilder,
    EventWidgetBuilder<T> eventWidgetBuilder,
    Color defaultColor,
    Color selectedColor,
    Color disabledColor,
    Color weekdayTextColor,
    Color defaultTextColor,
    Color selectedTextColor,
    Color disabledTextColor,
    Color todayTextColor,
    Color todaySelectedTextColor,
  }) {
    DateTime _date;
    _date = selectedDate?.value ?? DateTime.now();
    _date = DateTime.utc(_date.year, _date.month, _date.day, 12);

    selectedDate?.value = _date;

    final _selectedDate = selectedDate ?? ValueNotifier<DateTime>(_date);

    assert(bgColorOfCalendarView == null || decorationOfCalendarView == null);
    if (bgColorOfCalendarView != null) {
      decorationOfCalendarView = BoxDecoration(color: bgColorOfCalendarView);
    }
    return ScalableCalendar._(
      key: key,
      selectedDate: _selectedDate,
      isInMonthView: isInMonthView ?? ValueNotifier(true),
      minItemHeight: minItemHeight,
      minItemWidth: minItemWidth,
      paddingOfCalendarView: paddingOfCalendarView,
      decorationOfCalendarView: decorationOfCalendarView,
      weekDayFromIndex: weekDayFromIndex,
      weekDayBuilder: weekDayBuilder,
      dateBuilder: dateBuilder,
      eventBuilder: eventBuilder,
      eventWidgetBuilder: eventWidgetBuilder,
      defaultColor: defaultColor,
      selectedColor: selectedColor,
      disabledColor: disabledColor,
      weekdayTextColor: weekdayTextColor,
      defaultTextColor: defaultTextColor,
      selectedTextColor: selectedTextColor,
      disabledTextColor: disabledTextColor,
      todayTextColor: todayTextColor,
      todaySelectedTextColor: todaySelectedTextColor,
    );
  }
  DateTime get nowSelectedDate =>
      (selectedDate == null || selectedDate.value == null)
          ? DateTime.now()
          : selectedDate.value;
  @override
  _ScalableCalendarState<T> createState() => _ScalableCalendarState<T>();
}

mixin ScalableCalendarState<T> implements State<ScalableCalendar<T>> {
  bool get isInMonthView;
  bool get isVerticalScrolling;
}

class _ScalableCalendarState<T> extends State<ScalableCalendar<T>>
    with ScalableCalendarState<T> {
  PageController _pageController =
      PageController(initialPage: START_PAGE, keepPage: false);

  bool get isInMonthView => widget.isInMonthView.value;
  set isInMonthView(bool value) {
    widget.isInMonthView.value = value;
  }

  bool isVerticalScrolling = false;
  _BaseSelectedDateAndPageIndex _baseSelectedDateAndPageIndex;
  _BaseSelectedDateAndPageIndex get selectedDateAndPageIndex =>
      _baseSelectedDateAndPageIndex;
  set selectedDateAndPageIndex(_BaseSelectedDateAndPageIndex value) {
    if (_baseSelectedDateAndPageIndex != value) {
      _baseSelectedDateAndPageIndex = value;
      if (widget.selectedDate.value != value.date) {
        widget.selectedDate.value = value.date;
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDateAndPageIndex =
        _BaseSelectedDateAndPageIndex(START_PAGE, widget.nowSelectedDate);
    widget.selectedDate.addListener(onDateChanged);
  }

  @override
  void dispose() {
    widget.selectedDate.removeListener(onDateChanged);
    super.dispose();
  }

  void onDateChanged() {
    if (widget.selectedDate.value != selectedDateAndPageIndex.date) {
      changeToDate(widget.selectedDate.value);
    }
  }

  void changeToDate(DateTime date) {
    int pageIndex = selectedDateAndPageIndex.page, pageDiff = 0;
    final nowSelectedDate = selectedDateAndPageIndex.date;
    if (Utils.isSameDay(nowSelectedDate, date)) {
      return;
    }
    if (isInMonthView &&
        (nowSelectedDate.year != date.year ||
            nowSelectedDate.month != date.month)) {
      pageDiff = (date.year - nowSelectedDate.year) * 12 +
          (date.month - nowSelectedDate.month);
    }
    if (pageDiff == 0) {
      selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(pageIndex, date);
    } else {
      pageIndex += pageDiff;
      _pageController
          .animateToPage(pageIndex,
              curve: Curves.easeInOut, duration: Duration(milliseconds: 300))
          .then((_) {
        selectedDateAndPageIndex =
            _BaseSelectedDateAndPageIndex(pageIndex, date);
      });
    }
  }

  int getPageIndexByDate(DateTime date) {
    final toDate = DateTime.utc(date.year, date.month, date.day, 12);
    final initial = DateTime.utc(
        selectedDateAndPageIndex.date.year,
        selectedDateAndPageIndex.date.month,
        selectedDateAndPageIndex.date.day,
        12);
    if (isInMonthView) {
      return selectedDateAndPageIndex.page +
          (toDate.year - initial.year) * 12 +
          (toDate.month - initial.month);
    } else {
      final days = toDate.difference(initial).inDays;
      final weekOffsetInt = (days / 7);
      final daysOffsetInAWeek = days % 7;
      final minWeekday =
          toDate.weekday > initial.weekday ? initial.weekday : toDate.weekday;
      if (minWeekday + daysOffsetInAWeek > 7) {
        return selectedDateAndPageIndex.page +
            (weekOffsetInt > 0 ? weekOffsetInt.ceil() : weekOffsetInt.floor());
      } else {
        return selectedDateAndPageIndex.page + weekOffsetInt.floor();
      }
    }
  }

  DateTime buildLayoutDate(int pageIndex) {
    DateTime selectedDate;
    final initialSelectedDate = selectedDateAndPageIndex.date;

    final pageDiff = pageIndex - selectedDateAndPageIndex.page;
    if (isInMonthView) {
      final newMonth = initialSelectedDate.month + pageDiff;
      final realMonth = ((newMonth + 11) % 12) + 1;
      selectedDate =
          DateTime(initialSelectedDate.year, newMonth, initialSelectedDate.day);
      while (selectedDate.month != realMonth) {
        selectedDate = selectedDate.subtract(Duration(days: 1));
      }
    } else {
      selectedDate = initialSelectedDate.add(Duration(days: 7 * pageDiff));
    }
    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return buildNotificationListenerAndScrollView();
  }

  Widget buildNotificationListenerAndScrollView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0) {
          return false;
        }
        if (notification is ScrollStartNotification) {
          setState(() {
            isVerticalScrolling = true;
          });
        } else if (notification is ScrollEndNotification) {
          setState(() {
            isInMonthView = notification.metrics.pixels == 0;
            this.isVerticalScrolling = false;
          });
        }
        return false;
      },
      child: buildSnappingContainer(),
    );
  }

  Widget buildSnappingContainer() {
    final headerMaxScrollOffset = widget.minItemHeight * 5;
    final paddingVertical = widget.paddingOfCalendarView?.vertical ?? 0;
    return NestedScrollView(
      controller: ScrollController(
          initialScrollOffset: isInMonthView ? 0 : headerMaxScrollOffset),
      physics:
          _SnappingScrollPhysics(maxScrollOffset: () => headerMaxScrollOffset),
      headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: SliverPersistentHeader(
            pinned: true,
            delegate: _CalendarViewDelegate(
              minHeight: widget.minItemHeight * 2 + paddingVertical,
              maxHeight: widget.minItemHeight * 7 + paddingVertical,
              childBuilder: (context) {
                Widget result = buildNotificationListenerAndPageView();
                if (widget.paddingOfCalendarView != null) {
                  result = Padding(
                    padding: widget.paddingOfCalendarView,
                    child: result,
                  );
                }
                if (widget.decorationOfCalendarView != null) {
                  result = DecoratedBox(
                    decoration: widget.decorationOfCalendarView,
                    child: result,
                  );
                }
                return result;
              },
            ),
          ),
        ),
      ],
      body: Builder(builder: (context) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            ValueListenableBuilder<DateTime>(
              valueListenable: widget.selectedDate,
              builder: (context, value, child) {
                final List<T> events = (widget.eventBuilder == null
                        ? []
                        : widget.eventBuilder(value)) ??
                    [];
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (widget.eventWidgetBuilder == null) {
                        return Placeholder();
                      }
                      return widget.eventWidgetBuilder(context, events[index]);
                    },
                    childCount: events.length,
                  ),
                );
              },
            )
          ],
        );
      }),
    );
  }

  Widget buildNotificationListenerAndPageView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          int pageIndex = _pageController.page.round();
          if (pageIndex != selectedDateAndPageIndex.page) {
            selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(
                pageIndex, buildLayoutDate(pageIndex));
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: isVerticalScrolling ? NeverScrollableScrollPhysics() : null,
        itemCount: START_PAGE * 2,
        itemBuilder: (context, index) {
          return buildCalendarView(buildLayoutDate(index));
        },
      ),
    );
  }

  Widget buildCalendarView(DateTime nowSelectedDate) {
    return CalendarView(
      initialSelectedDate: nowSelectedDate,
      minItemHeight: widget.minItemHeight,
      weekDayFromIndex: widget.weekDayFromIndex,
      weekDayBuilder: widget.weekDayBuilder,
      dateBuilder: widget.dateBuilder,
      dateSelected: changeToDate,
      defaultColor: widget.defaultColor,
      selectedColor: widget.selectedColor,
      disabledColor: widget.disabledColor,
      weekdayTextColor: widget.weekdayTextColor,
      defaultTextColor: widget.defaultTextColor,
      selectedTextColor: widget.selectedTextColor,
      disabledTextColor: widget.disabledTextColor,
      todayTextColor: widget.todayTextColor,
      todaySelectedTextColor: widget.todaySelectedTextColor,
    );
  }
}

class _CalendarViewDelegate extends SliverPersistentHeaderDelegate {
  _CalendarViewDelegate({
    @required this.childBuilder,
    @required this.minHeight,
    @required this.maxHeight,
  }) : super();

  final WidgetBuilder childBuilder;
  final double minHeight;
  final double maxHeight;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: childBuilder(context),
    );
  }

  @override
  bool shouldRebuild(_CalendarViewDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        childBuilder != oldDelegate.childBuilder;
  }

  @override
  String toString() => '_SliverMainContentDelegate';
}

class _SnappingScrollPhysics extends ClampingScrollPhysics {
  _SnappingScrollPhysics({
    ScrollPhysics parent,
    @required this.maxScrollOffset,
  })  : assert(maxScrollOffset != null),
        super(parent: parent);

  final double Function() maxScrollOffset;

  @override
  _SnappingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return _SnappingScrollPhysics(
        parent: buildParent(ancestor), maxScrollOffset: maxScrollOffset);
  }

  Simulation _toMaxScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.max(dragVelocity, minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, maxScrollOffset(), velocity,
        tolerance: tolerance);
  }

  Simulation _toMinScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.min(dragVelocity, -minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, 0, velocity,
        tolerance: tolerance);
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double dragVelocity) {
    final Simulation simulation =
        super.createBallisticSimulation(position, dragVelocity);
    final double offset = position.pixels;
    var maxOffset = maxScrollOffset();

    if (simulation != null) {
      // The drag ended with sufficient velocity to trigger creating a simulation.
      // If the simulation is headed up towards midScrollOffset but will not reach it,
      // then snap it there. Similarly if the simulation is headed down past
      // midScrollOffset but will not reach zero, then snap it to zero.
      final double simulationEnd = simulation.x(double.infinity);
      if (simulationEnd >= maxOffset) return simulation;
      if (dragVelocity > 0.0) {
        return _toMaxScrollOffsetSimulation(offset, dragVelocity);
      }
      if (dragVelocity < 0.0) {
        return _toMinScrollOffsetSimulation(offset, dragVelocity);
      }
    } else {
      // The user ended the drag with little or no velocity. If they
      // didn't leave the offset above midScrollOffset, then
      // snap to midScrollOffset if they're more than halfway there,
      // otherwise snap to zero.
      final double snapThreshold = maxOffset / 2.0;
      if (offset >= snapThreshold && offset < maxOffset) {
        return _toMaxScrollOffsetSimulation(offset, dragVelocity);
      }
      if (offset > 0.0 && offset < snapThreshold) {
        return _toMinScrollOffsetSimulation(offset, dragVelocity);
      }
    }

    return simulation;
  }
}
