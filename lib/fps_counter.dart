import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fps_counter/utils.dart';

class FpsCounter {
  static bool _initialized = false;
  static FpsCounterOverlay? fpsCounterOverlay;
  static const bool _isFpsEnabled = bool.fromEnvironment(
    'fps_counter',
    defaultValue: false,
  );
  static bool visibility = false;

  static bool toggleVisibility() {
    setVisibility(!visibility);
    return visibility;
  }

  static void setVisibility(bool value) {
    value ? fpsCounterOverlay?._show() : fpsCounterOverlay?._hide();
    visibility = value;
  }

  static void toggleSmoothing() {
    if (fpsCounterOverlay != null) {
      fpsCounterOverlay!.smoothing
          ? fpsCounterOverlay?.smoothing = false
          : fpsCounterOverlay?.smoothing = true;
    }
  }

  static void setSmoothing(bool value) {
    fpsCounterOverlay?.smoothing = value;
  }

  static void initialize(
      {Color backgroundColor = Colors.black54,
      bool smoothing = false,
      double textSize = 14,
      Function(double fps)? onFrameCallback,
      bool startHidden = false,
      Position position = const Position(left: 16, top: 16)}) {
    if (!kProfileMode && !_isFpsEnabled || _initialized) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '\x1B[31m== WARNING: Fps counter enabled in debug mode. Hot restarting the app will throw an error each frame. See: https://github.com/flutter/flutter/issues/10437 ==\x1B[0m');
    }

    debugPrint('\x1B[32m== FPS COUNTER ENABLED ==\x1B[0m');
    _initialized = true;
    visibility = !startHidden;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fpsCounterOverlay = FpsCounterOverlay(
        backgroundColor: backgroundColor,
        smoothing: smoothing,
        textSize: textSize,
        onFrameCallback: onFrameCallback,
        position: position,
        startHidden: startHidden,
      );
    });
  }
}

class FpsCounterOverlay {
  FpsCounterOverlay({
    required this.backgroundColor,
    required this.smoothing,
    required this.textSize,
    required this.onFrameCallback,
    required this.position,
    required this.startHidden,
  }) {
    _start(startHidden);
  }

  final Color backgroundColor;
  bool smoothing = false;
  final double textSize;
  final Function(double fps)? onFrameCallback;
  final Position position;
  final bool startHidden;

  OverlayEntry? _fpsOverlay;
  Ticker? _ticker;
  final ValueNotifier<double> _fps = ValueNotifier<double>(0.0);
  Duration? _lastFrameTime;

  void _start(bool startHidden) {
    Future.delayed(Duration(milliseconds: 100), () {
      _insertFpsOverlay();
      if (startHidden) {
        _hide();
      }
    });
    _ticker = Ticker(_updateFps);
    _ticker?.start();
  }

  void _updateFps(Duration currentTime) {
    if (_lastFrameTime != null) {
      final deltaTime = currentTime - _lastFrameTime!;
      final deltaSeconds = deltaTime.inMicroseconds / 1000000.0;
      if (deltaSeconds > 0) {
        final fps = 1.0 / deltaSeconds;
        if (smoothing) {
          _fps.value = _fps.value * 0.9 + fps * 0.1;
        } else {
          _fps.value = fps;
        }
        onFrameCallback?.call(_fps.value);
      }
    }
    _lastFrameTime = currentTime;
  }

  Color get _color {
    if (_fps.value >= 50) {
      return const Color.fromARGB(255, 114, 255, 119);
    } else if (_fps.value >= 30) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  void _hide() {
    _ticker?.stop();
    _fpsOverlay?.remove();
    _fpsOverlay = null;
  }

  void _show() {
    if (_fpsOverlay == null) {
      _insertFpsOverlay();
    }
    if (_ticker != null && !_ticker!.isTicking) {
      _ticker?.start();
    }
  }

  void _insertFpsOverlay() {
    final context =
        WidgetsBinding.instance.focusManager.primaryFocus?.context ??
            WidgetsBinding.instance.rootElement;

    if (context == null) {
      printError('Could not find context to attach FPS counter');
      return;
    }

    _fpsOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.top,
        left: position.left,
        right: position.right,
        bottom: position.bottom,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ValueListenableBuilder(
              valueListenable: _fps,
              builder: (context, fps, child) {
                return Text(
                  "${_fps.value.round()} FPS",
                  style: TextStyle(
                    color: _color,
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_fpsOverlay!);
  }
}
