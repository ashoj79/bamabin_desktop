part of 'subscription_bloc.dart';

@immutable
sealed class SubscriptionState {}

final class SubscriptionInitial extends SubscriptionState {}

final class SubscriptionLoading extends SubscriptionState {}

final class SubscriptionError extends SubscriptionState {
  SubscriptionError(this.message);

  final String message;
}

final class SubscriptionLoaded extends SubscriptionState {
  SubscriptionLoaded({
    required this.plans,
    required this.selectedIndex,
    required this.vipLabel,
    this.discountCode = '',
    this.discountedPrices = const {},
    this.isVerifyingDiscount = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.gateways = const [],
    this.isLoadingGateways = false,
    this.isBuyLoading = false,
    this.paymentUrl,
  });

  final List<Plan> plans;
  final int selectedIndex;
  final String vipLabel;
  final String discountCode;
  final Map<int, int> discountedPrices;
  final bool isVerifyingDiscount;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final List<Gateway> gateways;
  final bool isLoadingGateways;
  final bool isBuyLoading;
  final String? paymentUrl;

  bool get hasDiscount => discountedPrices.isNotEmpty;

  Plan? get selectedPlan {
    if (selectedIndex < 0 || selectedIndex >= plans.length) return null;
    return plans[selectedIndex];
  }

  SubscriptionLoaded copyWith({
    List<Plan>? plans,
    int? selectedIndex,
    String? vipLabel,
    String? discountCode,
    Map<int, int>? discountedPrices,
    bool clearDiscountedPrices = false,
    bool? isVerifyingDiscount,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? feedbackIsError,
    List<Gateway>? gateways,
    bool? isLoadingGateways,
    bool? isBuyLoading,
    String? paymentUrl,
    bool clearPaymentUrl = false,
  }) {
    return SubscriptionLoaded(
      plans: plans ?? this.plans,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      vipLabel: vipLabel ?? this.vipLabel,
      discountCode: discountCode ?? this.discountCode,
      discountedPrices: clearDiscountedPrices
          ? const {}
          : (discountedPrices ?? this.discountedPrices),
      isVerifyingDiscount: isVerifyingDiscount ?? this.isVerifyingDiscount,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      gateways: gateways ?? this.gateways,
      isLoadingGateways: isLoadingGateways ?? this.isLoadingGateways,
      isBuyLoading: isBuyLoading ?? this.isBuyLoading,
      paymentUrl: clearPaymentUrl ? null : (paymentUrl ?? this.paymentUrl),
    );
  }
}
