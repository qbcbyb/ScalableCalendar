import 'dart:math' as math;
import 'package:date_utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scalable_calendar/calendar_view.dart';

const START_PAGE = 10000;

typedef List<T> EventBuilder<T>(DateTime selectedDate);
typedef Widget EventWidgetBuilder<T>(BuildContext context, T eventData);

const isSameDay = Utils.isSameDay;
const isSameWeek = Utils.isSameWeek;

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
      context.ancestorStateOfType(const TypeMatcher<_ScalableCalendarState>());

  final double minRowHeight;

  final WeekDayFromIndex weekDayFromIndex;
  final DateBuilder dateBuilder;

  final EventBuilder<T> eventBuilder;
  final EventWidgetBuilder<T> eventWidgetBuilder;
  final ValueNotifier<DateTime> selectedDate;
  final Function(BuildContext context) onContextGetted;

  ScalableCalendar({
    Key key,
    this.selectedDate,
    this.minRowHeight = 40.0,
    this.weekDayFromIndex,
    this.dateBuilder,
    this.eventBuilder,
    this.eventWidgetBuilder,
    this.onContextGetted,
  }) : super(key: key);
  DateTime get nowSelectedDate =>
      (selectedDate == null || selectedDate.value == null) ? DateTime.now() : selectedDate.value;
  @override
  _ScalableCalendarState<T> createState() => _ScalableCalendarState<T>();
}

mixin ScalableCalendarState<T> implements State<ScalableCalendar<T>> {
  bool get isInMonthView;
  bool get isVerticalScrolling;
}

class _ScalableCalendarState<T> extends State<ScalableCalendar<T>> with ScalableCalendarState<T> {
  PageController _pageController = PageController(initialPage: START_PAGE, keepPage: false);

  bool isInMonthView = true;
  bool isVerticalScrolling = false;
  _BaseSelectedDateAndPageIndex _baseSelectedDateAndPageIndex;
  _BaseSelectedDateAndPageIndex get selectedDateAndPageIndex => _baseSelectedDateAndPageIndex;
  set selectedDateAndPageIndex(_BaseSelectedDateAndPageIndex value) {
    if (_baseSelectedDateAndPageIndex != value) {
      widget.selectedDate.value = value.date;
      setState(() {
        _baseSelectedDateAndPageIndex = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(START_PAGE, widget.nowSelectedDate);
  }

  DateTime buildLayoutDate(int pageIndex) {
    DateTime selectedDate;
    final initialSelectedDate = selectedDateAndPageIndex.date;

    final pageDiff = pageIndex - selectedDateAndPageIndex.page;
    if (isInMonthView) {
      final newMonth = initialSelectedDate.month + pageDiff;
      final realMonth = ((newMonth + 11) % 12) + 1;
      selectedDate = DateTime(initialSelectedDate.year, newMonth, initialSelectedDate.day);
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
    return Builder(
      builder: (context) {
        if (widget.onContextGetted != null) {
          widget.onContextGetted(context);
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              int pageIndex = _pageController.page.round();
              if (pageIndex != selectedDateAndPageIndex.page) {
                selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(pageIndex, buildLayoutDate(pageIndex));
              }
            }
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            physics: isVerticalScrolling ? NeverScrollableScrollPhysics() : null,
            itemCount: START_PAGE * 2,
            itemBuilder: (context, index) {
              return buildNotificationListener(buildLayoutDate(index));
            },
          ),
        );
      },
    );
  }

  NotificationListener<ScrollNotification> buildNotificationListener(DateTime nowSelectedDate) {
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
      child: buildSnappingContainer(nowSelectedDate),
    );
  }

  Widget buildSnappingContainer(DateTime nowSelectedDate) {
    final headerMaxScrollOffset = widget.minRowHeight * 5;
    final List<T> events = (widget.eventBuilder == null ? [] : widget.eventBuilder(nowSelectedDate)) ?? [];
    return NestedScrollView(
      controller: ScrollController(initialScrollOffset: isInMonthView ? 0 : headerMaxScrollOffset),
      physics: _SnappingScrollPhysics(maxScrollOffset: () => headerMaxScrollOffset),
      headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          child: SliverPersistentHeader(
            pinned: true,
            delegate: _CalendarViewDelegate(
              minHeight: widget.minRowHeight * 2,
              maxHeight: widget.minRowHeight * 7,
              childBuilder: (context) => Container(
                color: Colors.white,
                child: CalendarView(
                  initialSelectedDate: nowSelectedDate,
                  minRowHeight: widget.minRowHeight,
                  weekDayFromIndex: widget.weekDayFromIndex,
                  dateBuilder: widget.dateBuilder,
                  dateSelected: (date) {
                    int pageIndex = selectedDateAndPageIndex.page, pageDiff = 0;
                    final nowSelectedDate = selectedDateAndPageIndex.date;
                    if (Utils.isSameDay(nowSelectedDate, date)) {
                      return;
                    }
                    if (isInMonthView && (nowSelectedDate.year != date.year || nowSelectedDate.month != date.month)) {
                      pageDiff = (date.year - nowSelectedDate.year) * 12 + (date.month - nowSelectedDate.month);
                    }
                    if (pageDiff == 0) {
                      selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(pageIndex, date);
                    } else {
                      pageIndex += pageDiff;
                      _pageController
                          .animateToPage(pageIndex, curve: Curves.easeInOut, duration: Duration(milliseconds: 300))
                          .then((_) {
                        selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(pageIndex, date);
                      });
                    }
                  },
                ),
              ),
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return widget.eventWidgetBuilder == null
                      ? Placeholder()
                      : widget.eventWidgetBuilder(context, events[index]);
                },
                childCount: events.length,
              ),
            ),
          ],
        );
      }),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
    return _SnappingScrollPhysics(parent: buildParent(ancestor), maxScrollOffset: maxScrollOffset);
  }

  Simulation _toMaxScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.max(dragVelocity, minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, maxScrollOffset(), velocity, tolerance: tolerance);
  }

  Simulation _toMinScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.min(dragVelocity, -minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, 0, velocity, tolerance: tolerance);
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double dragVelocity) {
    final Simulation simulation = super.createBallisticSimulation(position, dragVelocity);
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
