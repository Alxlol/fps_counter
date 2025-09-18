import 'package:flutter/material.dart';
import 'package:fps_counter/fps_counter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FpsCounter.initialize();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FPS Counter example app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: <Widget>[
              OutlinedButton(
                  onPressed: FpsCounter.hideFps, child: Text('Hide')),
              OutlinedButton(
                  onPressed: FpsCounter.showFps, child: Text('Show')),
              OutlinedButton(
                  onPressed: () => FpsCounter.setSmoothing(false),
                  child: Text('Disabled smoothing')),
              OutlinedButton(
                  onPressed: () => FpsCounter.setSmoothing(true),
                  child: Text('Enable smoothing'))
            ],
          ),
        ),
      ),
    );
  }
}
