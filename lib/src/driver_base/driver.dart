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
import 'package:universal_io/driver_base.dart';

class BaseIODriver extends IODriver {
  const BaseIODriver({
    FileSystemDriver fileSystemDriver,
    InternetAddressDriver internetAddressDriver,
    HttpClientDriver httpClientDriver,
    HttpServerDriver httpServerDriver,
    PlatformDriver platformDriver,
    ProcessDriver processDriver,
    SocketsDriver socketsDriver = const BaseSocketsDriver(),
  }) : super(
          fileSystemDriver: fileSystemDriver,
          internetAddressDriver: internetAddressDriver,
          httpClientDriver: httpClientDriver,
          httpServerDriver: httpServerDriver,
          platformDriver: platformDriver,
          processDriver: processDriver,
          socketsDriver: socketsDriver,
        );
}
