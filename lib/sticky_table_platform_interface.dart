import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sticky_table_method_channel.dart';

abstract class StickyTablePlatform extends PlatformInterface {
  /// Constructs a StickyTablePlatform.
  StickyTablePlatform() : super(token: _token);

  static final Object _token = Object();

  static StickyTablePlatform _instance = MethodChannelStickyTable();

  /// The default instance of [StickyTablePlatform] to use.
  ///
  /// Defaults to [MethodChannelStickyTable].
  static StickyTablePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [StickyTablePlatform] when
  /// they register themselves.
  static set instance(StickyTablePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
