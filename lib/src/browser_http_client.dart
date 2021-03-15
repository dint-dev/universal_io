export 'browser_http_client_impl_others.dart'
    if (dart.library.html) 'browser_http_client_impl_browser.dart'
    if (dart.library.io) 'browser_http_client_impl_others.dart'
    if (dart.library.js) 'browser_http_client_impl_others.dart';
