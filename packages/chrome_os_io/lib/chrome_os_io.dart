/// Support for 'dart:io' sockets in Chrome OS Apps.
library chrome_os_io;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';

import 'src/third-party/chrome/chrome_common.dart' as chrome;
import 'src/third-party/chrome/chrome_sockets.dart' as chrome;

part 'src/io_driver.dart';
part 'src/raw_datagram_socket.dart';
part 'src/raw_server_socket.dart';
part 'src/raw_socket.dart';
