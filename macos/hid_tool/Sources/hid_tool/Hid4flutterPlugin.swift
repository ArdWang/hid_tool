import Cocoa
import FlutterMacOS
import IOKit

let kIOHIDDevicePathKey = "IOHIDDevicePath"

public class HidToolPlugin: NSObject, FlutterPlugin {
  var channel: FlutterMethodChannel?

  private var notificationPort: IONotificationPortRef?
  private var addedIterator: io_iterator_t = 0
  private var removedIterator: io_iterator_t = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hid_tool",
      binaryMessenger: registrar.messenger
    )

    let instance = HidToolPlugin()
    instance.channel = channel

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "startListening":
      startListening()
      result("Listening started")

    case "stopListening":
      stopListening()
      result("Listening stopped")

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startListening() {
    guard let matchingDict = IOServiceMatching(kIOHIDDeviceKey) else {
      print("Error: IOServiceMatching returned NULL for HID devices.")
      return
    }

    notificationPort = IONotificationPortCreate(kIOMainPortDefault)

    guard let notificationPort = notificationPort else {
      print("Error: IONotificationPortCreate returned NULL.")
      return
    }

    let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort)
      .takeUnretainedValue()

    CFRunLoopAddSource(
      CFRunLoopGetCurrent(),
      runLoopSource,
      CFRunLoopMode.defaultMode
    )

    let selfPointer = UnsafeMutableRawPointer(
      Unmanaged.passUnretained(self).toOpaque()
    )

    let addResult = IOServiceAddMatchingNotification(
      notificationPort,
      kIOFirstMatchNotification,
      matchingDict,
      deviceAddedCallback,
      selfPointer,
      &addedIterator
    )

    if addResult != KERN_SUCCESS {
      print("Error: IOServiceAddMatchingNotification (add) failed.")
      return
    }

    deviceAddedCallback(
      refcon: selfPointer,
      iterator: addedIterator
    )

    let removeResult = IOServiceAddMatchingNotification(
      notificationPort,
      kIOTerminatedNotification,
      matchingDict,
      deviceRemovedCallback,
      selfPointer,
      &removedIterator
    )

    if removeResult != KERN_SUCCESS {
      print("Error: IOServiceAddMatchingNotification (remove) failed.")
      return
    }

    deviceRemovedCallback(
      refcon: selfPointer,
      iterator: removedIterator
    )
  }

  private func stopListening() {
    if addedIterator != 0 {
      IOObjectRelease(addedIterator)
      addedIterator = 0
    }

    if removedIterator != 0 {
      IOObjectRelease(removedIterator)
      removedIterator = 0
    }

    if let port = notificationPort {
      IONotificationPortDestroy(port)
      notificationPort = nil
    }
  }
}

func deviceAddedCallback(
  refcon: UnsafeMutableRawPointer?,
  iterator: io_iterator_t
) {
  guard let refcon = refcon else {
    return
  }

  let plugin = Unmanaged<HidToolPlugin>
    .fromOpaque(refcon)
    .takeUnretainedValue()

  var hidDevice: io_object_t

  while true {
    hidDevice = IOIteratorNext(iterator)

    if hidDevice == 0 {
      break
    }

    var devicePath = "Unknown device"

    if let cfPath = IORegistryEntryCreateCFProperty(
      hidDevice,
      kIOHIDDevicePathKey as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? String {
      devicePath = cfPath
    }

    var vendorId: Int? = nil

    if let cfVid = IORegistryEntryCreateCFProperty(
      hidDevice,
      "idVendor" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? NSNumber {
      vendorId = cfVid.intValue
    }

    var productId: Int? = nil

    if let cfPid = IORegistryEntryCreateCFProperty(
      hidDevice,
      "idProduct" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? NSNumber {
      productId = cfPid.intValue
    }

    print(
      "HID Device connected: \(devicePath) " + "(VID: 0x\(String(format: "%04x", vendorId ?? 0)), "
        + "PID: 0x\(String(format: "%04x", productId ?? 0)))"
    )

    let args: [String: Any?] = [
      "path": devicePath,
      "vendorId": vendorId,
      "productId": productId,
    ]

    plugin.channel?.invokeMethod(
      "onDeviceConnected",
      arguments: args
    )

    IOObjectRelease(hidDevice)
  }
}

func deviceRemovedCallback(
  refcon: UnsafeMutableRawPointer?,
  iterator: io_iterator_t
) {
  guard let refcon = refcon else {
    return
  }

  let plugin = Unmanaged<HidToolPlugin>
    .fromOpaque(refcon)
    .takeUnretainedValue()

  var hidDevice: io_object_t

  while true {
    hidDevice = IOIteratorNext(iterator)

    if hidDevice == 0 {
      break
    }

    var devicePath = "Unknown device"

    if let cfPath = IORegistryEntryCreateCFProperty(
      hidDevice,
      kIOHIDDevicePathKey as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? String {
      devicePath = cfPath
    }

    var vendorId: Int? = nil

    if let cfVid = IORegistryEntryCreateCFProperty(
      hidDevice,
      "idVendor" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? NSNumber {
      vendorId = cfVid.intValue
    }

    var productId: Int? = nil

    if let cfPid = IORegistryEntryCreateCFProperty(
      hidDevice,
      "idProduct" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeUnretainedValue() as? NSNumber {
      productId = cfPid.intValue
    }

    print(
      "HID Device disconnected: \(devicePath) "
        + "(VID: 0x\(String(format: "%04x", vendorId ?? 0)), "
        + "PID: 0x\(String(format: "%04x", productId ?? 0)))"
    )

    let args: [String: Any?] = [
      "path": devicePath,
      "vendorId": vendorId,
      "productId": productId,
    ]

    plugin.channel?.invokeMethod(
      "onDeviceDisconnected",
      arguments: args
    )

    IOObjectRelease(hidDevice)
  }
}
