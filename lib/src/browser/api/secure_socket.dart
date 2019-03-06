import 'dart:typed_data';

/// X509Certificate represents an SSL certificate, with accessors to
/// get the fields of the certificate.
abstract class X509Certificate {
  /// The DER encoded bytes of the certificate.
  Uint8List get der;

  /// The PEM encoded String of the certificate.
  String get pem;

  /// The SHA1 hash of the certificate.
  Uint8List get sha1;

  String get subject;

  String get issuer;

  DateTime get startValidity;

  DateTime get endValidity;
}
