// MIT License
//
// Copyright (c) 2018 dart-universal_io authors.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';

/// Enables zone-scoped values.
class ZoneLocal<T> {
  /// Default value.
  T defaultValue;

  bool _hasForked = false;

  /// Key used with [Zone.fork].
  final Object zoneValueKey = Object();

  ZoneLocal({this.defaultValue});

  /// Returns current value.
  ///
  /// If values of [Zone.current] or its ancestor is not a return value of
  /// [forkWithValue], [defaultValue] will be returned.
  T get current {
    if (_hasForked) {
      final value = Zone.current[zoneValueKey];
      if (value != null) {
        return value;
      }
    }
    return defaultValue;
  }

  /// Creates a new zone with [Zone.fork].
  Zone forkWithValue(T value) {
    _hasForked = true;
    return Zone.current.fork(zoneValues: {
      zoneValueKey: value,
    });
  }
}
