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

import 'package:universal_io/driver.dart';
import 'package:universal_io/src/driver_for_browser/browser_io_driver.dart';

/// Determines the default IODriver:
///   1.) BrowserIODriver when 'dart:html' is available.
///   2.) IODriver in 'drivers_in_js.dart' when when 'dart:js' is available.
///   3.) IODriver in "drivers_in_vm.dart' otherwise.
final IODriver defaultIODriver = BrowserIODriver();
