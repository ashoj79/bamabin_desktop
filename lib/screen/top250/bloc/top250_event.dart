part of 'top250_bloc.dart';

@immutable
sealed class Top250Event {}

final class Top250LoadEvent extends Top250Event {}
