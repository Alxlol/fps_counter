# FPS Counter for Flutter

A simple, easy-to-use FPS counter for Flutter

Add `WidgetsFlutterBinding.ensureInitialized()` and `FpsCounter.initialize()` to your main function

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FpsCounter.initialize();
  runApp(const MyApp());
}
```

then run your project in profile mode -- `flutter run --profile`.
If you want the fps counter enabled in debug or release mode you can run your app with the `--dart-define=fps_counter=true` flag.

## Options:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FpsCounter.initialize(position: Position(bottom: 16, right: 16), smoothing: false, backgroundColor: Colors.transparent, startHidden: true);
  runApp(const MyApp());
}
```

## Running in debug WARNING:

Hot restarting in debug mode will cause the ticker to throw an error on each frame, hot reload works as normal.
See:
https://github.com/flutter/flutter/issues/69949
https://github.com/flutter/flutter/issues/10437

## Add to project:

Add to your pubspec.yaml

```yaml
dependencies:
    fps_counter:
        git:
            url: https://github.com/Alxlol/fps_counter
```
