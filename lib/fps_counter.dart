import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Position {
  const Position({this.left, this.right, this.top, this.bottom});

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}

class FpsCounter extends StatefulWidget {
  const FpsCounter({
    super.key,
    required this.child,
    this.backgroundColor = Colors.black54,
    this.smoothing = true,
    this.textSize = 14,
    this.onFrameCallback,
    this.position = const Position(left: 16, top: 16, right: 0, bottom: 0),
  });

  final Widget child;
  final Color backgroundColor;
  final double textSize;
  final Position position;

  /// Callback that fires each frame, returns the current fps. Be careful with this :)
  final Function(double fps)? onFrameCallback;

  /// Averages readings, prevents wild fluctuations in the displayed FPS if set to true
  final bool smoothing;

  @override
  State<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<FpsCounter> {
  OverlayEntry? fpsOverlay;

  late Ticker _ticker;
  final ValueNotifier<double> _fps = ValueNotifier<double>(0.0);
  Duration? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFpsOverlay();
    });
    if (mounted) {
      _ticker = Ticker((Duration duration) {
        _updateFps(duration);
      });
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    fpsOverlay?.remove();
    super.dispose();
  }

  void _updateFps(Duration currentTime) {
    if (_lastFrameTime != null) {
      final deltaTime = currentTime - _lastFrameTime!;
      final deltaSeconds = deltaTime.inMicroseconds / 1000000.0;
      if (deltaSeconds > 0) {
        final fps = 1.0 / deltaSeconds;
        if (widget.smoothing) {
          _fps.value = _fps.value * 0.9 + fps * 0.1;
        } else {
          _fps.value = fps;
        }
        widget.onFrameCallback?.call(_fps.value);
      }
    }
    _lastFrameTime = currentTime;
  }

  Color get color {
    if (_fps.value >= 50) {
      return const Color.fromARGB(255, 114, 255, 119);
    } else if (_fps.value >= 30) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  void _insertFpsOverlay() {
    fpsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: widget.position.left,
        left: widget.position.left,
        right: widget.position.right,
        bottom: widget.position.bottom,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ValueListenableBuilder(
              valueListenable: _fps,
              builder: (context, fps, child) {
                return Text(
                  "${_fps.value.round()} FPS",
                  style: TextStyle(
                    color: color,
                    fontSize: widget.textSize,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(fpsOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
