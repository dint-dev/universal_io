// Copy-pasted from:
// https://github.com/dart-gde/chrome.dart/
//
// The original license was:
//
//  The BSD 2-Clause License
//  http://www.opensource.org/licenses/bsd-license.php
//
//  Copyright (c) 2012, The chrome_vm.dart project authors
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

import 'dart:js';
import 'dart:typed_data' as typed_data;

class ActionsCallback {
  ActionsCallback.fromProxy(JsObject jsProxy);
}

class ArrayBuffer extends ChromeObject {
  ArrayBuffer();

  factory ArrayBuffer.fromBytes(List<int> data) {
    var uint8Array = JsObject(context['Uint8Array'], [JsArray.from(data)]);

    return ArrayBuffer.fromProxy(uint8Array['buffer']);
  }

  factory ArrayBuffer.fromProxy(/*JsObject*/ jsProxy) {
    // TODO: investigate and fix
//    if (jsProxy is typed_data.Uint8List) {
//      return new _Uint8ListArrayBuffer(jsProxy);
//    } else {
    return ArrayBuffer._proxy(jsProxy);
//    }
  }

  factory ArrayBuffer.fromString(String str) {
    var uint8Array =
        JsObject(context['Uint8Array'], [JsArray.from(str.codeUnits)]);

    return ArrayBuffer.fromProxy(uint8Array['buffer']);
  }

  ArrayBuffer._proxy(jsProxy) : super.fromProxy(jsProxy);

  List<int> getBytes() {
    if (jsProxy is typed_data.Uint8List) {
      return jsProxy as typed_data.Uint8List;
    } else {
      var int8View = JsObject(context['Uint8Array'], [jsProxy]);

      List<int> result = List<int>(int8View['length']);

      // TODO: this is _very_ slow
      // can we instead do: jsArray = Array.apply([], int8View);
      for (int i = 0; i < result.length; i++) {
        result[i] = int8View[i];
      }

      return result;
    }
  }

  static ArrayBuffer create(/*JsObject*/ jsProxy) =>
      ArrayBuffer.fromProxy(jsProxy);
}

class Bounds extends ChromeObject {
  Bounds();

  Bounds.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  int get height => jsProxy['height'];

  set height(int value) => jsProxy['height'] = value;

  int get left => jsProxy['left'];

  set left(int value) => jsProxy['left'] = value;

  int get top => jsProxy['top'];

  set top(int value) => jsProxy['top'] = value;

  int get width => jsProxy['width'];

  set width(int value) => jsProxy['width'] = value;

  static Bounds create(JsObject jsProxy) =>
      jsProxy == null ? null : Bounds.fromProxy(jsProxy);
}

// This is shared in common by app.window and system.display.
class CapabilitiesCallback {
  CapabilitiesCallback.fromProxy(JsObject jsProxy);
}

class CertificatesCallback {
  CertificatesCallback.fromProxy(JsObject jsProxy);
}

/// A common super class for the Chrome APIs.
abstract class ChromeApi {
  /// Returns true if the API is available. The common causes of an API not being
  /// avilable are:
  ///
  ///  * a permission is missing in the application's manifest.json file
  ///  * the API is defined on a newer version of Chrome then the current runtime
  bool get available;
}

// TODO: See ArrayBuffer.fromProxy.
//class _Uint8ListArrayBuffer implements ArrayBuffer {
//  List<int> _bytes;
//  JsObject _jsProxy;
//
//  _Uint8ListArrayBuffer( typed_data.Uint8List list) {
//    _bytes = list.toList();
//  }
//
//  List<int> getBytes() => _bytes;
//
//  JsObject get jsProxy {
//    if (_jsProxy == null) {
//      _jsProxy = new ArrayBuffer.fromBytes(_bytes).jsProxy;
//    }
//
//    return _jsProxy;
//  }
//
//  JsObject toJs() => jsProxy;
//}

// TODO: this is a hack, to eliminate analysis warnings. remove as soon as possible
/// The abstract superclass of Chrome enums.
abstract class ChromeEnum {
  final String value;

  const ChromeEnum(this.value);

  String toString() => value;
}

// TODO: this is a hack, to eliminate analysis warnings. remove as soon as possible
/// The abstract superclass of objects that can hold [JsObject] proxies.
class ChromeObject {
  final dynamic jsProxy;

  /// Create a new instance of a `ChromeObject`, which creates and delegates to
  /// a JsObject proxy.
  ChromeObject() : jsProxy = JsObject(context['Object']);

  /// Create a new instance of a `ChromeObject`, which delegates to the given
  /// JsObject proxy.
  ChromeObject.fromProxy(this.jsProxy);

  JsObject toJs() => jsProxy;

  String toString() => jsProxy.toString();
}

class Date extends ChromeObject {
  Date.fromProxy(jsProxy) : super.fromProxy(jsProxy);
}

class DeviceCallback {
  DeviceCallback.fromProxy(JsObject jsProxy);
}

class EntriesCallback {
  EntriesCallback.fromProxy(JsObject jsProxy);
}

class FileDataCallback {
  FileDataCallback.fromProxy(JsObject jsProxy);
}

class LocalMediaStream extends ChromeObject {
  LocalMediaStream();

  LocalMediaStream.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  static LocalMediaStream create(JsObject jsProxy) =>
      LocalMediaStream.fromProxy(jsProxy);
}

class MetadataCallback {
  MetadataCallback.fromProxy(JsObject jsProxy);
}

class PrintCallback {
  PrintCallback.fromProxy(JsObject jsProxy);
}

class PrinterInfoCallback {
  PrinterInfoCallback.fromProxy(JsObject jsProxy);
}

class PrintersCallback {
  PrintersCallback.fromProxy(JsObject jsProxy);
}

class ProviderErrorCallback {
  ProviderErrorCallback.fromProxy(JsObject jsProxy);
}

class ProviderSuccessCallback {
  ProviderSuccessCallback.fromProxy(JsObject jsProxy);
}

class RequestPinCallback {
  RequestPinCallback.fromProxy(JsObject jsProxy);
}

class SignCallback {
  SignCallback.fromProxy(JsObject jsProxy);
}

class StopPinRequestCallback {
  StopPinRequestCallback.fromProxy(JsObject jsProxy);
}

class SubtleCrypto {
  SubtleCrypto.fromProxy(JsObject jsProxy);
}

// TODO:
class SuggestFilenameCallback {
  SuggestFilenameCallback.fromProxy(JsObject jsProxy);
}
