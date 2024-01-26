#include "include/sticky_table/sticky_table_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sticky_table_plugin.h"

void StickyTablePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sticky_table::StickyTablePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
