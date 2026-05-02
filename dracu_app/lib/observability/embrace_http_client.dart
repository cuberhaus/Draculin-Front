/// `http.Client` wrapper that injects an `X-Embrace-Session-Id`
/// header on every outgoing request for cross-tier correlation.
///
/// The Embrace SDK already ships its own [EmbraceHttpClient] (same
/// name, exported from `package:embrace`) which auto-records every
/// request as a network event in the active session. We compose
/// that wrapper as the inner client here and add ONE behaviour on
/// top: header injection before the SDK's recording fires. That
/// way the request payload the SDK captures already contains the
/// session ID header — making the on-device record consistent with
/// what the (currently uninstrumented) Django backend receives.
///
/// We don't use Dio (which Embrace also offers an interceptor for
/// via `embrace_dio`) because the Draculin app already standardised
/// on `package:http`. Wrapping `http.BaseClient` keeps the existing
/// call sites idiomatic — the only diff is constructing
/// `DracuHttpClient()` instead of using the bare top-level
/// `http.get` / `http.post` shortcuts.
///
/// Behavioural contract:
/// * Telemetry is best-effort: any failure inside the
///   header-injection path is swallowed so it cannot affect the
///   actual HTTP outcome.
/// * The session ID is fetched on EVERY request rather than
///   cached, because Embrace can mint a new session mid-app-life
///   (background → foreground after >5 min) and stale headers
///   would mis-correlate the event on the backend.
library;

import 'dart:async';
import 'dart:convert';

// The SDK ships its own EmbraceHttpClient — alias it to avoid a
// name collision with our DracuHttpClient below.
import 'package:embrace/embrace.dart' show EmbraceHttpClient;
import 'package:http/http.dart' as http;

import 'embrace.dart';

/// Header name shared with the (currently uninstrumented) Django
/// backend. The convention is committed so a future
/// "OTel-on-Django + Embrace-on-mobile correlation" experiment
/// only needs to add a Django middleware that reads it. See
/// `Draculin-Backend/observability/README.md`.
const String embraceSessionHeader = 'X-Embrace-Session-Id';

class DracuHttpClient extends http.BaseClient {
  DracuHttpClient({http.Client? inner})
      : _inner = EmbraceHttpClient(innerClient: inner ?? http.Client());

  /// Composed inner: SDK's EmbraceHttpClient (auto-recording)
  /// wrapping a plain http.Client (the actual transport).
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Inject the session ID header BEFORE delegating, so the SDK's
    // EmbraceHttpClient sees the header on the request as it
    // records the network event. `getCurrentSessionId` is async
    // because it crosses the iOS native bridge — we must await
    // before the request goes out.
    try {
      final sessionId = await DracuObs.currentSessionId();
      if (sessionId != null && sessionId.isNotEmpty) {
        request.headers[embraceSessionHeader] = sessionId;
      }
    } catch (_) {
      // Telemetry must never break the request path.
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Convenience helper for the common case of "POST a small JSON
/// body and parse the JSON response". Saves a few lines per call
/// site if you don't already have json encoding/decoding logic.
Future<Map<String, dynamic>> postJson(
  http.Client client,
  Uri uri, {
  required Map<String, dynamic> body,
}) async {
  final response = await client.post(
    uri,
    body: jsonEncode(body),
    headers: const {'Content-Type': 'application/json'},
  );
  if (response.statusCode >= 400) {
    throw http.ClientException(
      'POST $uri failed with status ${response.statusCode}',
      uri,
    );
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
