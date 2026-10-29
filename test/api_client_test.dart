import 'dart:convert';

import 'package:bloodbank/core/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts authenticated callable data to the configured Worker', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          '${ApiClient.baseUrl}/call/createBloodRequest',
        );
        expect(request.headers['authorization'], 'Bearer test-id-token');
        expect(jsonDecode(request.body), {
          'data': {
            'hospitalName': 'City Hospital',
            'hospitalAddress': 'Main Road',
          },
        });
        return http.Response(
          jsonEncode({
            'result': {'id': 'request-1', 'notificationStatus': 'complete'},
          }),
          200,
        );
      }),
      idTokenProvider: () async => 'test-id-token',
    );

    expect(
      await client.call('createBloodRequest', {
        'hospitalName': 'City Hospital',
        'hospitalAddress': 'Main Road',
      }),
      {'id': 'request-1', 'notificationStatus': 'complete'},
    );
  });

  test('converts the Worker structured error to a readable app error', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'permission-denied',
              'message': 'Receiver account required.',
            },
          }),
          403,
        ),
      ),
      idTokenProvider: () async => 'test-id-token',
    );

    await expectLater(
      client.call('createBloodRequest'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Receiver account required.'),
        ),
      ),
    );
  });

  test('rejects invalid workflow names before making a request', () async {
    var requestSent = false;
    final client = ApiClient(
      client: MockClient((_) async {
        requestSent = true;
        return http.Response('{}', 200);
      }),
      idTokenProvider: () async => 'test-id-token',
    );

    await expectLater(client.call('../createBloodRequest'), throwsException);
    expect(requestSent, isFalse);
  });
}
