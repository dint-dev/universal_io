library nodejs_io;

import 'package:universal_io/driver.dart';
import 'src/http_client.dart';
import 'src/http_server.dart';

const nodeJsIODriver = _NodeJsIODriver();

class _NodeJsIODriver extends IODriver {
  const _NodeJsIODriver()
      : super(
          httpClientDriver: const NodeJsHttpClientDriver(),
          httpServerDriver: const NodeJsHttpServerDriver(),
        );
}
