import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/remote/model/app/gateway.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan.dart';
import 'package:bamabin_desktop/screen/subscription/bloc/subscription_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _subBg = Color(0xFF0A0A12);
const _subSurface = Color(0xFF14141F);
const _subMuted = Color(0xFFA8AABB);
const _subInk = Color(0xFFF4F4F8);
const _subSubtle = Color(0xFF6F7182);
const _subLabel = Color(0xFFC9CBDB);
const _subSuccess = Color(0xFF4ADE80);
const _subAmber = Color(0xFFF59E0B);
const _subAmberEnd = Color(0xFFFB923C);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _subBg,
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
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
                  Text(state.message, style: const TextStyle(color: _subMuted)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<SubscriptionBloc>().add(
                      SubscriptionLoadEvent(),
                    ),
                    child: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            );
          }

          if (state is! SubscriptionLoaded) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 90),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(Routes.profile);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'تمدید اشتراک',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _subInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.vipLabel,
                        style: const TextStyle(fontSize: 14, color: _subMuted),
                      ),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 20),
                      if (state.plans.isEmpty)
                        Container(
                          height: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _subSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: const Text(
                            'پلنی برای نمایش وجود ندارد',
                            style: TextStyle(color: _subMuted),
                          ),
                        )
                      else ...[
                        for (var i = 0; i < state.plans.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          _PlanCard(
                            plan: state.plans[i],
                            selected: i == state.selectedIndex,
                            codeDiscountPrice:
                                state.discountedPrices[state.plans[i].id],
                            accentPrimary: i == 0 ? blueColor : _subAmber,
                            accentSecondary: i == 0
                                ? desktopAccentDarkColor
                                : _subAmberEnd,
                            onTap: () => context.read<SubscriptionBloc>().add(
                              SubscriptionSelectPlanEvent(index: i),
                            ),
                          ),
                        ],
                      ],
                      if (state.plans.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.center,
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
                              minimumSize: const Size(220, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'dana',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('پرداخت و تمدید اشتراک'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'خرید اشتراک به معنای پذیرش قوانین بامابین است',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _subInk,
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/img/small_logo.png', width: 38, height: 38),
        const SizedBox(width: 12),
        const Text(
          'بامابین',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: _subInk,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: _subLabel,
            textStyle: const TextStyle(fontFamily: 'dana', fontSize: 14.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('بازگشت به پروفایل'),
              SizedBox(width: 8),
              Text('←'),
            ],
          ),
        ),
      ],
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
            height: 48,
            child: TextField(
              controller: controller,
              enabled: !isVerifying,
              style: const TextStyle(fontSize: 14, color: _subInk),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              onSubmitted: (_) {
                if (!isVerifying) onApply();
              },
              decoration: InputDecoration(
                hintText: 'کد تخفیف دارید؟ اینجا وارد کنید',
                hintStyle: const TextStyle(color: _subSubtle, fontSize: 14),
                filled: true,
                fillColor: _subSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isApplied
                        ? _subSuccess.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: blueColor.withValues(alpha: 0.5),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: isVerifying ? null : onApply,
            style: OutlinedButton.styleFrom(
              foregroundColor: _subLabel,
              disabledForegroundColor: _subSubtle,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'dana',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isVerifying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
    required this.accentPrimary,
    required this.accentSecondary,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final int? codeDiscountPrice;
  final Color accentPrimary;
  final Color accentSecondary;
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1A1A2A) : _subSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? blueColor : Colors.white.withValues(alpha: 0.06),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF1A1A2A),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '✦',
                        style: TextStyle(color: accentPrimary, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [accentPrimary, accentSecondary],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: plan.iconUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: plan.iconUrl,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Text(
                                    '$_months',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '$_months',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _subInk,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showStrike) ...[
                    Text(
                      _formatToman(plan.price),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _subSubtle,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: _subSubtle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PriceBadge(
                      text: _formatToman(_displayPrice),
                      background: _subSuccess.withValues(alpha: 0.06),
                      border: _subSuccess.withValues(alpha: 0.4),
                      foreground: _subSuccess,
                    ),
                  ] else
                    _PriceBadge(
                      text: _formatToman(_displayPrice),
                      background: blueColor.withValues(alpha: 0.1),
                      border: blueColor.withValues(alpha: 0.4),
                      foreground: blueColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
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
