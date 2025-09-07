import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Issue with properly disposing things during hot restart causing the ticker to fire errors on every frame
// https://github.com/flutter/flutter/issues/69949

class Position {
  const Position({this.left, this.right, this.top, this.bottom});

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}

class FpsCounter extends StatefulWidget {
  /// Run project with [flutter run --dart-define=FPS_COUNTER=true] to enable
  const FpsCounter({
    super.key,
    required this.child,
    this.backgroundColor = Colors.black54,
    this.smoothing = true,
    this.textSize = 14,
    this.onFrameCallback,
    this.position = const Position(
      left: 16,
      top: 16,
      right: null,
      bottom: null,
    ),
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

  Ticker? _ticker;
  final ValueNotifier<double> _fps = ValueNotifier<double>(0.0);
  Duration? _lastFrameTime;

  static const bool _isFpsEnabled = bool.fromEnvironment(
    'FPS_COUNTER',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    if (!_isFpsEnabled) {
      debugPrint('\x1B[33m== FPS COUNTER DISABLED ==\x1B[0m');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFpsOverlay();
    });
    _ticker = Ticker((Duration duration) {
      _updateFps(duration);
    });
    _ticker?.start();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _ticker?.stop();
    _ticker?.dispose();
    fpsOverlay?.remove();
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
        top: widget.position.top,
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
