part of universal_io.http;

class _HttpClient implements HttpClient {
  @override
  Duration idleTimeout;

  @override
  Duration connectionTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  bool autoUncompress;

  @override
  String userAgent;

  _HttpClient(SecurityContext context);

  @override
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)) {
    throw UnimplementedError();
  }

  @override
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)) {
    throw UnimplementedError();
  }

  @override
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)) {
    throw UnimplementedError();
  }

  @override
  set findProxy(String f(Uri url)) {
    throw UnimplementedError();
  }

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return open("DELETE", host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return openUrl("DELETE", url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return open("GET", host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return openUrl("GET", url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return open("HEAD", host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return openUrl("HEAD", url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    String query;
    final i = path.indexOf("?");
    if (i >= 0) {
      query = path.substring(i + 1);
      path = path.substring(0, i);
    }
    return openUrl(
        method,
        Uri(
          scheme: "https",
          host: host,
          port: port,
          path: path,
          query: query,
          fragment: null,
        ));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
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
    return Future<HttpClientRequest>.value(
        _HttpClientRequest._(this, method, url));
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return open("PATCH", host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl("PATCH", url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return open("POST", host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return openUrl("POST", url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return open("PUT", host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return openUrl("PUT", url);
  }
}

class _HttpClientRequest extends HttpClientRequest implements IOSink {
  final _HttpClient _client;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _HttpHeaders("1.0");

  final Int8Buffer _buffer = Int8Buffer();

  final Completer<HttpClientResponse> _completer =
      Completer<HttpClientResponse>();
  bool _closed = false;
  Future _requestBodyFuture;

  @override
  final List<Cookie> cookies = <Cookie>[];

  _HttpClientRequest._(this._client, this.method, this.uri);

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  Future<HttpClientResponse> get done {
    return _completer.future;
  }

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {
    throw StateError("IOSink encoding is not mutable");
  }

  @override
  void add(List<int> event) {
    if (_requestBodyFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    _buffer.addAll(event);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (_closed) {
      throw StateError("HTTP request is closed already");
    }
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    if (_requestBodyFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    _requestBodyFuture = stream.listen((item) {
      _buffer.addAll(item);
    }, onError: (error) {
      addError(error);
    }, cancelOnError: true).asFuture(null);
    return _requestBodyFuture;
  }

  @override
  Future<HttpClientResponse> close() {
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    if (!_completer.isCompleted) {
      if (_requestBodyFuture != null) {
        _requestBodyFuture.then((_) {
          return _send();
        });
      } else {
        _send();
      }
    }
    return _completer.future;
  }

  void _send() {
    try {
      final xhr = html.HttpRequest();
      xhr.open(method, uri.toString(), async: true);
      xhr.responseType = 'blob';
      xhr.withCredentials = true;
      headers.forEach((name, values) {
        for (var value in values) {
          xhr.setRequestHeader(name, value);
        }
      });

      var completer = this._completer;
      xhr.onLoad.first.then((_) {
        // TODO(nweiz): Set the response type to "arraybuffer" when issue 18542
        // is fixed.
        var blob = xhr.response == null ? html.Blob([]) : xhr.response;
        var reader = html.FileReader();

        reader.onLoad.first.then((_) {
          var body = reader.result as Uint8List;
          completer.complete(_HttpClientResponse._(
            _client,
            method,
            uri,
            headers,
            xhr,
            body,
          ));
        });

        reader.onError.first.then((error) {
          completer.completeError(
              SocketException("${error.toString()}. Request: '$method $uri'"),
              StackTrace.current);
        });

        reader.readAsArrayBuffer(blob);
      });

      xhr.onError.first.then((_) {
        // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
        // specific information about the error itself.
        completer.completeError(
            SocketException("XMLHttpRequest error. Request: '$method $uri'"),
            StackTrace.current);
      });
      xhr.send(Uint8List.fromList(_buffer));
    } catch (e) {
      _completer.completeError(e);
    }
  }

  @override
  Future<void> flush() {
    return Future<void>.value();
  }

  @override
  void write(Object obj) {
    String string = '$obj';
    if (string.isEmpty) return;
    add(utf8.encode(string));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object object = ""]) {
    write(object);
    write("\n");
  }
}

class _HttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final HttpClient _client;
  final String _requestMethod;
  final HttpHeaders _requestHeaders;
  final html.HttpRequest _response;
  final List<int> _responseData;

  @override
  final HttpHeaders headers = _HttpHeaders("1.0");

  _HttpClientResponse._(this._client, this._requestMethod, Uri requestUri,
      this._requestHeaders, this._response, this._responseData)
      : assert(_response != null) {
    final headers = this.headers;
    _response.responseHeaders.forEach((k, v) {
      headers.add(k, v);
    });
  }

  @override
  X509Certificate get certificate => throw UnimplementedError();

  @override
  HttpConnectionInfo get connectionInfo {
    throw UnimplementedError();
  }

  @override
  int get contentLength {
    throw UnimplementedError();
  }

  @override
  List<Cookie> get cookies {
    final cookies = <Cookie>[];
    for (String value in this.headers[HttpHeaders.setCookieHeader]) {
      cookies.add(Cookie.fromSetCookieValue(value));
    }
    return cookies;
  }

  @override
  bool get isRedirect =>
      HttpStatus.temporaryRedirect == statusCode ||
      HttpStatus.movedPermanently == statusCode;

  @override
  bool get persistentConnection {
    throw UnimplementedError();
  }

  @override
  String get reasonPhrase {
    return _response.statusText;
  }

  @override
  List<RedirectInfo> get redirects {
    throw UnimplementedError();
  }

  int get statusCode => _response.status;

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return Stream.fromIterable([this._responseData]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]) {
    final newUrl =
        url ?? Uri.parse(this.headers.value(HttpHeaders.locationHeader));
    return _client.openUrl(method ?? _requestMethod, newUrl).then((newRequest) {
      _requestHeaders.forEach((name, value) {
        newRequest.headers.add(name, value);
      });
      newRequest.followRedirects = true;
      return newRequest.close();
    });
  }
}
