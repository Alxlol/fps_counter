import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(SomePkgDevToolsExtension());
}

class SomePkgDevToolsExtension extends StatefulWidget {
  const SomePkgDevToolsExtension({super.key});

  @override
  State<SomePkgDevToolsExtension> createState() =>
      _SomePkgDevToolsExtensionState();
}

class _SomePkgDevToolsExtensionState extends State<SomePkgDevToolsExtension> {
  bool _smoothing = false;
  void toggleSmoothing() async {
    _smoothing = !_smoothing;
    try {
      final result = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.fps_counter.setSmoothing',
        args: {'enabled': _smoothing.toString()},
      );
      if (result.json != null) {
        setState(() {
          _smoothing = result.json!['smoothing'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading smoothing state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: Column(
        children: [
          Row(
            children: [
              Switch(value: true, onChanged: (value) {}),
              DevToolsButton(
                onPressed: toggleSmoothing,
                label: _smoothing.toString(),
              ),
              SizedBox(width: 8),
              Text('False'),
            ],
          ),
        ],
      ), // Build your extension here
    );
  }
}
