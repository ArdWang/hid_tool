#ifndef FLUTTER_PLUGIN_HID_TOOL_PLUGIN_H_
#define FLUTTER_PLUGIN_HID_TOOL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include <windows.h>

namespace hid_tool {

class HidToolPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  HidToolPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~HidToolPlugin();

  // Disallow copy and assign.
  HidToolPlugin(const HidToolPlugin&) = delete;
  HidToolPlugin& operator=(const HidToolPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // Window procedure for handling device notifications
  static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

  // Notify HIDL for HID device events
  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND hwnd_;
};

}  // namespace hid_tool

#endif  // FLUTTER_PLUGIN_HID4FLUTTER_PLUGIN_H_
