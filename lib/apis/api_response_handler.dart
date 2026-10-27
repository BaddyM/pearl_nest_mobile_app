class ApiResponseHandler {
  static Map<String, dynamic> handleSuccess(dynamic data, {String? message}) {
    return {
      'success': true,
      'data': data,
      'message': message ?? 'Operation successful',
    };
  }
  
  static Map<String, dynamic> handleError(String message, {int? statusCode, dynamic data}) {
    return {
      'success': false,
      'message': message,
      'statusCode': statusCode,
      'data': data,
    };
  }
  
  static Map<String, dynamic> handleNetworkError(String error) {
    return {
      'success': false,
      'message': 'Network error: Please check your internet connection',
      'error': error,
    };
  }
  
  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
