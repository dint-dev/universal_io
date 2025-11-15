import 'dart:js_interop';

@JS()
external Navigator get navigator;

@JS('origin')
external String get windowOrigin;

extension type Navigator._(JSObject _) implements JSObject {
  external JSArray<JSString> get languages;
  external String get userAgent;
}

@JS('XMLHttpRequest')
extension type Xhr._(JSObject _) implements JSObject {
  static const readyStateUnsent = 0;
  static const readyStateOpened = 1;
  static const readyStateHeadersReceived = 2;
  static const readyStateLoading = 3;
  static const readyStateDone = 4;

  external String responseType;

  external int timeout;

  external bool withCredentials;

  @JS('onreadystatechange')
  external JSFunction onReadyStateChange;

  external Xhr();

  external int get readyState;

  external JSAny get response;

  external JSString getAllResponseHeaders();

  external String get responseText;

  external int? get status;

  external String? get statusText;

  external void abort();

  external void open(
    String method,
    String url, [
    bool async,
    String? user,
    String? password,
  ]);

  external void send([JSAny? body]);

  external void setRequestHeader(String header, String value);
}

extension type XhrHeaders._(JSObject _) implements JSObject {
  external JSString operator [](JSString key);
}
