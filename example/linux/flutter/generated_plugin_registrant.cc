//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <sticky_table/sticky_table_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) sticky_table_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "StickyTablePlugin");
  sticky_table_plugin_register_with_registrar(sticky_table_registrar);
}
