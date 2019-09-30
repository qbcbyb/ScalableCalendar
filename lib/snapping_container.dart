import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SnappingContainer extends StatefulWidget {
  final double minExtent;
  final double maxExtent;
  final Widget resizingView;
  final Widget bottomView;
  final double _minFlingVelocity;
  final bool initialMaxExtent;

  const SnappingContainer({
    Key key,
    @required this.minExtent,
    @required this.maxExtent,
    @required this.resizingView,
    @required this.bottomView,
    double minFlingVelocity,
    bool initialMaxExtent,
  })  : assert(minExtent != null),
        assert(maxExtent != null),
        assert(maxExtent > minExtent),
        assert(resizingView != null),
        assert(bottomView != null),
        _minFlingVelocity = minFlingVelocity ?? 300,
        initialMaxExtent = initialMaxExtent ?? true,
        super(key: key);
  @override
  _SnappingContainerState createState() => _SnappingContainerState();
}

class _SnappingContainerState extends State<SnappingContainer> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Map<Type, GestureRecognizerFactory> _gesturesRecognizer;
  double nowExtent;
  double _viewportDimension;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this)..addListener(_tick);
    _gesturesRecognizer = {
      VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(),
        (instance) {
          instance
            ..onDown = _handleDragDown
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd
            ..onCancel = _handleDragCancel;
        },
      ),
    };
    nowExtent = widget.initialMaxExtent ? widget.maxExtent : widget.minExtent;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraits) {
        _viewportDimension = constraits.maxHeight;
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: _gesturesRecognizer,
          child: Column(
            children: <Widget>[
              Container(
                height: nowExtent,
                child: widget.resizingView,
              ),
              widget.bottomView,
            ],
          ),
        );
      },
    );
  }

  void _handleDragDown(DragDownDetails details) {
    _animationController.reset();
  }

  void _handleDragStart(DragStartDetails details) {
    ScrollStartNotification(
      metrics:
          SnappingScrollPosition(AxisDirection.down, widget.maxExtent, widget.minExtent, nowExtent, _viewportDimension),
      context: context,
    ).dispatch(context);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    updateExtent(nowExtent + details.delta.dy);
  }

  void _handleDragEnd(DragEndDetails details) {
    handleDragFinish(details.primaryVelocity);
  }

  void _handleDragCancel() {
    handleDragFinish(0);
  }

  void updateExtent(double newExtent) {
    if (newExtent != nowExtent && newExtent >= widget.minExtent && newExtent <= widget.maxExtent) {
      ScrollUpdateNotification(
        metrics: SnappingScrollPosition(newExtent > nowExtent ? AxisDirection.down : AxisDirection.up, widget.maxExtent,
            widget.minExtent, newExtent, _viewportDimension),
        context: context,
      ).dispatch(context);
      setState(() {
        nowExtent = newExtent;
      });
    }
  }

  void handleDragFinish(double velocity) {
    var halfScrollExtent = (widget.maxExtent - widget.minExtent) / 2;
    var middleExtent = widget.minExtent + halfScrollExtent;
    if (velocity > halfScrollExtent) {
      animateToMax(velocity);
    } else if (velocity < -halfScrollExtent) {
      animateToMin(velocity);
    } else if (nowExtent > middleExtent && nowExtent < widget.maxExtent) {
      animateToMax(velocity);
    } else if (nowExtent < middleExtent && nowExtent > widget.minExtent) {
      animateToMin(velocity);
    } else {
      ScrollEndNotification(
        metrics: SnappingScrollPosition(
            AxisDirection.down, widget.maxExtent, widget.minExtent, nowExtent, _viewportDimension),
        context: context,
      ).dispatch(context);
    }
  }

  void animateToMax(double velocity) {
    animateTo(math.max(velocity, widget._minFlingVelocity), widget.maxExtent);
  }

  void animateToMin(double velocity) {
    animateTo(math.min(velocity, -widget._minFlingVelocity), widget.minExtent);
  }

  void animateTo(double velocity, double end) {
    var simulation = ScrollSpringSimulation(
      SpringDescription(
        mass: 2,
        stiffness: 200.0,
        damping: 18,
      ),
      nowExtent,
      end,
      velocity,
      tolerance: Tolerance(distance: 0.1, velocity: 0.1, time: 0.1),
    );
    _animationController.animateWith(simulation).whenComplete(_end);
  }

  void _tick() {
    if (!_animationController.isDismissed) {
      updateExtent(_animationController.value);
    }
  }

  void _end() {
    final newExtent = _animationController.value;
    ScrollEndNotification(
      metrics: SnappingScrollPosition(newExtent > nowExtent ? AxisDirection.down : AxisDirection.up, widget.maxExtent,
          widget.minExtent, newExtent, _viewportDimension),
      context: context,
    ).dispatch(context);
  }
}

class SnappingScrollPosition extends ScrollMetrics {
  final AxisDirection axisDirection;
  final double maxScrollExtent;
  final double minScrollExtent;
  final double pixels;
  final double viewportDimension;

  SnappingScrollPosition(
      this.axisDirection, this.maxScrollExtent, this.minScrollExtent, this.pixels, this.viewportDimension);
}
