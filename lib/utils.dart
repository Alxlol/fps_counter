import 'package:flutter/foundation.dart';

class Position {
  const Position({this.left, this.right, this.top, this.bottom});

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}

void printError(String message) {
  debugPrint('\x1B[31mERROR: $message\x1B[0m');
}
