// Copyright 2020 terrier989@gmail.com.
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

library universal_io.browser_driver;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:meta/meta.dart';

import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';
import 'dart:typed_data';

part 'browser/http_client.dart';
part 'browser/http_client_exception.dart';
part 'browser/http_client_request.dart';
part 'browser/http_client_response.dart';

/// Determines the default IODriver:
///   * _BrowserIODriver_ in browser (when 'dart:html' is available).
///   * _BaseIODriver_ in Javascript targets such as Node.JS.
///   * Null otherwise (VM, Flutter).
final IODriver defaultIODriver = IODriver(
  parent: null,
  httpOverrides: _BrowserHttpOverrides(),
  platformOverrides: _platformOverridesFromEnvironment(),
  networkInterfaceOverrides: NetworkInterfaceOverrides(),
);

String _operatingSystemFromUserAgent(String userAgent) {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  if (userAgent.contains('iphone') || userAgent.contains('ipad') || userAgent.contains('ipod')) {
    return 'ios';
  }
  if (userAgent.contains('mac os x')) {
    return 'macos';
  }
  if (userAgent.contains('android')) {
    return 'android';
  }
  if (userAgent.contains('croS')) {
    return 'linux';
  }
  return 'windows';
}

PlatformOverrides _platformOverridesFromEnvironment() {
  // Locale
  var locale = 'en';
  final languages = html.window.navigator.languages;
  if (languages.isNotEmpty) {
    locale = languages.first;
  }

  // Operating system
  final userAgent = html.window.navigator.userAgent;
  final operatingSystem = _operatingSystemFromUserAgent(userAgent);

  return PlatformOverrides(
    numberOfProcessors: html.window.navigator.hardwareConcurrency ?? 1,
    localeName: locale,
    operatingSystem: operatingSystem,
  );
}

class _BrowserHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return _BrowserHttpClient();
  }
}
