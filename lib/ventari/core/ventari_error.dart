/// The shared Ventari error envelope (VJ-130): `{code, message, retryable, requestId}`.
class VentariError implements Exception {
  const VentariError({
    required this.code,
    required this.message,
    required this.retryable,
    this.statusCode,
    this.requestId,
  });

  final String code;
  final String message;

  /// True only when the server says the same request may be repeated safely.
  final bool retryable;
  final int? statusCode;
  final String? requestId;

  /// Builds an error from a BFF response. Unknown shapes fail closed as a
  /// non-retryable error rather than being treated as success.
  factory VentariError.fromResponse(int statusCode, Object? body, {String? requestId}) {
    if (body is Map<String, dynamic>) {
      final code = body['code'] ?? body['statusMessage'];
      return VentariError(
        code: code is String && code.isNotEmpty ? code : 'HTTP_$statusCode',
        message: body['message'] is String ? body['message'] as String : 'Request failed',
        retryable: body['retryable'] == true || statusCode == 503,
        statusCode: statusCode,
        requestId: body['requestId'] is String ? body['requestId'] as String : requestId,
      );
    }
    return VentariError(
      code: 'HTTP_$statusCode',
      message: 'Request failed',
      retryable: statusCode == 503,
      statusCode: statusCode,
      requestId: requestId,
    );
  }

  static const invalidResponse = VentariError(
    code: 'INVALID_RESPONSE',
    message: 'The service returned an unexpected response',
    retryable: false,
  );

  @override
  String toString() => 'VentariError($code, status: $statusCode, retryable: $retryable)';
}
