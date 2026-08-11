import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/gateway.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan.dart';
import 'package:bamabin_desktop/data/remote/model/user/vip_info.dart';
import 'package:bamabin_desktop/screen/subscription/bloc/subscription_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _subBg = Color(0xFF0C0C14);
const _subSurface = Color(0xFF131321);
const _subInk = Color(0xFFFFFFFF);
const _subMuted = Color(0x7AFFFFFF);
const _subSubtle = Color(0x99FFFFFF);
const _subLabel = Color(0xBFFFFFFF);
const _subBorder = Color(0x17FFFFFF);
const _subBorderStrong = Color(0x5CFFFFFF);
const _subSuccess = Color(0xFF4ADE80);
const _subSuccessBg = Color(0x1A22C55E);
const _subSuccessBorder = Color(0x804ADE80);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _discountController = TextEditingController();
  var _gatewayDialogOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(SubscriptionLoadEvent());
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showGatewayDialog() async {
    if (_gatewayDialogOpen) return;
    final bloc = context.read<SubscriptionBloc>();
    final state = bloc.state;
    if (state is! SubscriptionLoaded || state.selectedPlan == null) {
      showBamabinSnackbar(context, 'ابتدا یک پلن را انتخاب کنید');
      return;
    }

    bloc.add(SubscriptionLoadGatewaysEvent());
    _gatewayDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: _GatewayAlert(
            onDismiss: () => Navigator.of(dialogContext).pop(),
            onGatewayClick: (gateway) {
              bloc.add(SubscriptionBuyEvent(gateway: gateway));
            },
          ),
        );
      },
    );
    _gatewayDialogOpen = false;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _subBg,
      child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (previous, current) {
          if (current is! SubscriptionLoaded) return false;
          if (previous is! SubscriptionLoaded) {
            return current.feedbackMessage != null ||
                (current.paymentUrl?.isNotEmpty ?? false);
          }
          final feedbackChanged =
              current.feedbackMessage != null &&
              current.feedbackMessage != previous.feedbackMessage;
          final paymentChanged =
              current.paymentUrl != null &&
              current.paymentUrl != previous.paymentUrl &&
              current.paymentUrl!.isNotEmpty;
          return feedbackChanged || paymentChanged;
        },
        listener: (context, state) async {
          if (state is! SubscriptionLoaded) return;

          final paymentUrl = state.paymentUrl;
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            final bloc = context.read<SubscriptionBloc>();
            if (_gatewayDialogOpen && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            bloc.add(SubscriptionClearPaymentUrlEvent());
            await _openPaymentUrl(paymentUrl);
            return;
          }

          final message = state.feedbackMessage;
          if (message == null || message.isEmpty) return;
          showBamabinSnackbar(context, message);
          context.read<SubscriptionBloc>().add(
            SubscriptionClearFeedbackEvent(),
          );
        },
        builder: (context, state) {
          if (state is SubscriptionLoading || state is SubscriptionInitial) {
            return const Center(child: LoadingWidget(showText: false));
          }

          if (state is SubscriptionError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<SubscriptionBloc>().add(
                      SubscriptionLoadEvent(),
                    ),
                    child: Text(
                      'تلاش مجدد',
                      style: TextStyle(color: blueColor),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is! SubscriptionLoaded) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1001),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TitleRow(
                        vip: TempDb.vipInfo.value,
                        onBack: _goBack,
                      ),
                      const SizedBox(height: 32),
                      _DiscountRow(
                        controller: _discountController,
                        isVerifying: state.isVerifyingDiscount,
                        isApplied: state.hasDiscount,
                        onApply: () => context.read<SubscriptionBloc>().add(
                          SubscriptionApplyDiscountEvent(
                            code: _discountController.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.plans.isEmpty)
                        Container(
                          height: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _subSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _subBorder),
                          ),
                          child: Text(
                            'پلنی برای نمایش وجود ندارد',
                            style: TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < state.plans.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _PlanCard(
                            plan: state.plans[i],
                            selected: i == state.selectedIndex,
                            codeDiscountPrice:
                                state.discountedPrices[state.plans[i].id],
                            onTap: () => context.read<SubscriptionBloc>().add(
                              SubscriptionSelectPlanEvent(index: i),
                            ),
                          ),
                        ],
                      if (state.plans.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton(
                            onPressed: state.selectedPlan == null
                                ? null
                                : _showGatewayDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: blueColor.withValues(
                                alpha: 0.35,
                              ),
                              elevation: 0,
                              minimumSize: const Size(0, 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: _subBorder),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'vazir',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('پرداخت و تمدید اشتراک'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'خرید اشتراک به معنای پذیرش قوانین بامابین است.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'vazir',
                            fontSize: 16,
                            height: 22 / 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.vip, required this.onBack});

  final VipInfo vip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تمدید اشتراک',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: _subInk,
                ),
              ),
              const SizedBox(height: 10),
              if (vip.isVip)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusTag(label: 'اشتراک پرو فعال است'),
                    Text(
                      '.',
                      style: TextStyle(
                        fontFamily: 'vazir',
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                    _StatusTag(label: '${vip.days} روز باقی مانده است'),
                  ],
                )
              else
                Text(
                  'اشتراک فعالی ندارید',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        TextButton(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: _subInk,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontFamily: 'vazir',
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('بازگشت به پروفایل'),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/img/arrow_left.svg',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _subSuccessBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _subSuccessBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'vazir',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _subSuccess,
        ),
      ),
    );
  }
}

