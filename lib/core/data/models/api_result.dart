class ApiResult<T> {
  final T? data;
  final String? message;
  final bool isSuccess;

  const ApiResult._({
    required this.data,
    required this.message,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(data: data, message: null, isSuccess: true);
  }

  factory ApiResult.failure(String message) {
    return ApiResult._(data: null, message: message, isSuccess: false);
  }

  ApiResult<R> map<R>(R Function(T data) mapper) {
    if (!isSuccess || data == null) {
      return ApiResult._(data: null, message: message, isSuccess: false);
    }
    return ApiResult.success(mapper(data as T));
  }
}
