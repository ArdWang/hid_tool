#include "include/hid_tool/hid_tool_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <libudev.h>
#include <string.h>
#include <pthread.h>
#include <poll.h>
#include <unistd.h>

#include <cstring>

#include "hid_tool_plugin_private.h"

#define HID_TOOL_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), hid_tool_plugin_get_type(), \
                              HidToolPlugin))

struct _HidToolPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  struct udev* udev;
  struct udev_monitor* mon;
  GThread* monitor_thread;
  volatile int running;
};

G_DEFINE_TYPE(HidToolPlugin, hid_tool_plugin, g_object_get_type())

// Forward declaration
static void* device_monitor_thread(void* data);

// Helper function to send event to Dart
static void send_device_event(HidToolPlugin* self, const char* method_name,
                               const char* device_path, int vendor_id, int product_id) {
  g_autoptr(FlValue) args = fl_value_new_map();
  fl_value_set_string_take(args, "path",
                           fl_value_new_string(device_path ? device_path : ""));

  if (vendor_id >= 0) {
    fl_value_set_string_take(args, "vendorId", fl_value_new_int(vendor_id));
  }
  if (product_id >= 0) {
    fl_value_set_string_take(args, "productId", fl_value_new_int(product_id));
  }

  g_autoptr(FlMethodCall) method_call = fl_method_call_new(
      fl_method_channel_get_name(self->channel),
      method_name,
      args,
      fl_method_channel_get_codec(self->channel));

  // Invoke method on the channel
  fl_method_channel_invoke_method(self->channel, method_name, args, NULL, NULL, NULL);
}

// Thread function to monitor udev events
static void* device_monitor_thread(void* data) {
  HidToolPlugin* self = HID_TOOL_PLUGIN(data);

  if (!self->mon) {
    return NULL;
  }

  int fd = udev_monitor_get_fd(self->mon);

  while (self->running) {
    struct pollfd fds[1];
    fds[0].fd = fd;
    fds[0].events = POLLIN;

    int ret = poll(fds, 1, 1000);  // 1 second timeout

    if (ret > 0 && (fds[0].revents & POLLIN)) {
      struct udev_device* dev = udev_monitor_receive_device(self->mon);

      if (dev) {
        const char* subsystem = udev_device_get_subsystem(dev);
        const char* action = udev_device_get_action(dev);
        const char* dev_path = udev_device_get_devnode(dev);

        // Check if it's a HID device
        const char* devtype = udev_device_get_devtype(dev);

        // Filter for HID devices (usb subsystem with hid devtype or hid subsystem)
        int is_hid = 0;
        if (subsystem && (strcmp(subsystem, "usb") == 0 ||
                          strcmp(subsystem, "hid") == 0)) {
          // Check if it's a HID device by looking at device properties
          const char* vendor_str = udev_device_get_sysattr_value(dev, "idVendor");
          if (vendor_str || (devtype && strcmp(devtype, "usb_device") == 0)) {
            is_hid = 1;
          }
          // Also check for hidraw devices
          if (dev_path && strstr(dev_path, "hidraw")) {
            is_hid = 1;
          }
        }

        if (is_hid && action && dev_path) {
          int vendor_id = -1;
          int product_id = -1;

          const char* vendor_str = udev_device_get_sysattr_value(dev, "idVendor");
          const char* product_str = udev_device_get_sysattr_value(dev, "idProduct");

          if (vendor_str) {
            vendor_id = (int)strtoul(vendor_str, NULL, 16);
          }
          if (product_str) {
            product_id = (int)strtoul(product_str, NULL, 16);
          }

          if (strcmp(action, "add") == 0) {
            g_message("HID Device connected: %s (VID: 0x%04x, PID: 0x%04x)",
                      dev_path, vendor_id, product_id);
            send_device_event(self, "onDeviceConnected", dev_path, vendor_id, product_id);
          } else if (strcmp(action, "remove") == 0) {
            g_message("HID Device disconnected: %s (VID: 0x%04x, PID: 0x%04x)",
                      dev_path, vendor_id, product_id);
            send_device_event(self, "onDeviceDisconnected", dev_path, vendor_id, product_id);
          }
        }

        udev_device_unref(dev);
      }
    }
  }

  return NULL;
}

// Called when a method call is received from Flutter.
static void hid_tool_plugin_handle_method_call(
    HidToolPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (g_strcmp0(method, "startListening") == 0) {
    // Start the device monitor thread
    if (!self->monitor_thread && self->running == 0) {
      self->running = 1;
      self->monitor_thread = g_thread_new("device-monitor",
                                           device_monitor_thread,
                                           self);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (g_strcmp0(method, "stopListening") == 0) {
    // Stop the device monitor thread
    self->running = 0;
    if (self->monitor_thread) {
      g_thread_join(self->monitor_thread);
      self->monitor_thread = NULL;
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void hid_tool_plugin_dispose(GObject* object) {
  HidToolPlugin* self = HID_TOOL_PLUGIN(object);

  // Stop monitoring
  self->running = 0;
  if (self->monitor_thread) {
    g_thread_join(self->monitor_thread);
    self->monitor_thread = NULL;
  }

  // Clean up udev
  if (self->mon) {
    udev_monitor_unref(self->mon);
    self->mon = NULL;
  }
  if (self->udev) {
    udev_unref(self->udev);
    self->udev = NULL;
  }

  G_OBJECT_CLASS(hid_tool_plugin_parent_class)->dispose(object);
}

static void hid_tool_plugin_class_init(HidToolPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = hid_tool_plugin_dispose;
}

static void hid_tool_plugin_init(HidToolPlugin* self) {
  // Initialize udev
  self->udev = udev_new();
  if (!self->udev) {
    g_warning("Failed to initialize udev");
    return;
  }

  // Create and setup monitor
  self->mon = udev_monitor_new_from_netlink(self->udev, "udev");
  if (self->mon) {
    // Filter for usb and hid subsystems
    udev_monitor_filter_add_match_subsystem_devtype(self->mon, "usb", "usb_device");
    udev_monitor_filter_add_match_subsystem_devtype(self->mon, "hid", NULL);
    udev_monitor_enable_receiving(self->mon);
  }

  self->running = 0;
  self->monitor_thread = NULL;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  HidToolPlugin* plugin = HID_TOOL_PLUGIN(user_data);
  hid_tool_plugin_handle_method_call(plugin, method_call);
}

void hid_tool_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  HidToolPlugin* plugin = HID_TOOL_PLUGIN(
      g_object_new(hid_tool_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "hid_tool",
                            FL_METHOD_CODEC(codec));

  plugin->channel = channel;

  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
