import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  test('check ReceiveSharingIntent 1.8.1 methods', () {
    debugPrint('${SharedMediaType.values}');
    // Checking if instance is used
    ReceiveSharingIntent.instance.getMediaStream();
  });
}
