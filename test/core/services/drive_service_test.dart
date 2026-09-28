import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:key_budget/core/services/drive_service.dart';

class _RecordingClient extends http.BaseClient {
  bool closed = false;
  String? authorization;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorization = request.headers['Authorization'];
    return http.StreamedResponse(Stream.value(<int>[]), 200);
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  test(
    'GoogleAuthClient forwards authorization and closes its HTTP client',
    () async {
      final delegate = _RecordingClient();
      final client = GoogleAuthClient({
        'Authorization': 'Bearer token',
      }, client: delegate);

      await client.send(http.Request('GET', Uri.https('example.com', '/')));
      client.close();

      expect(delegate.authorization, 'Bearer token');
      expect(delegate.closed, isTrue);
    },
  );
}
