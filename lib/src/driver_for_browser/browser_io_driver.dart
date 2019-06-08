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

import 'dart:html' as html;

import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/io.dart';

import 'browser_http_client.dart';

/// Browser implementation of [IODriver].
///
/// This class is automatically used by 'package:universal_io/io.dart' when
/// you target browsers with Dart2js.
class BrowserIODriver extends BaseIODriver {
  BrowserIODriver(
      {FileSystemDriver fileSystemDriver,
      InternetAddressDriver internetAddressDriver,
      HttpClientDriver httpClientDriver = const BrowserHttpClientDriver(),
      HttpServerDriver httpServerDriver,
      PlatformDriver platformDriver,
      ProcessDriver processDriver,
      SocketsDriver socketsDriver})
      : super(
          fileSystemDriver: fileSystemDriver,
          internetAddressDriver: internetAddressDriver,
          httpClientDriver: httpClientDriver,
          httpServerDriver: httpServerDriver,
          platformDriver: platformDriver ?? platformDriverFromEnvironment(),
          processDriver: processDriver,
          socketsDriver: socketsDriver,
        );

  /// Sets [BrowserIODriver] as the default driver.
  static void enable() {
    IODriver.zoneLocal.freezeDefaultValue(BrowserIODriver());
  }
}

PlatformDriver platformDriverFromEnvironment() {
  // Locale
  String locale = "en";
  final languages = html.window.navigator.languages;
  if (languages.isNotEmpty) {
    locale = languages.first;
  }

  // Operating system
  final userAgent = html.window.navigator.userAgent;
  final operatingSystem = operatingSystemFromUserAgent(userAgent);

  return PlatformDriver(
    numberOfProcessors: html.window.navigator.hardwareConcurrency ?? 1,
    localeName: locale,
    operatingSystem: operatingSystem,
  );
}

String operatingSystemFromUserAgent(String userAgent) {
  final userAgent = html.window.navigator.userAgent;
  if (userAgent.contains("Mac OS X")) {
    return "macos";
  }
  if (userAgent.contains("CrOS")) {
    return "linux";
  }
  if (userAgent.contains("Android")) {
    return "android";
  }
  if (userAgent.contains("iPhone")) {
    return "ios";
  }
  return "windows";
}

class BrowserHttpClientDriver extends HttpClientDriver {
  const BrowserHttpClientDriver();

  @override
  HttpClient newHttpClient({SecurityContext context}) {
    return BrowserHttpClient();
  }
}
