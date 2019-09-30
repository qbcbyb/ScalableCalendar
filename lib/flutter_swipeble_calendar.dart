import 'package:date_utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipeble_calendar/calendar_view.dart';
import 'package:flutter_swipeble_calendar/snapping_container.dart';

const START_PAGE = 10000;

class SwipebleCalendar extends StatefulWidget {
  final DateTime initialSelectedDate;
  final double minRowHeight;

  SwipebleCalendar({Key key, DateTime initialSelectedDate, DateTime initialLayoutDate, this.minRowHeight = 40.0})
      : this.initialSelectedDate = (initialSelectedDate ?? DateTime.now()),
        super(key: key);

  @override
  _SwipebleCalendarState createState() => _SwipebleCalendarState();
}

class _BaseSelectedDateAndPageIndex {
  final int page;
  final DateTime date;

  _BaseSelectedDateAndPageIndex(this.page, this.date);

  @override
  String toString() {
    return "_BaseSelectedDateAndPageIndex: { page: $page, date: $date }";
  }
}

class _SwipebleCalendarState extends State<SwipebleCalendar> {
  PageController _pageController = PageController(initialPage: START_PAGE, keepPage: false);

  bool isInMonthView = true;
  bool isVerticalScrolling = false;
  _BaseSelectedDateAndPageIndex _baseSelectedDateAndPageIndex;
  _BaseSelectedDateAndPageIndex get selectedDateAndPageIndex => _baseSelectedDateAndPageIndex;
  set selectedDateAndPageIndex(_BaseSelectedDateAndPageIndex value) {
    if (_baseSelectedDateAndPageIndex != value) {
      setState(() {
        _baseSelectedDateAndPageIndex = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(START_PAGE, widget.initialSelectedDate);
  }

  DateTime buildLayoutDate(int pageIndex) {
    DateTime selectedDate;
    final initialSelectedDate = selectedDateAndPageIndex.date;

    final pageDiff = pageIndex - selectedDateAndPageIndex.page;
    if (isInMonthView) {
      selectedDate = DateTime(initialSelectedDate.year, initialSelectedDate.month + pageDiff, initialSelectedDate.day);
      while (selectedDate.month - initialSelectedDate.month != pageDiff) {
        selectedDate = selectedDate.subtract(Duration(days: 1));
      }
    } else {
      selectedDate = initialSelectedDate.add(Duration(days: 7 * pageDiff));
    }
    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    // return NotificationListener<ScrollNotification>(
    //   onNotification: (notification) {
    //     if (notification is ScrollEndNotification) {
    //       int pageIndex = _pageController.page.round();
    //       if (pageIndex != selectedDateAndPageIndex.page) {
    //         selectedDateAndPageIndex = _BaseSelectedDateAndPageIndex(pageIndex, buildLayoutDate(pageIndex));
    //       }
    //     }
    //     return false;
    //   },
    //   child: PageView.builder(
    //     controller: _pageController,
    //     physics: isVerticalScrolling ? NeverScrollableScrollPhysics() : null,
    //     itemCount: START_PAGE * 2,
    //     itemBuilder: (context, index) {
    return buildNotificationListener(buildLayoutDate(START_PAGE));
    //   return buildNotificationListener(buildLayoutDate(index));
    //     },
    //   ),
    // );
  }

  NotificationListener<ScrollNotification> buildNotificationListener(DateTime nowSelectedDate) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          setState(() {
            isVerticalScrolling = true;
          });
        } else if (notification is ScrollEndNotification) {
          setState(() {
            isInMonthView = notification.metrics.pixels == notification.metrics.maxScrollExtent;
            this.isVerticalScrolling = false;
          });
        }
        return false;
      },
      child: buildSnappingContainer(nowSelectedDate),
    );
  }

  SnappingContainer buildSnappingContainer(DateTime nowSelectedDate) {
    return SnappingContainer(
      minExtent: 80,
      maxExtent: 280,
      initialMaxExtent: isInMonthView,
      resizingView: CalendarView(
        initialSelectedDate: nowSelectedDate,
        minRowHeight: 40,
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
      bottomView: Container(),
    );
  }
}
