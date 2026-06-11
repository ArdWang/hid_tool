class HidException implements Exception {
  HidException([this.message]);

  final String? message;

  @override
  String toString() {
    if (message != null) {
      return 'HidException: $message';
    }
    return 'HidException';
  }
}
