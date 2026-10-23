import 'dart:convert';

import 'package:dio/dio.dart';

/// Minimal HTTP seam so Ventari clients are testable without a network.
class VentariResponse {
  const VentariResponse(this.statusCode, this.body, {this.headers = const {}});

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;
}

abstract class VentariTransport {
  Future<VentariResponse> send(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
  });
}

/// Production transport on dio (already a dependency of the fork).
class DioTransport implements VentariTransport {
  DioTransport({Dio? dio, Duration timeout = const Duration(seconds: 15)})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: timeout,
              receiveTimeout: timeout,
              sendTimeout: timeout,
              // Status handling belongs to the Ventari clients.
              validateStatus: (_) => true,
              responseType: ResponseType.plain,
              followRedirects: false,
            ));

  final Dio _dio;

  @override
  Future<VentariResponse> send(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
  }) async {
    final response = await _dio.requestUri<String>(
      uri,
      data: body == null ? null : jsonEncode(body),
      options: Options(method: method, headers: {
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...headers,
      }),
    );
    Object? decoded;
    final text = response.data;
    if (text != null && text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        decoded = null;
      }
    }
    return VentariResponse(
      response.statusCode ?? 0,
      decoded,
      headers: {
        for (final entry in response.headers.map.entries) entry.key.toLowerCase(): entry.value.join(','),
      },
    );
  }
}
