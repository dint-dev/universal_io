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

import 'dart:io';

import 'package:universal_io/src/internal/ip_utils.dart';
import '../driver_for_vm/vm_io_driver.dart';

import 'drivers_in_vm.dart'; // <--- IMPORTANT

/// Determines the default IODriver:
///   * _BrowserIODriver_ in browser (when 'dart:html' is available).
///   * _BaseIODriver_ in Javascript targets such as Node.JS.
///   * Null otherwise (VM, Flutter).
final IODriver defaultIODriver = vmIODriver;

/// Constructs [InternetAddress] from bytes and/or string. You can optionally
/// specify a hostname too.
InternetAddress internetAddressFrom(
    {List<int> bytes, String address, String host}) {
  if (bytes == null && address == null) {
    throw ArgumentError("Bytes and address can't be both null");
  }
  return InternetAddress(address ?? stringFromIp(bytes));
}
