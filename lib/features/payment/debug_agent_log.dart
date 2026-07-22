import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-mode NDJSON logger for subscription verify investigation (session 4c8dd8).
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const <String, Object?>{},
}) {
  // #region agent log
  final Map<String, Object?> payload = <String, Object?>{
    'sessionId': '4c8dd8',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final String line = jsonEncode(payload);
  debugPrint('DBG4c8dd8 $line');
  try {
    File(
      '/Users/babatundetosin/StudioProjects/naijaSingles/.cursor/debug-4c8dd8.log',
    ).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } on Object {
    // Device / sandbox may not reach host path.
  }
  for (final String host in <String>['127.0.0.1', '192.168.4.42']) {
    HttpClient()
        .postUrl(
          Uri.parse(
            'http://$host:7394/ingest/4ae06386-9a4e-409c-a35a-fb9340702beb',
          ),
        )
        .then((HttpClientRequest req) {
          req.headers.set('Content-Type', 'application/json');
          req.headers.set('X-Debug-Session-Id', '4c8dd8');
          req.add(utf8.encode(line));
          return req.close();
        })
        .then((HttpClientResponse res) => res.drain<void>())
        .catchError((Object _) {});
  }
  // #endregion
}
