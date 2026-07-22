part of 'subscription_bloc.dart';

@immutable
sealed class SubscriptionEvent {}

final class SubscriptionLoadEvent extends SubscriptionEvent {}

final class SubscriptionSelectPlanEvent extends SubscriptionEvent {
  SubscriptionSelectPlanEvent({required this.index});

  final int index;
}

final class SubscriptionApplyDiscountEvent extends SubscriptionEvent {
  SubscriptionApplyDiscountEvent({required this.code});

  final String code;
}

final class SubscriptionClearFeedbackEvent extends SubscriptionEvent {}

final class SubscriptionLoadGatewaysEvent extends SubscriptionEvent {}

final class SubscriptionBuyEvent extends SubscriptionEvent {
  SubscriptionBuyEvent({required this.gateway});

  final String gateway;
}

final class SubscriptionClearPaymentUrlEvent extends SubscriptionEvent {}

final class SubscriptionVipUpdatedEvent extends SubscriptionEvent {}
