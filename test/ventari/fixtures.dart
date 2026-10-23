import 'dart:convert';
import 'dart:io';

import 'package:bagisto_flutter/ventari/ventari.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/ventari/$name').readAsStringSync()) as Map<String, dynamic>;

/// Scripted transport: returns queued responses and records requests.
class FakeTransport implements VentariTransport {
  FakeTransport(this.responses);

  final List<Object> responses; // VentariResponse or an Exception to throw
  final List<({String method, Uri uri, Map<String, String> headers})> requests = [];

  @override
  Future<VentariResponse> send(String method, Uri uri, {Map<String, String> headers = const {}, Object? body}) async {
    requests.add((method: method, uri: uri, headers: headers));
    final next = responses.removeAt(0);
    if (next is Exception) throw next;
    return next as VentariResponse;
  }
}

final testConfig = VentariConfig.parse('https://api.example.com', '1.2.3');
