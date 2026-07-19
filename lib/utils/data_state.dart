abstract class DataState<T> {
  String errorMessage;
  T? data;

  DataState({required this.errorMessage, this.data});
}

class DataSuccess<T> extends DataState<T> {
  DataSuccess([T? data, String errorMessage = '']) : super(data: data, errorMessage: errorMessage);
}

class DataError<T> extends DataState<T> {
  DataError(String message) : super(errorMessage: message);
}