class _DiscountRow extends StatelessWidget {
  const _DiscountRow({
    required this.controller,
    required this.isVerifying,
    required this.isApplied,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool isVerifying;
  final bool isApplied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: TextField(
              controller: controller,
              enabled: !isVerifying,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'vazir',
                fontSize: 16,
                color: _subInk,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onSubmitted: (_) {
                if (!isVerifying) onApply();
              },
              decoration: InputDecoration(
                hintText: 'کد تخفیف دارید؟ اینجا وارد کنید ...',
                hintStyle: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.36),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.09),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _subBorderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isApplied
                        ? _subSuccess.withValues(alpha: 0.45)
                        : _subBorderStrong,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: blueColor.withValues(alpha: 0.6),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _subBorderStrong),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: isVerifying ? null : onApply,
            style: OutlinedButton.styleFrom(
              foregroundColor: _subLabel,
              disabledForegroundColor: _subMuted,
              backgroundColor: Colors.white.withValues(alpha: 0.09),
              side: const BorderSide(color: _subBorderStrong),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: 'vazir',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isVerifying
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: blueColor,
                    ),
                  )
                : Text(isApplied ? 'اعمال مجدد' : 'اعمال کد'),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.codeDiscountPrice,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final int? codeDiscountPrice;
  final VoidCallback onTap;

  int get _months {
    if (plan.days <= 0) return 1;
    final months = (plan.days / 30).round();
    return months < 1 ? 1 : months;
  }

  int get _basePrice {
    if (plan.discountPrice > 0 && plan.discountPrice < plan.price) {
      return plan.discountPrice;
    }
    return plan.price;
  }

  int get _displayPrice => codeDiscountPrice ?? _basePrice;

  bool get _showStrike {
    final display = _displayPrice;
    return display < plan.price;
  }

