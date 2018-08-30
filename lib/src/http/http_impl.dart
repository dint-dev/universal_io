part of universal_io.http;

class _AuthenticationScheme {
  final String _scheme;

  static const UNKNOWN = const _AuthenticationScheme("Unknown");
  static const BASIC = const _AuthenticationScheme("Basic");
  static const DIGEST = const _AuthenticationScheme("Digest");

  const _AuthenticationScheme(this._scheme);

  factory _AuthenticationScheme.fromString(String scheme) {
    if (scheme.toLowerCase() == "basic") return BASIC;
    if (scheme.toLowerCase() == "digest") return DIGEST;
    return UNKNOWN;
  }

  String toString() => _scheme;
}

abstract class _Credentials {
  _HttpClientCredentials credentials;
  String realm;
  bool used = false;

  // Digest specific fields.
  String ha1;
  String nonce;
  String algorithm;
  String qop;
  int nonceCount;

  _Credentials(this.credentials, this.realm) {
    if (credentials.scheme == _AuthenticationScheme.DIGEST) {
      // Calculate the H(A1) value once. There is no mentioning of
      // username/password encoding in RFC 2617. However there is an
      // open draft for adding an additional accept-charset parameter to
      // the WWW-Authenticate and Proxy-Authenticate headers, see
      // http://tools.ietf.org/html/draft-reschke-basicauth-enc-06. For
      // now always use UTF-8 encoding.
      _HttpClientDigestCredentials creds = credentials;
      var hasher = new _MD5()
        ..add(utf8.encode(creds.username))
        ..add([_CharCode.COLON])
        ..add(realm.codeUnits)
        ..add([_CharCode.COLON])
        ..add(utf8.encode(creds.password));
      ha1 = _CryptoUtils.bytesToHex(hasher.close());
    }
  }

  _AuthenticationScheme get scheme => credentials.scheme;

  void authorize(HttpClientRequest request);
}

abstract class _HttpClientCredentials implements HttpClientCredentials {
  _AuthenticationScheme get scheme;
  void authorize(_Credentials credentials, HttpClientRequest request);
}

class _HttpClientBasicCredentials extends _HttpClientCredentials
    implements HttpClientBasicCredentials {
  String username;
  String password;

  _HttpClientBasicCredentials(this.username, this.password);

  _AuthenticationScheme get scheme => _AuthenticationScheme.BASIC;

  String authorization() {
    // There is no mentioning of username/password encoding in RFC
    // 2617. However there is an open draft for adding an additional
    // accept-charset parameter to the WWW-Authenticate and
    // Proxy-Authenticate headers, see
    // http://tools.ietf.org/html/draft-reschke-basicauth-enc-06. For
    // now always use UTF-8 encoding.
    String auth =
        _CryptoUtils.bytesToBase64(utf8.encode("$username:$password"));
    return "Basic $auth";
  }

  void authorize(_Credentials _, HttpClientRequest request) {
    request.headers.set(HttpHeaders.authorizationHeader, authorization());
  }
}

class _HttpClientDigestCredentials extends _HttpClientCredentials
    implements HttpClientDigestCredentials {
  String username;
  String password;

  _HttpClientDigestCredentials(this.username, this.password);

  _AuthenticationScheme get scheme => _AuthenticationScheme.DIGEST;

  String authorization(_Credentials credentials, _HttpClientRequest request) {
    String requestUri = request.uri.toString();
    _MD5 hasher = new _MD5()
      ..add(request.method.codeUnits)
      ..add([_CharCode.COLON])
      ..add(requestUri.codeUnits);
    var ha2 = _CryptoUtils.bytesToHex(hasher.close());

    String qop;
    String cnonce;
    String nc;
    hasher = new _MD5()..add(credentials.ha1.codeUnits)..add([_CharCode.COLON]);
    if (credentials.qop == "auth") {
      qop = credentials.qop;
      cnonce = _CryptoUtils.bytesToHex(_CryptoUtils.getRandomBytes(4));
      ++credentials.nonceCount;
      nc = credentials.nonceCount.toRadixString(16);
      nc = "00000000".substring(0, 8 - nc.length + 1) + nc;
      hasher
        ..add(credentials.nonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(nc.codeUnits)
        ..add([_CharCode.COLON])
        ..add(cnonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(credentials.qop.codeUnits)
        ..add([_CharCode.COLON])
        ..add(ha2.codeUnits);
    } else {
      hasher
        ..add(credentials.nonce.codeUnits)
        ..add([_CharCode.COLON])
        ..add(ha2.codeUnits);
    }
    var response = _CryptoUtils.bytesToHex(hasher.close());

    StringBuffer buffer = new StringBuffer()
      ..write('Digest ')
      ..write('username="$username"')
      ..write(', realm="${credentials.realm}"')
      ..write(', nonce="${credentials.nonce}"')
      ..write(', uri="$requestUri"')
      ..write(', algorithm="${credentials.algorithm}"');
    if (qop == "auth") {
      buffer
        ..write(', qop="$qop"')
        ..write(', cnonce="$cnonce"')
        ..write(', nc="$nc"');
    }
    buffer.write(', response="$response"');
    return buffer.toString();
  }

  void authorize(_Credentials credentials, HttpClientRequest request) {
    request.headers.set(
        HttpHeaders.authorizationHeader, authorization(credentials, request));
  }
}
