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

import 'package:universal_io/prefer_universal/io.dart';

/// Driver implementation can use this method to evaluate parameters of type
/// "a string or [InternetAddress]" (e.g. [RawSocket.connect]) into
/// [InternetAddress].
///
/// If the evaluation fails, this method throws [ArgumentError].
Future<InternetAddress> resolveHostOrInternetAddress(Object host) async {
  if (host is InternetAddress) {
    return host;
  } else if (host is String) {
    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty) {
      throw ArgumentError("Host '$host' could not be resolved.");
    }
    return addresses.first;
  } else {
    throw ArgumentError.value(host);
  }
}

class BaseConnectionTask<S> implements ConnectionTask<S> {
  @override
  final Future<S> socket;
  final void Function() _onCancel;

  BaseConnectionTask({Future<S> socket, void Function() onCancel})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  @override
  void cancel() {
    _onCancel();
  }
}
