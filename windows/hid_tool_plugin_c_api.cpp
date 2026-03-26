#include "include/hid_tool/hid_tool_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "hid_tool_plugin.h"

void HidToolPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  hid_tool::HidToolPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
