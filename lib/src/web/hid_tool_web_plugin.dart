// Web plugin registration
// Export HidWeb for the generated web_plugin_registrant.dart
export 'hid_web.dart' show HidWeb;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'hid_web.dart';

/// Web plugin registration function.
/// This is called by Flutter's web plugin registry.
void registerWith(Registrar registrar) {
  HidWeb.registerWith(registrar);
}
