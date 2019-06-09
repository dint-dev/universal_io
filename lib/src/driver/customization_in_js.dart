// Copyright 'dart-universal_io' project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:universal_io/src/internal/ip_utils.dart';

import '../io/io/internet_address.dart' show InternetAddress;
import '../io/io/internet_address.dart' as internet_address;

export 'package:universal_io/driver_base.dart';

export 'customization_in_js_non_browser.dart'
    if (dart.library.html) 'customization_in_js_browser.dart';

/// Constructs [InternetAddress] from bytes and/or string. You can optionally
/// specify a hostname too.
InternetAddress internetAddressFrom(
    {List<int> bytes, String address, String host}) {
  if (bytes == null) {
    if (address == null) {
      throw ArgumentError("Bytes and address can't be both null");
    }
    bytes = parseIp(address);
  }
  return internet_address.internetAddressFromBytes(bytes,
      address: address, host: host);
}
