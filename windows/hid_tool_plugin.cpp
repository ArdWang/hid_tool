#include "hid_tool_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <dbt.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <iostream>
#include <string>

// Include initguid.h first to define GUIDs, then setupapi/hidclass
// This ensures GUID_DEVINTERFACE_HID is properly defined
#include <initguid.h>
#include <setupapi.h>
#include <hidclass.h>
#pragma comment(lib, "setupapi.lib")

// Helper function to convert wide strings to UTF-8 strings
std::string ConvertWStringToString(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();

    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);

    return strTo;
}

// Helper function to extract VID and PID from device path
bool ExtractVidPid(const std::string& device_path, int& vid, int& pid) {
    // Device path format: \\?\HID#VID_XXXX&PID_XXXX#...
    size_t vid_pos = device_path.find("VID_");
    size_t pid_pos = device_path.find("PID_");

    if (vid_pos != std::string::npos && pid_pos != std::string::npos) {
        try {
            vid = std::stoi(device_path.substr(vid_pos + 4, 4), nullptr, 16);
            pid = std::stoi(device_path.substr(pid_pos + 4, 4), nullptr, 16);
            return true;
        } catch (...) {
            return false;
        }
    }
    return false;
}

// Helper function to check if the device path is a HID device
bool IsHidDevice(const std::string& device_path) {
    return device_path.find("HID") != std::string::npos ||
           device_path.find("VID_") != std::string::npos;
}

namespace hid_tool {

// static
void HidToolPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "hid_tool",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<HidToolPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

HidToolPlugin::HidToolPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar), hwnd_(nullptr) {
  // Create a hidden window for receiving device notifications
  const std::wstring window_class_name = L"HID_DEVICE_LISTENER";

  WNDCLASS window_class = {};
  window_class.lpfnWndProc = WindowProc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.lpszClassName = window_class_name.c_str();
  RegisterClass(&window_class);

  hwnd_ = CreateWindow(window_class_name.c_str(), L"", 0, 0, 0, 0, 0, nullptr,
                       nullptr, GetModuleHandle(nullptr), this);

  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar_->messenger(), "hid_tool",
      &flutter::StandardMethodCodec::GetInstance());

  // Register for HID device interface notifications
  if (hwnd_ != nullptr) {
    DEV_BROADCAST_DEVICEINTERFACE NotificationFilter;
    ZeroMemory(&NotificationFilter, sizeof(NotificationFilter));
    NotificationFilter.dbcc_size = sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    NotificationFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    NotificationFilter.dbcc_classguid = GUID_DEVINTERFACE_HID;

    RegisterDeviceNotification(hwnd_, &NotificationFilter,
                               DEVICE_NOTIFY_WINDOW_HANDLE);
  }
}

HidToolPlugin::~HidToolPlugin() {
  if (hwnd_) {
    DestroyWindow(hwnd_);
  }
}

// Static method for handling Windows messages
LRESULT CALLBACK HidToolPlugin::WindowProc(HWND hwnd, UINT uMsg,
                                           WPARAM wParam, LPARAM lParam) {
  if (uMsg == WM_CREATE) {
    SetWindowLongPtr(hwnd, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(
                         reinterpret_cast<CREATESTRUCT*>(lParam)->lpCreateParams));
  } else if (uMsg == WM_DEVICECHANGE) {
    auto plugin = reinterpret_cast<HidToolPlugin*>(
        GetWindowLongPtr(hwnd, GWLP_USERDATA));

    if (plugin && (wParam == DBT_DEVICEARRIVAL ||
                   wParam == DBT_DEVICEREMOVECOMPLETE)) {
      DEV_BROADCAST_HDR* hdr = reinterpret_cast<DEV_BROADCAST_HDR*>(lParam);
      if (hdr->dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE) {
        DEV_BROADCAST_DEVICEINTERFACE* dev_interface =
            reinterpret_cast<DEV_BROADCAST_DEVICEINTERFACE*>(hdr);

        std::string device_path = ConvertWStringToString(dev_interface->dbcc_name);

        // Check if this is a HID device
        if (IsHidDevice(device_path)) {
          int vid = 0, pid = 0;
          ExtractVidPid(device_path, vid, pid);

          // Create event arguments map
          auto args = std::make_unique<flutter::EncodableMap>();
          args->insert({flutter::EncodableValue("path"),
                        flutter::EncodableValue(device_path)});
          args->insert({flutter::EncodableValue("vendorId"),
                        flutter::EncodableValue(vid)});
          args->insert({flutter::EncodableValue("productId"),
                        flutter::EncodableValue(pid)});

          if (wParam == DBT_DEVICEARRIVAL) {
            std::cerr << "HID Device connected: " << device_path
                      << " (VID: 0x" << std::hex << vid << ", PID: 0x" << pid << ")"
                      << std::endl;
            auto args_value = std::make_unique<flutter::EncodableValue>(std::move(*args));
            plugin->channel_->InvokeMethod("onDeviceConnected",
                                           std::move(args_value));
          } else if (wParam == DBT_DEVICEREMOVECOMPLETE) {
            std::cerr << "HID Device disconnected: " << device_path
                      << " (VID: 0x" << std::hex << vid << ", PID: 0x" << pid << ")"
                      << std::endl;
            auto args_value = std::make_unique<flutter::EncodableValue>(std::move(*args));
            plugin->channel_->InvokeMethod("onDeviceDisconnected",
                                           std::move(args_value));
          }
        }
      }
    }
  }
  return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void HidToolPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("startListening") == 0) {
    // Device notification is already registered in constructor
    // Just acknowledge the request
    result->Success();
  } else if (method_call.method_name().compare("stopListening") == 0) {
    // Device notification will be automatically unregistered when
    // the window is destroyed
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace hid_tool
