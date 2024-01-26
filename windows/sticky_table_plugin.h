#ifndef FLUTTER_PLUGIN_STICKY_TABLE_PLUGIN_H_
#define FLUTTER_PLUGIN_STICKY_TABLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace sticky_table {

class StickyTablePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  StickyTablePlugin();

  virtual ~StickyTablePlugin();

  // Disallow copy and assign.
  StickyTablePlugin(const StickyTablePlugin&) = delete;
  StickyTablePlugin& operator=(const StickyTablePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace sticky_table

#endif  // FLUTTER_PLUGIN_STICKY_TABLE_PLUGIN_H_
