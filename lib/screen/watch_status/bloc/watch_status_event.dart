part of 'watch_status_bloc.dart';

@immutable
sealed class WatchStatusEvent {}

final class WatchStatusLoadEvent extends WatchStatusEvent {}

final class WatchStatusLoadMoreEvent extends WatchStatusEvent {}
