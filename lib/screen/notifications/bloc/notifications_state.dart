part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoadingMore extends NotificationsState {
  NotificationsLoadingMore({required this.items});

  final List<app.Notification> items;
}

final class NotificationsSuccess extends NotificationsState {
  NotificationsSuccess({
    required this.items,
    required this.hasMore,
  });

  final List<app.Notification> items;
  final bool hasMore;
}

final class NotificationsError extends NotificationsState {
  NotificationsError({required this.message});

  final String message;
}
