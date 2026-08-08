part of 'top250_bloc.dart';

@immutable
sealed class Top250State {}

final class Top250Initial extends Top250State {}

final class Top250Loading extends Top250State {}

final class Top250Success extends Top250State {
  Top250Success({required this.items});

  final List<Post> items;
}

final class Top250Error extends Top250State {
  Top250Error({required this.message});

  final String message;
}
