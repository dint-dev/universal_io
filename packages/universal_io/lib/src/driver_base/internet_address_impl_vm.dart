import 'dart:io';

import '../ip_utils.dart';

/// Constructs [InternetAddress] from bytes.
InternetAddress internetAddressFromBytes(List<int> bytes,
    {String address, String host}) {
  return InternetAddress(address ?? host ?? stringFromIp(bytes));
}
