// Copy-pasted from:
// https://github.com/dart-gde/chrome.dart/
//
// The original license was:
//
//  The BSD 2-Clause License
//  http://www.opensource.org/licenses/bsd-license.php
//
//  Copyright (c) 2012, The chrome.dart project authors
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//      either expressed or implied, of the FreeBSD Project.

library chrome.src.common;

import 'dart:convert';

import 'dart:async';
export 'dart:async';

import 'dart:js';
export 'dart:js';

import 'chrome_common_exp.dart';
export 'chrome_common_exp.dart';

final JsObject _jsJSON = context['JSON'];

final JsObject chrome = context['chrome'];
final JsObject _runtime = context['chrome']['runtime'];

String get lastError {
  JsObject error = _runtime['lastError'];
  return error != null ? error['message'] : null;
}

List listify(JsObject obj, [Function transformer]) {
  if (obj == null) {
    return null;
  } else {
    List l = List(obj['length']);

    for (int i = 0; i < l.length; i++) {
      if (transformer != null) {
        l[i] = transformer(obj[i]);
      } else {
        l[i] = obj[i];
      }
    }

    return l;
  }
}

Map mapify(JsObject obj) {
  if (obj == null) return null;
  return json.decode(_jsJSON.callMethod('stringify', [obj]));
}

dynamic jsify(dynamic obj) {
  if (obj == null || obj is num || obj is String) {
    return obj;
  } else if (obj is ChromeObject) {
    return obj.jsProxy;
  } else if (obj is ChromeEnum) {
    return obj.value;
  } else if (obj is Map) {
    // Do a deep convert.
    Map m = {};
    for (var key in obj.keys) {
      m[key] = jsify(obj[key]);
    }
    return JsObject.jsify(m);
  } else if (obj is Iterable) {
    // Do a deep convert.
    return JsArray.from(obj).map(jsify);
  } else {
    return obj;
  }
}

dynamic selfConverter(var obj) => obj;

/// An object for handling completion callbacks that are common in the chrome.*
/// APIs.
class ChromeCompleter<T> {
  final Completer<T> _completer = Completer();
  Function _callback;

  ChromeCompleter.noArgs() {
    this._callback = ([_]) {
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        _completer.complete();
      }
    };
  }

  ChromeCompleter.oneArg([Function transformer]) {
    this._callback = ([arg1]) {
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        if (transformer != null) {
          arg1 = transformer(arg1);
        }
        _completer.complete(arg1);
      }
    };
  }

  ChromeCompleter.twoArgs(Function transformer) {
    this._callback = ([arg1, arg2]) {
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        _completer.complete(transformer(arg1, arg2));
      }
    };
  }

  Future<T> get future => _completer.future;

  Function get callback => _callback;
}

class ChromeStreamController<T> {
  JsObject get _api => _apiProvider();
  final Function _apiProvider;
  final String _eventName;
  StreamController<T> _controller = StreamController<T>.broadcast();
  bool _handlerAdded = false;
  Function _listener;

  ChromeStreamController.noArgs(this._apiProvider, this._eventName) {
    _controller = StreamController<T>.broadcast(
        onListen: _ensureHandlerAdded, onCancel: _removeHandler);
    _listener = () {
      _controller.add(null);
    };
  }

  ChromeStreamController.oneArg(
      this._apiProvider, this._eventName, Function transformer,
      [returnVal]) {
    _controller = StreamController<T>.broadcast(
        onListen: _ensureHandlerAdded, onCancel: _removeHandler);
    _listener = ([arg1]) {
      _controller.add(transformer(arg1));
      return returnVal;
    };
  }

  ChromeStreamController.twoArgs(
      this._apiProvider, this._eventName, Function transformer,
      [returnVal]) {
    _controller = StreamController<T>.broadcast(
        onListen: _ensureHandlerAdded, onCancel: _removeHandler);
    _listener = ([arg1, arg2]) {
      _controller.add(transformer(arg1, arg2));
      return returnVal;
    };
  }

  ChromeStreamController.threeArgs(
      this._apiProvider, this._eventName, Function transformer,
      [returnVal]) {
    _controller = StreamController<T>.broadcast(
        onListen: _ensureHandlerAdded, onCancel: _removeHandler);
    _listener = ([arg1, arg2, arg3]) {
      _controller.add(transformer(arg1, arg2, arg3));
      return returnVal;
    };
  }

  bool get hasListener => _controller.hasListener;

  Stream<T> get stream {
    return _controller.stream;
  }

  void _ensureHandlerAdded() {
    if (!_handlerAdded) {
      // TODO: Workaround an issue where the event objects are not properly
      // proxied in M35 and after.
      var jsEvent = _api[_eventName];
      JsObject event =
          (jsEvent is JsObject ? jsEvent : JsObject.fromBrowserObject(jsEvent));
      event.callMethod('addListener', [_listener]);
      _handlerAdded = true;
    }
  }

  void _removeHandler() {
    if (_handlerAdded) {
      // TODO: Workaround an issue where the event objects are not properly
      // proxied in M35 and after.
      var jsEvent = _api[_eventName];
      JsObject event =
          (jsEvent is JsObject ? jsEvent : JsObject.fromBrowserObject(jsEvent));
      event.callMethod('removeListener', [_listener]);
      _handlerAdded = false;
    }
  }
}
