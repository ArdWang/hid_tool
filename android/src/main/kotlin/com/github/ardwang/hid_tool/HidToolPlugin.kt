package com.github.ardwang.hid_tool

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.charset.StandardCharsets

/** HidToolPlugin */
class HidToolPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    private const val CHANNEL_NAME = "hid_tool"
    private const val ACTION_USB_PERMISSION = "com.github.ardwang.hid_tool.USB_PERMISSION"

    private const val USB_REQUEST_GET_DESCRIPTOR = 0x06
    private const val USB_RECIPIENT_DEVICE = 0x00
    private const val USB_RECIPIENT_INTERFACE = 0x01
    private const val HID_REQUEST_GET_REPORT = 0x01
    private const val HID_REQUEST_SET_REPORT = 0x09

    private const val USB_DESCRIPTOR_TYPE_STRING = 0x03
    private const val HID_DESCRIPTOR_TYPE_REPORT = 0x22

    private const val HID_REPORT_TYPE_OUTPUT = 0x02
    private const val HID_REPORT_TYPE_FEATURE = 0x03
    private const val HID_API_BUS_USB = 0x01

    private const val DEFAULT_PACKET_SIZE = 64
    private const val DEFAULT_CONTROL_TIMEOUT_MS = 1000
    private const val DEFAULT_LANGUAGE_ID = 0x0409
  }

  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private lateinit var usbManager: UsbManager
  private lateinit var permissionIntent: PendingIntent

  private val openSessions = mutableMapOf<String, DeviceSession>()
  private val pendingPermissionRequests = mutableMapOf<String, MutableList<PendingOpenRequest>>()

  private var permissionReceiverRegistered = false
  private var deviceEventsReceiverRegistered = false

  private val permissionReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
      if (intent?.action != ACTION_USB_PERMISSION) {
        return
      }

      val device = intent.extractUsbDevice() ?: return
      val requests = pendingPermissionRequests.remove(device.deviceName) ?: return
      val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)

      for (request in requests) {
        if (!permissionGranted) {
          request.result.error(
            "PERMISSION_DENIED",
            "USB permission denied for ${device.deviceName}.",
            null,
          )
          continue
        }

        try {
          val reference = findDeviceReference(request.path)
            ?: throw HidPlatformException(
              "DEVICE_NOT_FOUND",
              "HID device ${request.path} is no longer available.",
            )
          completeOpen(reference)
          request.result.success(null)
        } catch (error: Throwable) {
          reportError(request.result, error)
        }
      }
    }
  }

  private val deviceEventsReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
      val device = intent.extractUsbDevice() ?: return

      when (intent?.action) {
        UsbManager.ACTION_USB_DEVICE_ATTACHED -> dispatchDeviceEvent("onDeviceConnected", device)
        UsbManager.ACTION_USB_DEVICE_DETACHED -> {
          closeSessionsForDevice(device.deviceName)
          dispatchDeviceEvent("onDeviceDisconnected", device)
        }
      }
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    usbManager = applicationContext.getSystemService(Context.USB_SERVICE) as UsbManager
    permissionIntent = PendingIntent.getBroadcast(
      applicationContext,
      0,
      Intent(ACTION_USB_PERMISSION).setPackage(applicationContext.packageName),
      pendingIntentFlags(),
    )

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
    registerPermissionReceiver()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getDevices" -> runSafely(result) {
        enumerateDevices(
          call.argument<Int>("vendorId"),
          call.argument<Int>("productId"),
        )
      }
      "openDevice" -> {
        val path = call.argument<String>("path")
        if (path == null) {
          result.error("INVALID_ARGUMENT", "Missing device path.", null)
          return
        }
        openDevice(path, result)
      }
      "closeDevice" -> withPath(call, result) { path ->
        closeSession(path)
        null
      }
      "receiveReport" -> withPath(call, result) { path ->
        receiveReport(
          path,
          call.argument<Int>("reportLength") ?: DEFAULT_PACKET_SIZE,
          call.argument<Int>("timeout"),
        )
      }
      "sendReport" -> withPath(call, result) { path ->
        sendOutputReport(
          path,
          call.argument<Int>("reportId") ?: 0,
          call.argument<ByteArray>("data") ?: ByteArray(0),
        )
        null
      }
      "receiveFeatureReport" -> withPath(call, result) { path ->
        receiveFeatureReport(
          path,
          call.argument<Int>("reportId") ?: 0,
          call.argument<Int>("bufferSize") ?: 1024,
        )
      }
      "sendFeatureReport" -> withPath(call, result) { path ->
        sendFeatureReport(
          path,
          call.argument<Int>("reportId") ?: 0,
          call.argument<ByteArray>("data") ?: ByteArray(0),
        )
        null
      }
      "sendOutputReport" -> withPath(call, result) { path ->
        sendOutputReport(
          path,
          call.argument<Int>("reportId") ?: 0,
          call.argument<ByteArray>("data") ?: ByteArray(0),
        )
        null
      }
      "getIndexedString" -> withPath(call, result) { path ->
        getIndexedString(
          path,
          call.argument<Int>("index") ?: 0,
          call.argument<Int>("maxLength") ?: 256,
        )
      }
      "getReportDescriptor" -> withPath(call, result) { path ->
        getReportDescriptor(path)
      }
      "startListening" -> runSafely(result) {
        startListeningInternal()
        null
      }
      "stopListening" -> runSafely(result) {
        stopListeningInternal()
        null
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    stopListeningInternal()
    unregisterPermissionReceiver()
    closeAllSessions()
    channel.setMethodCallHandler(null)
  }

  private fun openDevice(path: String, result: Result) {
    try {
      if (openSessions.containsKey(path)) {
        result.success(null)
        return
      }

      val reference = findDeviceReference(path)
        ?: throw HidPlatformException("DEVICE_NOT_FOUND", "HID device $path was not found.")

      if (!usbManager.hasPermission(reference.device)) {
        pendingPermissionRequests
          .getOrPut(reference.device.deviceName) { mutableListOf() }
          .add(PendingOpenRequest(path, result))
        usbManager.requestPermission(reference.device, permissionIntent)
        return
      }

      completeOpen(reference)
      result.success(null)
    } catch (error: Throwable) {
      reportError(result, error)
    }
  }

  @Suppress("UNUSED_PARAMETER")
  private fun enumerateDevices(vendorId: Int?, productId: Int?): List<Map<String, Any>> {
    val devices = mutableListOf<Map<String, Any>>()

    for (device in usbManager.deviceList.values) {
      if (vendorId != null && device.vendorId != vendorId) {
        continue
      }

      if (productId != null && device.productId != productId) {
        continue
      }

      for (index in 0 until device.interfaceCount) {
        val usbInterface = device.getInterface(index)
        if (!isHidInterface(usbInterface)) {
          continue
        }

        devices.add(createDeviceInfo(device, usbInterface))
      }
    }

    return devices
  }

  private fun completeOpen(reference: DeviceReference) {
    closeSession(reference.path)

    val connection = usbManager.openDevice(reference.device)
      ?: throw HidPlatformException("OPEN_FAILED", "Failed to open USB device ${reference.path}.")

    if (!connection.claimInterface(reference.usbInterface, true)) {
      connection.close()
      throw HidPlatformException(
        "OPEN_FAILED",
        "Failed to claim HID interface ${reference.usbInterface.id} for ${reference.path}.",
      )
    }

    val endpoints = findEndpoints(reference.usbInterface)
    openSessions[reference.path] = DeviceSession(
      path = reference.path,
      device = reference.device,
      usbInterface = reference.usbInterface,
      connection = connection,
      inputEndpoint = endpoints.first,
      outputEndpoint = endpoints.second,
    )
  }

  private fun receiveReport(path: String, reportLength: Int, timeout: Int?): ByteArray {
    val session = requireSession(path)
    val inputEndpoint = session.inputEndpoint
      ?: throw HidPlatformException("UNSUPPORTED", "Device $path does not expose an input endpoint.")

    val packetSize = if (reportLength > 0) reportLength else inputEndpoint.maxPacketSize
    val buffer = ByteArray(packetSize.coerceAtLeast(1))
    val timeoutMs = timeout ?: 0
    val bytesRead = session.connection.bulkTransfer(inputEndpoint, buffer, buffer.size, timeoutMs)

    if (bytesRead < 0) {
      if (timeout != null && timeout > 0) {
        throw HidPlatformException("TIMEOUT", "Timed out waiting for an input report from $path.")
      }
      throw HidPlatformException("IO_ERROR", "Failed to receive an input report from $path.")
    }

    return buffer.copyOf(bytesRead)
  }

  private fun sendOutputReport(path: String, reportId: Int, data: ByteArray) {
    val session = requireSession(path)
    val payload = withReportId(reportId, data)

    val bytesWritten = session.outputEndpoint?.let { endpoint ->
      session.connection.bulkTransfer(endpoint, payload, payload.size, DEFAULT_CONTROL_TIMEOUT_MS)
    } ?: session.connection.controlTransfer(
      UsbConstants.USB_DIR_OUT or UsbConstants.USB_TYPE_CLASS or USB_RECIPIENT_INTERFACE,
      HID_REQUEST_SET_REPORT,
      (HID_REPORT_TYPE_OUTPUT shl 8) or (reportId and 0xFF),
      session.usbInterface.id,
      payload,
      payload.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesWritten < 0) {
      throw HidPlatformException("IO_ERROR", "Failed to send an output report to $path.")
    }
  }

  private fun receiveFeatureReport(path: String, reportId: Int, bufferSize: Int): ByteArray {
    val session = requireSession(path)
    val buffer = ByteArray(bufferSize.coerceAtLeast(1))
    val bytesRead = session.connection.controlTransfer(
      UsbConstants.USB_DIR_IN or UsbConstants.USB_TYPE_CLASS or USB_RECIPIENT_INTERFACE,
      HID_REQUEST_GET_REPORT,
      (HID_REPORT_TYPE_FEATURE shl 8) or (reportId and 0xFF),
      session.usbInterface.id,
      buffer,
      buffer.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesRead < 0) {
      throw HidPlatformException("IO_ERROR", "Failed to receive a feature report from $path.")
    }

    return buffer.copyOf(bytesRead)
  }

  private fun sendFeatureReport(path: String, reportId: Int, data: ByteArray) {
    val session = requireSession(path)
    val payload = withReportId(reportId, data)
    val bytesWritten = session.connection.controlTransfer(
      UsbConstants.USB_DIR_OUT or UsbConstants.USB_TYPE_CLASS or USB_RECIPIENT_INTERFACE,
      HID_REQUEST_SET_REPORT,
      (HID_REPORT_TYPE_FEATURE shl 8) or (reportId and 0xFF),
      session.usbInterface.id,
      payload,
      payload.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesWritten < 0) {
      throw HidPlatformException("IO_ERROR", "Failed to send a feature report to $path.")
    }
  }

  private fun getIndexedString(path: String, index: Int, maxLength: Int): String {
    if (index <= 0) {
      return ""
    }

    val session = requireSession(path)
    val buffer = ByteArray(maxLength.coerceAtLeast(2))
    val languageId = resolveLanguageId(session.connection)
    val bytesRead = session.connection.controlTransfer(
      UsbConstants.USB_DIR_IN or UsbConstants.USB_TYPE_STANDARD or USB_RECIPIENT_DEVICE,
      USB_REQUEST_GET_DESCRIPTOR,
      (USB_DESCRIPTOR_TYPE_STRING shl 8) or (index and 0xFF),
      languageId,
      buffer,
      buffer.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesRead < 2) {
      throw HidPlatformException("IO_ERROR", "Failed to read string descriptor $index from $path.")
    }

    val descriptorLength = minOf(bytesRead, buffer[0].toInt() and 0xFF)
    if (descriptorLength <= 2) {
      return ""
    }

    return String(buffer, 2, descriptorLength - 2, StandardCharsets.UTF_16LE)
  }

  private fun getReportDescriptor(path: String): ByteArray {
    val session = requireSession(path)
    val buffer = ByteArray(4096)
    val bytesRead = session.connection.controlTransfer(
      UsbConstants.USB_DIR_IN or UsbConstants.USB_TYPE_STANDARD or USB_RECIPIENT_INTERFACE,
      USB_REQUEST_GET_DESCRIPTOR,
      HID_DESCRIPTOR_TYPE_REPORT shl 8,
      session.usbInterface.id,
      buffer,
      buffer.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesRead < 0) {
      throw HidPlatformException("IO_ERROR", "Failed to read the report descriptor from $path.")
    }

    return buffer.copyOf(bytesRead)
  }

  private fun createDeviceInfo(device: UsbDevice, usbInterface: UsbInterface): Map<String, Any> {
    val path = buildDevicePath(device, usbInterface)
    val inputEndpoint = findEndpoints(usbInterface).first

    return hashMapOf(
      "id" to path,
      "path" to path,
      "vendorId" to device.vendorId,
      "productId" to device.productId,
      "serialNumber" to safeSerialNumber(device),
      "releaseNumber" to parseReleaseNumber(safeVersion(device)),
      "manufacturer" to safeManufacturerName(device),
      "productName" to safeProductName(device),
      "usagePage" to 0,
      "usage" to 0,
      "interfaceNumber" to usbInterface.id,
      "busType" to HID_API_BUS_USB,
      "inputReportSize" to (inputEndpoint?.maxPacketSize ?: DEFAULT_PACKET_SIZE),
    )
  }

  private fun dispatchDeviceEvent(method: String, device: UsbDevice) {
    for (index in 0 until device.interfaceCount) {
      val usbInterface = device.getInterface(index)
      if (!isHidInterface(usbInterface)) {
        continue
      }

      channel.invokeMethod(method, createDeviceInfo(device, usbInterface))
    }
  }

  private fun startListeningInternal() {
    if (deviceEventsReceiverRegistered) {
      return
    }

    registerReceiver(
      deviceEventsReceiver,
      IntentFilter().apply {
        addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
      },
    )
    deviceEventsReceiverRegistered = true
  }

  private fun stopListeningInternal() {
    if (!deviceEventsReceiverRegistered) {
      return
    }

    applicationContext.unregisterReceiver(deviceEventsReceiver)
    deviceEventsReceiverRegistered = false
  }

  private fun registerPermissionReceiver() {
    if (permissionReceiverRegistered) {
      return
    }

    registerReceiver(permissionReceiver, IntentFilter(ACTION_USB_PERMISSION))
    permissionReceiverRegistered = true
  }

  private fun unregisterPermissionReceiver() {
    if (!permissionReceiverRegistered) {
      return
    }

    applicationContext.unregisterReceiver(permissionReceiver)
    permissionReceiverRegistered = false
  }

  private fun registerReceiver(receiver: BroadcastReceiver, filter: IntentFilter) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      applicationContext.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
      @Suppress("DEPRECATION")
      applicationContext.registerReceiver(receiver, filter)
    }
  }

  private fun pendingIntentFlags(): Int {
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return flags
  }

  private fun withPath(call: MethodCall, result: Result, block: (String) -> Any?) {
    val path = call.argument<String>("path")
    if (path == null) {
      result.error("INVALID_ARGUMENT", "Missing device path.", null)
      return
    }

    runSafely(result) {
      block(path)
    }
  }

  private fun runSafely(result: Result, block: () -> Any?) {
    try {
      result.success(block())
    } catch (error: Throwable) {
      reportError(result, error)
    }
  }

  private fun reportError(result: Result, error: Throwable) {
    if (error is HidPlatformException) {
      result.error(error.code, error.message, null)
    } else {
      result.error("HID_ERROR", error.message ?: "Unknown HID error.", null)
    }
  }

  private fun requireSession(path: String): DeviceSession {
    return openSessions[path]
      ?: throw HidPlatformException("NOT_OPEN", "Device $path is not open.")
  }

  private fun closeSession(path: String) {
    val session = openSessions.remove(path) ?: return
    try {
      session.connection.releaseInterface(session.usbInterface)
    } catch (_: Throwable) {
    }
    session.connection.close()
  }

  private fun closeSessionsForDevice(deviceName: String) {
    val paths = openSessions.keys.filter { it.startsWith("$deviceName#") }
    for (path in paths) {
      closeSession(path)
    }
  }

  private fun closeAllSessions() {
    val paths = openSessions.keys.toList()
    for (path in paths) {
      closeSession(path)
    }
  }

  private fun findDeviceReference(path: String): DeviceReference? {
    val separator = path.lastIndexOf('#')
    if (separator <= 0 || separator == path.lastIndex) {
      return null
    }

    val deviceName = path.substring(0, separator)
    val interfaceId = path.substring(separator + 1).toIntOrNull() ?: return null
    val device = usbManager.deviceList[deviceName] ?: return null

    for (index in 0 until device.interfaceCount) {
      val usbInterface = device.getInterface(index)
      if (usbInterface.id == interfaceId && isHidInterface(usbInterface)) {
        return DeviceReference(buildDevicePath(device, usbInterface), device, usbInterface)
      }
    }

    return null
  }

  private fun findEndpoints(usbInterface: UsbInterface): Pair<UsbEndpoint?, UsbEndpoint?> {
    var inputEndpoint: UsbEndpoint? = null
    var outputEndpoint: UsbEndpoint? = null

    for (index in 0 until usbInterface.endpointCount) {
      val endpoint = usbInterface.getEndpoint(index)
      if (endpoint.type != UsbConstants.USB_ENDPOINT_XFER_INT &&
        endpoint.type != UsbConstants.USB_ENDPOINT_XFER_BULK
      ) {
        continue
      }

      if (endpoint.direction == UsbConstants.USB_DIR_IN && inputEndpoint == null) {
        inputEndpoint = endpoint
      } else if (endpoint.direction == UsbConstants.USB_DIR_OUT && outputEndpoint == null) {
        outputEndpoint = endpoint
      }
    }

    return inputEndpoint to outputEndpoint
  }

  private fun buildDevicePath(device: UsbDevice, usbInterface: UsbInterface): String {
    return "${device.deviceName}#${usbInterface.id}"
  }

  private fun withReportId(reportId: Int, data: ByteArray): ByteArray {
    val payload = ByteArray(data.size + 1)
    payload[0] = reportId.toByte()
    System.arraycopy(data, 0, payload, 1, data.size)
    return payload
  }

  private fun resolveLanguageId(connection: UsbDeviceConnection): Int {
    val buffer = ByteArray(255)
    val bytesRead = connection.controlTransfer(
      UsbConstants.USB_DIR_IN or UsbConstants.USB_TYPE_STANDARD or USB_RECIPIENT_DEVICE,
      USB_REQUEST_GET_DESCRIPTOR,
      USB_DESCRIPTOR_TYPE_STRING shl 8,
      0,
      buffer,
      buffer.size,
      DEFAULT_CONTROL_TIMEOUT_MS,
    )

    if (bytesRead >= 4) {
      return ((buffer[3].toInt() and 0xFF) shl 8) or (buffer[2].toInt() and 0xFF)
    }

    return DEFAULT_LANGUAGE_ID
  }

  private fun isHidInterface(usbInterface: UsbInterface): Boolean {
    return usbInterface.interfaceClass == UsbConstants.USB_CLASS_HID
  }

  private fun safeManufacturerName(device: UsbDevice): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      try {
        device.manufacturerName ?: ""
      } catch (_: SecurityException) {
        ""
      }
    } else {
      ""
    }
  }

  private fun safeProductName(device: UsbDevice): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      try {
        device.productName ?: ""
      } catch (_: SecurityException) {
        ""
      }
    } else {
      ""
    }
  }

  private fun safeSerialNumber(device: UsbDevice): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      try {
        device.serialNumber ?: ""
      } catch (_: SecurityException) {
        ""
      }
    } else {
      ""
    }
  }

  private fun safeVersion(device: UsbDevice): String? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      device.version
    } else {
      null
    }
  }

  private fun parseReleaseNumber(version: String?): Int {
    if (version.isNullOrBlank()) {
      return 0
    }

    val parts = version.split('.')
    val major = parts.getOrNull(0)?.toIntOrNull() ?: return 0
    val minorDigits = parts.getOrNull(1)
      ?.filter { it.isDigit() }
      ?.padEnd(2, '0')
      ?.take(2)
      ?.toIntOrNull() ?: 0

    val majorBcd = ((major / 10) shl 4) or (major % 10)
    val minorBcd = ((minorDigits / 10) shl 4) or (minorDigits % 10)
    return (majorBcd shl 8) or minorBcd
  }

  @Suppress("DEPRECATION")
  private fun Intent?.extractUsbDevice(): UsbDevice? {
    if (this == null) {
      return null
    }

    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
    } else {
      getParcelableExtra(UsbManager.EXTRA_DEVICE) as? UsbDevice
    }
  }

  private data class PendingOpenRequest(
    val path: String,
    val result: Result,
  )

  private data class DeviceReference(
    val path: String,
    val device: UsbDevice,
    val usbInterface: UsbInterface,
  )

  private data class DeviceSession(
    val path: String,
    val device: UsbDevice,
    val usbInterface: UsbInterface,
    val connection: UsbDeviceConnection,
    val inputEndpoint: UsbEndpoint?,
    val outputEndpoint: UsbEndpoint?,
  )

  private class HidPlatformException(
    val code: String,
    override val message: String,
  ) : RuntimeException(message)
}

