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

// Annotate as 'internal' so developers don't accidentally import this.
@internal
library universal_io.choose.browser;

import 'dart:html' as html;

import 'package:meta/meta.dart';

import 'browser/http_client.dart';
import 'io_impl_js.dart';

String get locale {
  final languages = html.window.navigator.languages;
  if (languages!=null && languages.isNotEmpty) {
    return languages.first;
  }
  return 'en-US';
}

String get platform {
  final s = html.window.navigator.platform?.toLowerCase() ?? html.window.navigator.userAgent;
  if (s.contains('iphone') ||
      s.contains('ipad') ||
      s.contains('ipod')) {
    return 'ios';
  }
  if (s.contains('mac')) {
    return 'macos';
  }
  if (s.contains('android')) {
    return 'android';
  }
  if (s.contains('linux')) {
    return 'linux';
  }
  return 'windows';
}

HttpClient newHttpClient() {
  return BrowserHttpClient();
}
