part of universal_io;

abstract class InternetAddress {
  final String address;
  final String host;
  factory InternetAddress(String address) = InternetAddress._;
  InternetAddress._(this.address) : this.host = null;
}

abstract class Socket {}

class SocketException implements Exception {
  final InternetAddress address;
  final String message;
  final OSError osError;
  final int port;
  const SocketException(this.message, {this.osError, this.address, this.port});
  const SocketException.closed() : this("Closed");
  String toString() => "SocketException: ${message}";
}
