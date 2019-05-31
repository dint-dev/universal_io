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
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/io.dart';
import 'browser_http_client_exception.dart';
import 'browser_http_client_request.dart';

/// Browser implementation of _dart:io_ [HttpClient].
class BrowserHttpClient extends BaseHttpClient {
  BrowserHttpClient();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (url.host == null) {
      throw ArgumentError.value(url, "url", "Host can't be null");
    }
    var scheme = url.scheme;
    var needsNewUrl = false;
    if (scheme == null) {
      scheme = "https";
      needsNewUrl = true;
    } else {
      switch (scheme) {
        case "":
          scheme = "https";
          needsNewUrl = true;
          break;
        case "http":
          break;
        case "https":
          break;
        default:
          throw ArgumentError.value("Unsupported scheme '$scheme'");
      }
    }
    if (needsNewUrl) {
      url = Uri(
        scheme: scheme,
        userInfo: url.userInfo,
        host: url.host,
        port: url.port,
        query: url.query,
        fragment: url.fragment,
      );
    }
    final request = BrowserHttpClientRequest(method, url, client:this);
    if (userAgent != null) {
      request.headers.add("User-Agent", userAgent);
    }
    return request;
  }

  /// Tells whether the request is cross-origin.
  static bool isCrossOriginUrl(String url, {String origin}) {
    origin ??= html.window.origin;

    // Add '/' so 'http://example.com' and 'http://example.com.other.com'
    // will be different.
    if (!origin.endsWith("/")) {
      origin = "$origin/";
    }

    return !url.startsWith(origin);
  }
}