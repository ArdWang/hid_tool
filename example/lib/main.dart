import 'package:flutter/material.dart';
import 'package:hid_tool/hid_tool.dart';
import 'dart:typed_data';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true),
      home: const DeviceListScreen(),
    );
  }
}

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  DeviceListScreenState createState() => DeviceListScreenState();
}

class DeviceListScreenState extends State<DeviceListScreen> {
  List<HidDevice> devices = [];
  List<String> eventLog = [];
  bool isListening = false;
  StreamSubscription<HidDeviceEvent>? _connectedSubscription;
  StreamSubscription<HidDeviceEvent>? _disconnectedSubscription;

  // Check if running on web
  bool get isWeb {
    try {
      return identical(0, 0.0); // Web-specific check
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConnectedDevices();
  }

  @override
  void dispose() {
    _connectedSubscription?.cancel();
    _disconnectedSubscription?.cancel();
    _stopListening();
    super.dispose();
  }

  Future<void> _loadConnectedDevices() async {
    try {
      List<HidDevice> connectedDevices = await Hid.getDevices();
      if (!mounted) return;
      setState(() {
        devices = connectedDevices;
      });
      _addLog('Found ${devices.length} device(s)');
    } catch (e) {
      _addLog('Error getting connected devices: $e');
    }
  }

  /// Request device access (Web only)
  Future<void> _requestDevice() async {
    if (!isWeb) return;

    try {
      _addLog('Requesting device access...');
      // On web, we need to request device access first
      final webDevices = await Hid.requestDevice();
      if (webDevices.isNotEmpty) {
        _addLog('Granted access to ${webDevices.length} device(s)');
        await _loadConnectedDevices();
      }
    } catch (e) {
      _addLog('Error requesting device: $e');
    }
  }

  Future<void> _startListening() async {
    if (isListening) return;

    try {
      await Hid.startListening();

      await _connectedSubscription?.cancel();
      await _disconnectedSubscription?.cancel();

      _connectedSubscription = HidDeviceEvents.onConnected.listen((event) {
        if (!mounted) return;
        setState(() {
          _addLog('Device Connected: ${event.path}');
          _addLog('  VID: 0x${event.vendorId?.toRadixString(16) ?? "unknown"}');
          _addLog('  PID: 0x${event.productId?.toRadixString(16) ?? "unknown"}');
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadConnectedDevices();
          }
        });
      });

      _disconnectedSubscription = HidDeviceEvents.onDisconnected.listen((event) {
        if (!mounted) return;
        setState(() {
          _addLog('Device Disconnected: ${event.path}');
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadConnectedDevices();
          }
        });
      });

      if (!mounted) return;
      setState(() {
        isListening = true;
        _addLog('Started listening for device events');
      });
    } catch (e) {
      _addLog('Error starting event listening: $e');
    }
  }

  Future<void> _stopListening() async {
    if (!isListening) return;

    try {
      await Hid.stopListening();
      await _connectedSubscription?.cancel();
      await _disconnectedSubscription?.cancel();
      _connectedSubscription = null;
      _disconnectedSubscription = null;
      if (!mounted) return;
      setState(() {
        isListening = false;
        _addLog('Stopped listening for device events');
      });
    } catch (e) {
      _addLog('Error stopping event listening: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    eventLog.insert(0, '[$timestamp] $message');
    // Keep only last 50 log entries
    if (eventLog.length > 50) {
      eventLog.removeRange(50, eventLog.length);
    }
  }

  Future<void> _showDeviceDetails(HidDevice device) async {
    showDialog(
      context: context,
      builder: (context) => DeviceDetailDialog(device: device),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('HID Tool Example'),
        actions: [
          if (isWeb)
            IconButton(
              icon: const Icon(Icons.add_circle),
              tooltip: 'Request Device Access',
              onPressed: _requestDevice,
            ),
          if (!isWeb)
            IconButton(
              icon: Icon(isListening ? Icons.stop_circle : Icons.play_circle),
              tooltip: isListening ? 'Stop Event Listening' : 'Start Event Listening',
              onPressed: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Devices',
            onPressed: _loadConnectedDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Log Section
          if (!isWeb) ...[
            Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Log',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          eventLog[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          // Device List Section
          Expanded(
            child: _buildDeviceList(),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'logBtn',
            onPressed: () {
              setState(() {
                eventLog.clear();
                _addLog('Log cleared');
              });
            },
            tooltip: 'Clear Log',
            child: const Icon(Icons.delete_sweep),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'refreshBtn',
            onPressed: _loadConnectedDevices,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.usb_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No HID devices found'),
            SizedBox(height: 8),
            Text('Connect a HID device or start event listening'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        HidDevice device = devices[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.usb, size: 40),
            title: Text(device.productName.isNotEmpty
                ? device.productName
                : 'Device $index'),
            subtitle: Text(
                'VID: 0x${device.vendorId.toRadixString(16)} | PID: 0x${device.productId.toRadixString(16)}'),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDeviceDetails(device),
            ),
            onTap: () => _showDeviceDetails(device),
          ),
        );
      },
    );
  }
}

class DeviceDetailDialog extends StatefulWidget {
  final HidDevice device;

  const DeviceDetailDialog({super.key, required this.device});

  @override
  State<DeviceDetailDialog> createState() => _DeviceDetailDialogState();
}

class _DeviceDetailDialogState extends State<DeviceDetailDialog> {
  bool isLoading = false;
  String? reportDescriptorInfo;
  Uint8List? rawDescriptor;

  @override
  void initState() {
    super.initState();
    _loadReportDescriptor();
  }

  Future<void> _loadReportDescriptor() async {
    setState(() {
      isLoading = true;
    });

    try {
      await widget.device.open();
      final descriptor = await widget.device.getReportDescriptor();
      rawDescriptor = descriptor.rawBytes;

      // Format descriptor information
      final sb = StringBuffer();
      sb.writeln('Report Descriptor Size: ${descriptor.rawBytes.length} bytes');
      sb.writeln('');
      sb.writeln('Collections: ${descriptor.collections.length}');
      sb.writeln('Input Items: ${descriptor.inputs.length}');
      sb.writeln('Output Items: ${descriptor.outputs.length}');
      sb.writeln('Feature Items: ${descriptor.features.length}');
      sb.writeln('');
      sb.writeln('Raw Bytes (hex):');
      sb.writeln(_formatHexDump(descriptor.rawBytes));
      setState(() {
        reportDescriptorInfo = sb.toString();
      });
    } catch (e) {
      setState(() {
        reportDescriptorInfo = 'Error loading report descriptor: $e';
      });
    } finally {
      if (widget.device.isOpen) {
        try {
          await widget.device.close();
        } catch (_) {}
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatHexDump(Uint8List data) {
    final sb = StringBuffer();
    for (int i = 0; i < data.length; i += 16) {
      sb.write(i.toRadixString(16).padLeft(4, '0'));
      sb.write(': ');
      for (int j = 0; j < 16 && i + j < data.length; j++) {
        sb.write(data[i + j].toRadixString(16).padLeft(2, '0'));
        sb.write(' ');
      }
      sb.writeln();
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.device.productName.isNotEmpty
          ? widget.device.productName
          : 'Device Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('Device Information', _buildDeviceInfo()),
              const SizedBox(height: 16),
              _buildInfoSection('Report Descriptor', _buildDescriptorContent()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Divider(),
        content,
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Path', widget.device.path),
        _buildInfoRow('Vendor ID', '0x${widget.device.vendorId.toRadixString(16)}'),
        _buildInfoRow('Product ID', '0x${widget.device.productId.toRadixString(16)}'),
        _buildInfoRow('Serial Number', widget.device.serialNumber.isEmpty ? 'N/A' : widget.device.serialNumber),
        _buildInfoRow('Release Number', '0x${widget.device.releaseNumber.toRadixString(16)}'),
        _buildInfoRow('Manufacturer', widget.device.manufacturer.isEmpty ? 'N/A' : widget.device.manufacturer),
        _buildInfoRow('Product Name', widget.device.productName.isEmpty ? 'N/A' : widget.device.productName),
        _buildInfoRow('Usage Page', '0x${widget.device.usagePage.toRadixString(16)}'),
        _buildInfoRow('Usage', '0x${widget.device.usage.toRadixString(16)}'),
        _buildInfoRow('Interface Number', '${widget.device.interfaceNumber}'),
        _buildInfoRow('Bus Type', '${widget.device.busType}'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptorContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportDescriptorInfo == null) {
      return const Text('Tap "Load Descriptor" to fetch report descriptor');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            reportDescriptorInfo!,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
