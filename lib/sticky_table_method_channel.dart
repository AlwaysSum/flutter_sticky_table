import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sticky_table_platform_interface.dart';

/// An implementation of [StickyTablePlatform] that uses method channels.
class MethodChannelStickyTable extends StickyTablePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sticky_table');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
