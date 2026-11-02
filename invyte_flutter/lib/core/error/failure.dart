/// The single error type that crosses layer boundaries.
///
/// Data sources and repositories convert transport, parsing and server errors
/// into a [Failure] so the presentation layer only ever has to render
/// [message].
class Failure implements Exception {
  const Failure(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Machine-readable reason from the API, e.g. `EMAIL_NOT_VERIFIED`.
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Can\'t reach Invyte right now. Check your connection and try again.',
  ]);
}

/// Runs [action] and guarantees that anything thrown is a [Failure].
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } catch (_) {
    throw const Failure('We received an unexpected response. Please try again.');
  }
}

/// Human readable message for any error surfaced to the UI.
String describeError(Object? error) {
  if (error is Failure) return error.message;
  return 'Something went wrong. Please try again.';
}
