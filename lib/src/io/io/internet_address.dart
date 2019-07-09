// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
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

import 'dart:async';
import 'dart:typed_data';

import 'package:universal_io/src/driver/drivers_in_js.dart';
import 'package:universal_io/src/internal/ip_utils.dart' as ip_utils;

/// Not exported by 'package:universal_io/io.dart'.
///
/// This is declared for drivers.
InternetAddress internetAddressFromBytes(List<int> bytes,
    {String address, String host}) {
  return InternetAddress._(bytes, address: address, host: host);
}

/// An internet address.
///
/// This object holds an internet address. If this internet address
/// is the result of a DNS lookup, the address also holds the hostname
/// used to make the lookup.
/// An Internet address combined with a port number represents an
/// endpoint to which a socket can connect or a listening socket can
/// bind.
class InternetAddress {
  /// IP version 4 loopback address. Use this address when listening on
  /// or connecting to the loopback adapter using IP version 4 (IPv4).
  static final InternetAddress loopbackIPv4 = InternetAddress("127.0.0.1");

  /// IP version 6 loopback address. Use this address when listening on
  /// or connecting to the loopback adapter using IP version 6 (IPv6).
  static final InternetAddress loopbackIPv6 = InternetAddress("::1");

  /// IP version 4 any address. Use this address when listening on
  /// all adapters IP addresses using IP version 4 (IPv4).
  static final InternetAddress anyIPv4 = InternetAddress("0.0.0.0");

  /// IP version 6 any address. Use this address when listening on
  /// all adapters IP addresses using IP version 6 (IPv6).
  static final InternetAddress anyIPv6 = InternetAddress("::");

  final String _host;

  /// The host used to lookup the address. If there is no host
  /// associated with the address this returns the numeric address.
  String get host => _host ?? address;

  /// Creates a new [InternetAddress] from a numeric address.
  ///
  /// If the address in [address] is not a numeric IPv4
  /// (dotted-decimal notation) or IPv6 (hexadecimal representation).
  /// address [ArgumentError] is thrown.
  factory InternetAddress(String address) {
    return InternetAddress._(ip_utils.parseIp(address), address: address);
  }

  /// Private constructor.
  InternetAddress._(this.rawAddress, {String address, String host})
      : this._address = address,
        this._host = host;

  /// Address as given in the constructor. Can be null.
  String _address;

  /// The numeric address of the host. For IPv4 addresses this is using
  /// the dotted-decimal notation. For IPv6 it is using the
  /// hexadecimal representation.
  String get address {
    return _address ?? (_address = ip_utils.stringFromIp(rawAddress));
  }

  /// Returns true if the [InternetAddress]s scope is a link-local.
  bool get isLinkLocal => throw UnimplementedError();

  /// Returns true if the [InternetAddress] is a loopback address.
  bool get isLoopback {
    return this == loopbackIPv4 || this == loopbackIPv6;
  }

  /// Returns true if the [InternetAddress]s scope is multicast.
  bool get isMulticast => throw UnimplementedError();

  /// Get the raw address of this [InternetAddress]. The result is either a
  /// 4 or 16 byte long list. The returned list is a copy, making it possible
  /// to change the list without modifying the [InternetAddress].
  final Uint8List rawAddress;

  /// The [type] of the [InternetAddress] specified what IP protocol.
  InternetAddressType get type {
    if (rawAddress == null) {
      return null;
    }
    if (rawAddress.length == 4) {
      return InternetAddressType.IPv4;
    }
    return InternetAddressType.IPv6;
  }

  /// Perform a reverse dns lookup on the [address], creating a new
  /// [InternetAddress] where the host field set to the result.
  Future<InternetAddress> reverse() {
    final driver = IODriver.current.internetAddressDriver;
    if (driver == null) {
      throw UnimplementedError();
    }
    return driver.reverseLookup(this);
  }

  /// Lookup a host, returning a Future of a list of
  /// [InternetAddress]s. If [type] is [InternetAddressType.any], it
  /// will lookup both IP version 4 (IPv4) and IP version 6 (IPv6)
  /// addresses. If [type] is either [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] it will only lookup addresses of the
  /// specified type. The order of the list can, and most likely will,
  /// change over time.
  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    final driver = IODriver.current.internetAddressDriver;
    if (driver == null) {
      throw UnimplementedError();
    }
    return driver.lookup(host, type: type);
  }

  @override
  int get hashCode {
    var h = 0;
    final bytes = this.rawAddress;
    for (var i = 0; i < bytes.length; i++) {
      h ^= bytes[i] << 8 * (i % 3);
    }
    return h;
  }

  @override
  operator ==(other) {
    if (other is InternetAddress) {
      final leftBytes = rawAddress;
      final rightBytes = other.rawAddress;
      if (leftBytes.length != rightBytes.length) {
        return false;
      }
      for (var i = 0; i < leftBytes.length; i++) {
        if (leftBytes[i] != rightBytes[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

/// [InternetAddressType] is the type an [InternetAddress]. Currently,
/// IP version 4 (IPv4) and IP version 6 (IPv6) are supported.
class InternetAddressType {
  static const InternetAddressType IPv4 = InternetAddressType._(0);
  static const InternetAddressType IPv6 = InternetAddressType._(1);
  static const InternetAddressType any = InternetAddressType._(-1);

  final int _value;

  const InternetAddressType._(this._value);

  factory InternetAddressType._from(int value) {
    if (value == 0) return IPv4;
    if (value == 1) return IPv6;
    throw ArgumentError("Invalid type: $value");
  }

  /// Get the name of the type, e.g. "IPv4" or "IPv6".
  String get name {
    switch (_value) {
      case -1:
        return "ANY";
      case 0:
        return "IPv4";
      case 1:
        return "IPv6";
      default:
        throw ArgumentError("Invalid InternetAddress");
    }
  }

  String toString() => "InternetAddressType: $name";
}
