// Copyright 2019 terrier989@gmail.com.
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

/// Contains an implementation of [IODriver] for Node.JS.
library nodejs_io;

import 'dart:async';
import 'dart:typed_data';

import 'package:node_http/node_http.dart' as node_http;
import 'package:node_io/node_io.dart' as node_io;
import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';

part 'src/http_client.dart';
part 'src/http_server.dart';

/// An implementation of [IODriver] for Node.JS.
///
/// Usage:
/// ```
/// import 'package:nodejs_io/nodejs_io.dart';
///
/// void main() {
///   nodeJsIODriver.enable();
///
///   // ...
/// }
/// ```
final IODriver nodeJsIODriver = IODriver(
  parent: defaultIODriver,
  httpOverrides: _NodeJsHttpOverrides(),
  httpServerOverrides: _NodeJsHttpServerOverrides(),
);
