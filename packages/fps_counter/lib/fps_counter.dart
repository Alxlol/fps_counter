import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Position {
  const Position({this.left, this.right, this.top, this.bottom});

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}

/// Run with: flutter run --profile --dart-define=fps_counter=true
///
/// WARNING: Hot restarting in debugMode will cause the ticker to throw an error on each frame, hot reload works as normal.
/// See: https://github.com/flutter/flutter/issues/10437
class FpsCounter {
  static bool _initialized = false;
  static _FpsOverlayManager? _overlayManager; // Store reference to manager

  static const bool _isFpsEnabled = bool.fromEnvironment(
    'fps_counter',
    defaultValue: false,
  );

  /// Call this once in main() to enable FPS overlay.
  /// Then run your project with flutter run --dart-define=fps_counter=true
  static void initialize({
    Color backgroundColor = Colors.black54,

    /// Averages readings, prevents wild fluctuations in the displayed FPS if set to true
    bool smoothing = false,
    double textSize = 14,

    /// Callback that fires each frame, returns the current fps. Be careful with this :)
    Function(double fps)? onFrameCallback,
    Position position = const Position(left: 16, top: 16),
  }) {
    if (kDebugMode && _isFpsEnabled) {
      debugPrint(
          '\x1B[31m== WARNING: Fps counter enabled in debug mode. Hot restarting the app will throw an error each frame. See: https://github.com/flutter/flutter/issues/10437 ==\x1B[0m');
    }
    if (!_isFpsEnabled || _initialized) {
      return;
    }

    debugPrint('\x1B[32m== FPS COUNTER ENABLED ==\x1B[0m');

    // Register service extensions for DevTools communication
    _registerServiceExtensions();

    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayManager = _FpsOverlayManager(
        backgroundColor: backgroundColor,
        smoothing: smoothing,
        textSize: textSize,
        onFrameCallback: onFrameCallback,
        position: position,
      );
      _overlayManager!._start();
    });
  }

  static void _registerServiceExtensions() {
    if (kDebugMode) {
      // Get current smoothing state
      registerExtension('ext.fps_counter.getSmoothing',
          (method, parameters) async {
        final smoothing = _overlayManager?.smoothing ?? false;
        return ServiceExtensionResponse.result(jsonEncode({
          'smoothing': smoothing,
        }));
      });

      // Set smoothing state
      registerExtension('ext.fps_counter.setSmoothing',
          (method, parameters) async {
        final enabled = parameters['enabled'] == 'true';
        _overlayManager?.updateSmoothing(enabled);
        print('SET SMOOTHING RECEIVED: $enabled');

        // Post event to notify DevTools of the change
        postEvent('fps_counter.smoothingChanged', {
          'smoothing': enabled,
        });

        return ServiceExtensionResponse.result(jsonEncode({
          'smoothing': enabled,
        }));
      });
    }
  }
}

class _FpsOverlayManager {
  _FpsOverlayManager({
    required this.backgroundColor,
    required bool smoothing,
    required this.textSize,
    required this.onFrameCallback,
    required this.position,
  }) : _smoothing = smoothing;

  final Color backgroundColor;
  bool _smoothing; // Make this mutable
  final double textSize;
  final Function(double fps)? onFrameCallback;
  final Position position;

  // Getter for smoothing
  bool get smoothing => _smoothing;

  OverlayEntry? _fpsOverlay;
  Ticker? _ticker;
  final ValueNotifier<double> _fps = ValueNotifier<double>(0.0);
  Duration? _lastFrameTime;

  // Method to update smoothing from service extension
  void updateSmoothing(bool newSmoothing) {
    _smoothing = newSmoothing;
    print('Smoothing updated to: $_smoothing');
  }

  void _start() {
    Future.delayed(Duration(milliseconds: 100), () {
      _insertFpsOverlay();
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
        if (_smoothing) {
          // Use the mutable _smoothing variable
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

  void _insertFpsOverlay() {
    final context =
        WidgetsBinding.instance.focusManager.primaryFocus?.context ??
            WidgetsBinding.instance.rootElement;

    if (context == null) {
      debugPrint('Could not find context to attach FPS counter');
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
