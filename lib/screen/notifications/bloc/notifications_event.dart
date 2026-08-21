part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsEvent {}

final class NotificationsLoadEvent extends NotificationsEvent {}

final class NotificationsLoadMoreEvent extends NotificationsEvent {}
