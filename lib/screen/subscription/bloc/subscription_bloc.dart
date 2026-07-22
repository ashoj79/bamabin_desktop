import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/gateway.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan.dart';
import 'package:bamabin_desktop/data/remote/model/user/vip_info.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc(this._appRepository) : super(SubscriptionInitial()) {
    on<SubscriptionLoadEvent>(_onLoad);
    on<SubscriptionSelectPlanEvent>(_onSelectPlan);
    on<SubscriptionApplyDiscountEvent>(_onApplyDiscount);
    on<SubscriptionClearFeedbackEvent>(_onClearFeedback);
    on<SubscriptionLoadGatewaysEvent>(_onLoadGateways);
    on<SubscriptionBuyEvent>(_onBuy);
    on<SubscriptionClearPaymentUrlEvent>(_onClearPaymentUrl);
    on<SubscriptionVipUpdatedEvent>(_onVipUpdated);

    TempDb.vipInfo.addListener(_onVipInfoChanged);
  }

  final AppRepository _appRepository;

  static String vipLabelFrom(VipInfo vip) => vip.isVip
      ? 'اشتراک فعلی فعال · ${vip.days} روز باقی‌مانده'
      : 'اشتراک فعالی ندارید';

  void _onVipInfoChanged() {
    add(SubscriptionVipUpdatedEvent());
  }

  @override
  Future<void> close() {
    TempDb.vipInfo.removeListener(_onVipInfoChanged);
    return super.close();
  }

  Future<void> _onLoad(
    SubscriptionLoadEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    final result = await _appRepository.getPlans();
    if (result is DataError) {
      emit(SubscriptionError(result.errorMessage));
      return;
    }

    final plans = result.data ?? const <Plan>[];
    final defaultIndex = plans.indexWhere((p) => p.isDefault);
    emit(
      SubscriptionLoaded(
        plans: plans,
        selectedIndex:
            defaultIndex >= 0 ? defaultIndex : (plans.isEmpty ? -1 : 0),
        vipLabel: vipLabelFrom(TempDb.vipInfo.value),
      ),
    );
  }

  void _onVipUpdated(
    SubscriptionVipUpdatedEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    final current = state;
    if (current is! SubscriptionLoaded) return;
    emit(current.copyWith(vipLabel: vipLabelFrom(TempDb.vipInfo.value)));
  }

  void _onSelectPlan(
    SubscriptionSelectPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    final current = state;
    if (current is! SubscriptionLoaded) return;
    if (event.index < 0 || event.index >= current.plans.length) return;
    emit(
      current.copyWith(
        selectedIndex: event.index,
        clearFeedback: true,
      ),
    );
  }

  Future<void> _onApplyDiscount(
    SubscriptionApplyDiscountEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = state;
    if (current is! SubscriptionLoaded) return;

    final code = event.code.trim();
    if (code.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'کد تخفیف را وارد کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isVerifyingDiscount: true,
        clearFeedback: true,
      ),
    );

    final result = await _appRepository.verifyDiscountForAllPlans(code);
    if (result is DataError) {
      emit(
        current.copyWith(
          isVerifyingDiscount: false,
          clearDiscountedPrices: true,
          discountCode: '',
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    final items = result.data ?? const [];
    if (items.isEmpty) {
      emit(
        current.copyWith(
          isVerifyingDiscount: false,
          clearDiscountedPrices: true,
          discountCode: '',
          feedbackMessage: 'کد تخفیف صحیح نیست',
          feedbackIsError: true,
        ),
      );
      return;
    }

    final prices = <int, int>{
      for (final item in items)
        if (item.id > 0) item.id: item.price,
    };

    emit(
      current.copyWith(
        isVerifyingDiscount: false,
        discountCode: code,
        discountedPrices: prices,
        feedbackMessage: 'کد تخفیف با موفقیت اعمال شد',
        feedbackIsError: false,
      ),
    );
  }

  void _onClearFeedback(
    SubscriptionClearFeedbackEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    final current = state;
    if (current is! SubscriptionLoaded) return;
    emit(current.copyWith(clearFeedback: true));
  }

  Future<void> _onLoadGateways(
    SubscriptionLoadGatewaysEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = state;
    if (current is! SubscriptionLoaded) return;

    if (current.selectedPlan == null) {
      emit(
        current.copyWith(
          feedbackMessage: 'ابتدا یک پلن را انتخاب کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    if (current.gateways.isNotEmpty) {
      emit(current.copyWith(isLoadingGateways: false));
      return;
    }

    emit(current.copyWith(isLoadingGateways: true, clearFeedback: true));
    final result = await _appRepository.getGateways();
    if (result is DataError) {
      emit(
        current.copyWith(
          isLoadingGateways: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isLoadingGateways: false,
        gateways: result.data ?? const [],
      ),
    );
  }

  Future<void> _onBuy(
    SubscriptionBuyEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = state;
    if (current is! SubscriptionLoaded) return;

    final plan = current.selectedPlan;
    if (plan == null) {
      emit(
        current.copyWith(
          feedbackMessage: 'ابتدا یک پلن را انتخاب کنید',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(current.copyWith(isBuyLoading: true, clearFeedback: true));
    final result = await _appRepository.buy(
      plan.id,
      event.gateway,
      current.discountCode,
    );
    if (result is DataError) {
      emit(
        current.copyWith(
          isBuyLoading: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    final url = result.data?.trim() ?? '';
    if (url.isEmpty) {
      emit(
        current.copyWith(
          isBuyLoading: false,
          feedbackMessage: 'لینک پرداخت دریافت نشد',
          feedbackIsError: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isBuyLoading: false,
        paymentUrl: url,
      ),
    );
  }

  void _onClearPaymentUrl(
    SubscriptionClearPaymentUrlEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    final current = state;
    if (current is! SubscriptionLoaded) return;
    emit(current.copyWith(clearPaymentUrl: true));
  }
}
