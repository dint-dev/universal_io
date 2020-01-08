import 'package:universal_io/prefer_universal/io.dart';

var testSuitePath = "test/src/test_suite";

SecurityContext localHostSecurityContext() {
  final securityContext = SecurityContext();
  securityContext.useCertificateChain(
    "$testSuitePath/localhost.crt",
  );
  securityContext.usePrivateKey(
    "$testSuitePath/localhost.key",
  );
  return securityContext;
}