  String get _fallbackIconAsset {
    final months = _months;
    if (months <= 1) return 'assets/img/subscription/ic_plan_bike.svg';
    if (months == 2) return 'assets/img/subscription/ic_plan_moto.svg';
    if (months <= 3) return 'assets/img/subscription/ic_plan_car.svg';
    if (months <= 6) return 'assets/img/subscription/ic_plan_jet.svg';
    return 'assets/img/subscription/ic_plan_rocket.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _subSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? _subBorderStrong : _subBorder,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              _PlanIcon(
                iconUrl: plan.iconUrl,
                fallbackAsset: _fallbackIconAsset,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  plan.name,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 24 / 20,
                    color: _subInk,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (_showStrike) ...[
                Text(
                  _formatToman(plan.price),
                  style: const TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 22 / 16,
                    color: _subSubtle,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _subSubtle,
                  ),
                ),
                const SizedBox(width: 16),
                _PriceBadge(text: _formatToman(_displayPrice)),
              ] else
                _PriceBadge(
                  text: _formatToman(_displayPrice),
                  useBlue: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.iconUrl, required this.fallbackAsset});

  final String iconUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0x5C131321),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      alignment: Alignment.center,
      child: iconUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: iconUrl,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => SvgPicture.asset(
                  fallbackAsset,
                  width: 30,
                  height: 30,
                ),
              ),
            )
          : SvgPicture.asset(fallbackAsset, width: 30, height: 30),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.text, this.useBlue = false});

  final String text;
  final bool useBlue;

  @override
  Widget build(BuildContext context) {
    final foreground = useBlue ? blueColor : _subSuccess;
    final background = useBlue
        ? blueColor.withValues(alpha: 0.1)
        : _subSuccessBg;
    final border = useBlue
        ? blueColor.withValues(alpha: 0.4)
        : _subSuccessBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'vazir',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _GatewayAlert extends StatelessWidget {
  const _GatewayAlert({required this.onDismiss, required this.onGatewayClick});

  final VoidCallback onDismiss;
  final void Function(String gateway) onGatewayClick;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      buildWhen: (previous, current) {
        if (current is! SubscriptionLoaded) return false;
        if (previous is! SubscriptionLoaded) return true;
        return previous.gateways != current.gateways ||
            previous.isLoadingGateways != current.isLoadingGateways ||
            previous.isBuyLoading != current.isBuyLoading;
      },
      builder: (context, state) {
        final loaded = state is SubscriptionLoaded ? state : null;
        final gateways = loaded?.gateways ?? const <Gateway>[];
        final isBuyLoading = loaded?.isBuyLoading ?? false;
        final isLoadingGateways = loaded?.isLoadingGateways ?? true;

        return _GatewayAlertBody(
          gateways: gateways,
          isBuyLoading: isBuyLoading,
          isLoadingGateways: isLoadingGateways,
          onDismiss: onDismiss,
          onGatewayClick: onGatewayClick,
        );
      },
    );
  }
}

class _GatewayAlertBody extends StatefulWidget {
  const _GatewayAlertBody({
    required this.gateways,
    required this.isBuyLoading,
    required this.isLoadingGateways,
    required this.onDismiss,
    required this.onGatewayClick,
  });

  final List<Gateway> gateways;
  final bool isBuyLoading;
  final bool isLoadingGateways;
  final VoidCallback onDismiss;
  final void Function(String gateway) onGatewayClick;

  @override
  State<_GatewayAlertBody> createState() => _GatewayAlertBodyState();
}

class _GatewayAlertBodyState extends State<_GatewayAlertBody> {
  var _gatewayType = 'irr';

  List<Gateway> get _filteredGateways =>
      widget.gateways.where((g) => g.type == _gatewayType).toList();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isBuyLoading ? null : widget.onDismiss,
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.isBuyLoading || widget.isLoadingGateways
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(color: yellowColor),
                    ),
                  )
                : widget.gateways.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'درگاهی یافت نشد',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'درگاه پرداخت را انتخاب کنید',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: blueColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _GatewayTypeButton(
                              label: 'درگاه ریالی',
                              selected: _gatewayType == 'irr',
                              isStart: true,
                              onTap: () => setState(() => _gatewayType = 'irr'),
                            ),
                          ),
                          Expanded(
                            child: _GatewayTypeButton(
                              label: 'درگاه دلاری',
                              selected: _gatewayType == 'usd',
                              isStart: false,
                              onTap: () => setState(() => _gatewayType = 'usd'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_filteredGateways.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'درگاهی در این دسته نیست',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      else
                        for (final gateway in _filteredGateways)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    widget.onGatewayClick(gateway.slug),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: CachedNetworkImage(
                                    imageUrl: gateway.icon,
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GatewayTypeButton extends StatelessWidget {
  const _GatewayTypeButton({
    required this.label,
    required this.selected,
    required this.isStart,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isStart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? blueColor : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: isStart ? const Radius.circular(8) : Radius.zero,
          left: isStart ? Radius.zero : const Radius.circular(8),
        ),
        side: BorderSide(color: blueColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          right: isStart ? const Radius.circular(8) : Radius.zero,
          left: isStart ? Radius.zero : const Radius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.black : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatToman(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '$buffer تومان';
}
