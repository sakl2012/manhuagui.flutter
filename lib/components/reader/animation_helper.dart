import 'dart:io';
import 'package:flutter/material.dart';

enum SlideDirection { leftToRight, rightToLeft }

typedef AnimationFinished = void Function(int);

class AnimationHelper {
  AnimationHelper(
      final TickerProviderStateMixin provider, final this.onAnimationFinished) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: provider,
    );
    animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5),
    );

    _posLeftRightFr = tweenLRF.animate(animation);
    _posLeftRightTo = tweenLRT.animate(animation);
    _posRightLeftFr = tweenRLF.animate(animation);
    _posRightLeftTo = tweenRLT.animate(animation);
  }

  void play(final int actionId) {
    _controller.reset();
    _controller.forward().whenComplete(() {
      if (onAnimationFinished == null) return;
      onAnimationFinished(actionId);
    });
  }

  void dispose() {
    _controller.dispose();
  }

  static double circleSize, strokeWidth;

  Widget buildImageWidget(final File file) => file != null
      ? Container(
          child: Image.file(
          file,
          fit: BoxFit.contain,
          // scale: 1.0,
        ))
      : Center(
          child: SizedBox(
            width: circleSize,
            height: circleSize,
            child: CircularProgressIndicator(strokeWidth: strokeWidth),
          ),
        );

  List<Widget> _doGenerateWidgets(
      final File current, final File next, final SlideDirection direction) {
    final from = buildImageWidget(current);
    if (direction == null) return [from];
    final to = buildImageWidget(next);
    return direction == SlideDirection.leftToRight
        ? [
            SlideTransition(position: _posLeftRightFr, child: from),
            SlideTransition(position: _posLeftRightTo, child: to),
          ]
        : [
            SlideTransition(position: _posRightLeftFr, child: from),
            SlideTransition(position: _posRightLeftTo, child: to),
          ];
  }

  List<Widget> makeWidgets({
    @required final File current,
    final File next,
    final SlideDirection direction,
    final Iterable<Widget> append,
  }) {
    final r = _doGenerateWidgets(current, next, direction);
    r.addAll(append);
    return r;
  }

  final AnimationFinished onAnimationFinished;
  CurvedAnimation animation;
  AnimationController _controller;
  Animation<Offset> _posLeftRightFr,
      _posLeftRightTo,
      _posRightLeftFr,
      _posRightLeftTo;

  static final tweenLRF = Tween(
    begin: Offset.zero,
    end: const Offset(-1.0, 0.0),
  );
  static final tweenLRT = Tween(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  );

  static final tweenRLF = Tween(
    begin: Offset.zero,
    end: const Offset(1.0, 0.0),
  );
  static final tweenRLT = Tween(
    begin: const Offset(-1.0, 0.0),
    end: Offset.zero,
  );
}
