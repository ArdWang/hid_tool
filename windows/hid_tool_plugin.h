#ifndef FLUTTER_PLUGIN_HID_TOOL_PLUGIN_H_
#define FLUTTER_PLUGIN_HID_TOOL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace hid_tool {

class HidToolPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  HidToolPlugin();

  virtual ~HidToolPlugin();

  // Disallow copy and assign.
  HidToolPlugin(const HidToolPlugin&) = delete;
  HidToolPlugin& operator=(const HidToolPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace hid_tool

#endif  // FLUTTER_PLUGIN_HID4FLUTTER_PLUGIN_H_
