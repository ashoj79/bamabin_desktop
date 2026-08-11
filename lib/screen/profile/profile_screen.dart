import 'dart:io';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/dialogs.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/core/widgets/view_all_button.dart';
import 'package:bamabin_desktop/core/widgets/watching_card.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/user/dashboard.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:bamabin_desktop/screen/profile/bloc/profile_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

const _profileBg = Color(0xFF0A0A12);
const _profileSurface = Color(0xFF14141F);
const _profileField = Color(0xFF1C1C2B);
const _profileMuted = Color(0xFFA8AABB);
const _profileInk = Color(0xFFF4F4F8);
const _profileSubtle = Color(0xFF6F7182);
const _profileLabel = Color(0xFFC9CBDB);
const _profileDanger = Color(0xFFF2536B);
const _profileSuccess = Color(0xFF4ADE80);
const _maxDevices = 4;

enum _ProfileTab { overview, edit, settings, playback, tvLogin }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _tab = _ProfileTab.overview;
  var _loadingDialogShown = false;

  var _emailNotif = true;
  var _smsNotif = false;
  var _pushNotif = true;
  var _autoplayNext = true;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadEvent());
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF2B2B2B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'آیا می‌خواهید از حساب کاربری خود خارج شوید؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'خیر',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'بله',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: redColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<ProfileBloc>().add(ProfileLogoutEvent());
  }

  Future<void> _confirmDeleteDevice({required int index}) async {
    final message = index == -1
        ? 'آیا می‌خواهید از همه دستگاه‌ها خارج شوید؟'
        : 'آیا می‌خواهید از این دستگاه خارج شوید؟';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF2B2B2B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'خیر',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'بله',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: redColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    context
        .read<ProfileBloc>()
        .add(ProfileDeleteDeviceEvent(index: index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _profileBg,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            current is ProfileLogoutLoading ||
            current is ProfileLogoutSuccess ||
            current is ProfileBusy ||
            current is ProfileActionSuccess ||
            current is ProfileError ||
            (previous is ProfileBusy && current is ProfileLoaded),
        buildWhen: (previous, current) =>
            current is ProfileInitial ||
            current is ProfileLoaded ||
            (current is ProfileError && previous is! ProfileLoaded),
        listener: (context, state) {
          if (state is ProfileLogoutLoading || state is ProfileBusy) {
            if (!_loadingDialogShown) {
              _loadingDialogShown = true;
              showLoadingDialog(context);
            }
            return;
          }

          if (_loadingDialogShown) {
            Navigator.of(context, rootNavigator: true).pop();
            _loadingDialogShown = false;
          }

          if (state is ProfileError) {
            showBamabinSnackbar(context, state.message);
          } else if (state is ProfileActionSuccess) {
            showBamabinSnackbar(context, state.message);
          } else if (state is ProfileLogoutSuccess) {
            context.go(Routes.main);
          }
        },
        builder: (context, state) {
          if (state is ProfileInitial) {
            return const Center(child: LoadingWidget(showText: false));
          }

          if (state is! ProfileLoaded) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    context.read<ProfileBloc>().add(ProfileLoadEvent()),
                child: const Text('تلاش مجدد'),
              ),
            );
          }

          final loaded = state;

          return ListView(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 90),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHero(
                        loaded: loaded,
                        onLogout: _confirmLogout,
                      ),
                      const SizedBox(height: 20),
                      _DomainBanner(
                        specialDomain: loaded.dashboard?.specialDomain ?? '',
                      ),
                      const SizedBox(height: 24),
                      _TabPills(
                        tab: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                      ),
                      const SizedBox(height: 20),
                      switch (_tab) {
                        _ProfileTab.overview => _OverviewTab(
                            loaded: loaded,
                          ),
                        _ProfileTab.edit => _EditTab(loaded: loaded),
                        _ProfileTab.settings => _SettingsTab(
                            loaded: loaded,
                            emailNotif: _emailNotif,
                            smsNotif: _smsNotif,
                            pushNotif: _pushNotif,
                            onToggleEmail: () =>
                                setState(() => _emailNotif = !_emailNotif),
                            onToggleSms: () =>
                                setState(() => _smsNotif = !_smsNotif),
                            onTogglePush: () =>
                                setState(() => _pushNotif = !_pushNotif),
                            onLogoutAll: () =>
                                _confirmDeleteDevice(index: -1),
                            onLogoutDevice: (index) =>
                                _confirmDeleteDevice(index: index),
                          ),
                        _ProfileTab.playback => _PlaybackTab(
                            loaded: loaded,
                            autoplayNext: _autoplayNext,
                            onToggleAutoplayNext: () => setState(
                              () => _autoplayNext = !_autoplayNext,
                            ),
                          ),
                        _ProfileTab.tvLogin => const _TvLoginTab(),
                      },
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.loaded,
    required this.onLogout,
  });

  final ProfileLoaded loaded;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    if (loaded.isDashboardLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF191531), Color(0xFF12111C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            const _ProfileShimmerBox(width: 120, height: 120, radius: 60),
            const SizedBox(width: 26),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ProfileShimmerBox(width: 180, height: 22, radius: 6),
                  SizedBox(height: 10),
                  _ProfileShimmerBox(width: 140, height: 16, radius: 6),
                  SizedBox(height: 10),
                  _ProfileShimmerBox(width: 200, height: 14, radius: 6),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dashboard = loaded.dashboard!;
    final hasVip = dashboard.vipTime > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF191531), Color(0xFF12111C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(url: dashboard.avatar, size: 120),
              const SizedBox(width: 26),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          loaded.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _profileInk,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasVip
                                ? _profileSuccess.withValues(alpha: 0.12)
                                : _profileDanger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: hasVip
                                  ? _profileSuccess.withValues(alpha: 0.3)
                                  : _profileDanger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasVip
                                      ? _profileSuccess
                                      : _profileDanger,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasVip
                                    ? 'اشتراک حرفه‌ای فعال'
                                    : 'بدون اشتراک فعال',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: hasVip
                                      ? _profileSuccess
                                      : _profileDanger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (loaded.email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        loaded.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _profileMuted,
                        ),
                      ),
                    ],
                    if (dashboard.registeredAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'تاریخ ثبت نام: ${dashboard.registeredAt}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _profileMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: _profileDanger,
              side: BorderSide(
                color: _profileDanger.withValues(alpha: 0.35),
              ),
              backgroundColor: _profileDanger.withValues(alpha: 0.08),
              minimumSize: const Size(0, 42),
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
            child: const Text('خروج از حساب کاربری'),
          ),
        ],
      ),
    );
  }
}

class _DomainBanner extends StatelessWidget {
  const _DomainBanner({required this.specialDomain});

  final String specialDomain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: _profileSuccess.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _profileSuccess.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.notifications_active, size: 18, color: _profileSuccess),
          const Text(
            'آدرس اختصاصی و بدون فیلتر شما:',
            style: TextStyle(fontSize: 14.5, color: Color(0xFFD7F7E2)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _profileField,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              specialDomain,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _profileSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  const _TabPills({required this.tab, required this.onChanged});

  final _ProfileTab tab;
  final ValueChanged<_ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, _ProfileTab value) {
      final active = tab == value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active ? blueColor : _profileSurface,
              border: active
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : _profileLabel,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        pill('نمای کلی', _ProfileTab.overview),
        pill('ویرایش اطلاعات', _ProfileTab.edit),
        pill('امنیت و تنظیمات', _ProfileTab.settings),
        pill('تنظیمات پخش', _ProfileTab.playback),
        pill('ورود تلویزیون', _ProfileTab.tvLogin),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.loaded});

  final ProfileLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final d = loaded.dashboard;
    final remainingPct = d == null
        ? 0.0
        : (100 - d.vipTimePercentage).clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loaded.isDashboardLoading) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1100
                  ? 6
                  : width >= 800
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.55,
                children: List.generate(
                  6,
                  (_) => const _ProfileShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 16,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const _ProfileShimmerBox(
            width: double.infinity,
            height: 120,
            radius: 20,
          ),
        ]
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1100
                  ? 6
                  : width >= 800
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.55,
                children: [
                  _StatCard(value: '${d!.watchedCount}', label: 'دیدمش رفت'),
                  _StatCard(value: '${d.watchingCount}', label: 'دارم می‌بینم'),
                  _StatCard(
                    value: '${d.notWatchedCount}',
                    label: 'می‌خوام ببینم',
                  ),
                  _StatCard(
                    value: '${d.favoritesCount}',
                    label: 'علاقه‌مندی‌ها',
                  ),
                  _StatCard(value: '${d.requestsCount}', label: 'درخواست‌ها'),
                  _StatCard(value: '${d.listsCount}', label: 'لیست‌ها'),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _VipCard(dashboard: d!, remainingPct: remainingPct),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'در حال تماشا',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _profileInk,
              ),
            ),
            const Spacer(),
            if (!loaded.isPlayStatusLoading)
              ViewAllButton(
                onPressed: () => context.push(Routes.watchStatusPosts),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (loaded.isPlayStatusLoading)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (_, _) => const WatchingCardShimmer(),
              );
            },
          )
        else if (loaded.playStatus.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _profileSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              'موردی در حال تماشا نیست',
              style: TextStyle(color: _profileMuted),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              final items = loaded.playStatus.take(4).toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) =>
                    WatchingCard(item: items[index]),
              );
            },
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: _profileSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _profileInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _profileMuted),
          ),
        ],
      ),
    );
  }
}

class _VipCard extends StatelessWidget {
  const _VipCard({
    required this.dashboard,
    required this.remainingPct,
  });

  final Dashboard dashboard;
  final double remainingPct;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = dashboard.vipTime < 0 ? 0 : dashboard.vipTime;
    final days = totalSeconds ~/ Duration.secondsPerDay;
    final hours = (totalSeconds ~/ Duration.secondsPerHour) % 24;
    final minutes = (totalSeconds ~/ Duration.secondsPerMinute) % 60;
    final endDate = dashboard.vipEndDate.isNotEmpty
        ? dashboard.vipEndDate
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
      decoration: BoxDecoration(
        color: _profileSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 30,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 30,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: remainingPct / 100,
                        strokeWidth: 11,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        color: blueColor,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '٪${remainingPct.round()}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _profileInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'زمان باقی‌مانده',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _profileMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اشتراک حرفه‌ای ماهانه',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _profileInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تاریخ انقضا: $endDate',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _profileMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dashboard.devicesCount} از $_maxDevices دستگاه فعال',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _profileMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CountdownBox(
                    value: minutes.toString().padLeft(2, '0'),
                    label: 'دقیقه',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: _profileSubtle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CountdownBox(
                    value: hours.toString().padLeft(2, '0'),
                    label: 'ساعت',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: _profileSubtle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CountdownBox(value: days.toString().padLeft(2, '0'), label: 'روز'),
                ],
              ),
              ElevatedButton(
                onPressed: () => context.go(Routes.subscription),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'dana',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('تمدید اشتراک'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _profileField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _profileInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _profileMuted),
          ),
        ],
      ),
    );
  }
}

class _EditTab extends StatefulWidget {
  const _EditTab({required this.loaded});

  final ProfileLoaded loaded;

  @override
  State<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<_EditTab> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _descriptionController;

  String? _localAvatarPath;

  ProfileLoaded get loaded => widget.loaded;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: loaded.firstName);
    _lastNameController = TextEditingController(text: loaded.lastName);
    _nicknameController = TextEditingController(text: loaded.nickname);
    _emailController = TextEditingController(text: loaded.email);
    _phoneController = TextEditingController(text: loaded.phone);
    _cityController = TextEditingController(text: loaded.city);
    _descriptionController = TextEditingController(text: loaded.description);
  }

  @override
  void didUpdateWidget(covariant _EditTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.loaded;
    final prev = oldWidget.loaded;
    if (next.firstName != prev.firstName ||
        next.lastName != prev.lastName ||
        next.nickname != prev.nickname ||
        next.email != prev.email ||
        next.phone != prev.phone ||
        next.city != prev.city ||
        next.description != prev.description) {
      _resetFields();
    }
    if (next.dashboard?.avatar != prev.dashboard?.avatar) {
      _localAvatarPath = null;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetFields() {
    _firstNameController.text = loaded.firstName;
    _lastNameController.text = loaded.lastName;
    _nicknameController.text = loaded.nickname;
    _emailController.text = loaded.email;
    _phoneController.text = loaded.phone;
    _cityController.text = loaded.city;
    _descriptionController.text = loaded.description;
    setState(() => _localAvatarPath = null);
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;

    setState(() => _localAvatarPath = path);
    context.read<ProfileBloc>().add(ProfileUpdateAvatarEvent(filePath: path));
  }

  void _save() {
    context.read<ProfileBloc>().add(
      ProfileEditEvent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = loaded.dashboard?.avatar ?? TempDb.avatar;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _profileSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ویرایش اطلاعات پروفایل',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _profileInk,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: _Avatar(
                    url: avatarUrl,
                    localPath: _localAvatarPath,
                    size: 120,
                  ),
                ),
              ),
              const SizedBox(width: 26),
              const Expanded(
                child: Text(
                  'برای تغییر عکس، روی دایره کلیک کنید یا فایل را انتخاب کنید',
                  style: TextStyle(fontSize: 14, color: _profileMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 700;
              final fields = [
                _ProfileField(
                  label: 'نام',
                  controller: _firstNameController,
                ),
                _ProfileField(
                  label: 'نام خانوادگی',
                  controller: _lastNameController,
                ),
                _ProfileField(
                  label: 'نام مستعار',
                  controller: _nicknameController,
                ),
                _ProfileField(
                  label: 'ایمیل',
                  controller: _emailController,
                ),
                _ProfileField(
                  label: 'شماره موبایل',
                  controller: _phoneController,
                ),
                _ProfileField(
                  label: 'شهر',
                  controller: _cityController,
                ),
              ];

              Widget grid;
              if (!twoCol) {
                grid = Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 20),
                    ],
                  ],
                );
              } else {
                grid = Column(
                  children: [
                    for (var i = 0; i < fields.length; i += 2) ...[
                      if (i > 0) const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: fields[i]),
                          const SizedBox(width: 20),
                          Expanded(
                            child: i + 1 < fields.length
                                ? fields[i + 1]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  grid,
                  const SizedBox(height: 20),
                  _ProfileField(
                    label: 'درباره من',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'dana',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('ذخیره تغییرات'),
              ),
              OutlinedButton(
                onPressed: _resetFields,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _profileLabel,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'dana',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('انصراف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    this.controller,
    this.maxLines = 1,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final int maxLines;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1 && !obscureText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: _profileMuted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: isMultiline ? null : 46,
          child: TextFormField(
            controller: controller,
            maxLines: isMultiline ? maxLines : 1,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14.5, color: _profileInk),
            decoration: InputDecoration(
              filled: true,
              fillColor: _profileField,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isMultiline ? 12 : 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: blueColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.loaded,
    required this.emailNotif,
    required this.smsNotif,
    required this.pushNotif,
    required this.onToggleEmail,
    required this.onToggleSms,
    required this.onTogglePush,
    required this.onLogoutAll,
    required this.onLogoutDevice,
  });

  final ProfileLoaded loaded;
  final bool emailNotif;
  final bool smsNotif;
  final bool pushNotif;
  final VoidCallback onToggleEmail;
  final VoidCallback onToggleSms;
  final VoidCallback onTogglePush;
  final VoidCallback onLogoutAll;
  final ValueChanged<int> onLogoutDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsCard(
          title: 'تغییر رمز عبور',
          child: const _ChangePasswordForm(),
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: 'دستگاه‌های متصل',
          trailing: OutlinedButton(
            onPressed: onLogoutAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: _profileDanger,
              side: BorderSide(
                color: _profileDanger.withValues(alpha: 0.35),
              ),
              backgroundColor: _profileDanger.withValues(alpha: 0.08),
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontFamily: 'dana',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('خروج از همه دستگاه‌ها'),
          ),
          child: loaded.isDevicesLoading
              ? Column(
                  children: List.generate(
                    3,
                    (i) => Column(
                      children: [
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ProfileShimmerBox(
                                      width: 140,
                                      height: 14,
                                      radius: 4,
                                    ),
                                    SizedBox(height: 8),
                                    _ProfileShimmerBox(
                                      width: 90,
                                      height: 11,
                                      radius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              _ProfileShimmerBox(
                                width: 72,
                                height: 34,
                                radius: 9,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < loaded.devices.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      _DeviceRow(
                        device: loaded.devices[i],
                        onLogout: loaded.devices[i].isCurrent
                            ? null
                            : () => onLogoutDevice(i),
                      ),
                    ],
                    if (loaded.devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'دستگاهی یافت نشد',
                          style: TextStyle(color: _profileMuted),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordSubmitController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordSubmitController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _currentPasswordController.clear();
    _passwordController.clear();
    _passwordSubmitController.clear();
  }

  void _submit() {
    final currentPassword = _currentPasswordController.text;
    final password = _passwordController.text;
    final passwordSubmit = _passwordSubmitController.text;

    if (currentPassword.isEmpty ||
        password.isEmpty ||
        passwordSubmit.isEmpty) {
      showBamabinSnackbar(context, 'لطفا همه فیلدهای رمز عبور را پر کنید');
      return;
    }
    if (password != passwordSubmit) {
      showBamabinSnackbar(context, 'رمز عبور جدید و تکرار آن یکسان نیست');
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileUpdatePasswordEvent(
        currentPassword: currentPassword,
        password: password,
        passwordSubmit: passwordSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => current is ProfileActionSuccess,
      listener: (context, state) {
        if (state is ProfileActionSuccess &&
            state.message.contains('رمز عبور')) {
          _clearFields();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final threeCol = constraints.maxWidth >= 700;
              final current = _ProfileField(
                label: 'رمز عبور فعلی',
                controller: _currentPasswordController,
                obscureText: true,
              );
              final next = _ProfileField(
                label: 'رمز عبور جدید',
                controller: _passwordController,
                obscureText: true,
              );
              final confirm = _ProfileField(
                label: 'تأیید رمز عبور جدید',
                controller: _passwordSubmitController,
                obscureText: true,
              );
              if (!threeCol) {
                return Column(
                  children: [
                    current,
                    const SizedBox(height: 20),
                    next,
                    const SizedBox(height: 20),
                    confirm,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: current),
                  const SizedBox(width: 20),
                  Expanded(child: next),
                  const SizedBox(width: 20),
                  Expanded(child: confirm),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'dana',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('به‌روزرسانی رمز عبور'),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, this.onLogout});

  final Device device;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty ? device.name : 'دستگاه',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _profileInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.type,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _profileMuted,
                  ),
                ),
              ],
            ),
          ),
          if (device.isCurrent)
            const Text(
              'دستگاه فعلی',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _profileSuccess,
              ),
            )
          else
            OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: _profileLabel,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'dana',
                  fontSize: 12.5,
                ),
              ),
              child: const Text('خروج'),
            ),
        ],
      ),
    );
  }
}

class _PlaybackPrefs {
  static const speeds = ['0.75x', '1.0x', '1.25x', '1.5x', '2.0x'];
  static const bgColors = ['مشکی', 'تیره کمرنگ', 'بی‌رنگ'];
  static const textColors = ['سفید', 'زرد', 'آبی'];
  static const fonts = ['ایران‌سنس', 'وزیر متن', 'دانا'];
  static const sizeLabels = ['کوچک', 'متوسط', 'بزرگ'];
  static const sizeValues = [16, 22, 28];
  static const marginLabels = ['کم', 'متوسط', 'زیاد'];
  static const marginValues = [8, 16, 32];

  static String labelFromIndex(List<String> options, int index) {
    if (index < 0 || index >= options.length) return options.first;
    return options[index];
  }

  static String labelFromValue(List<String> labels, List<int> values, int value) {
    var best = 0;
    var bestDiff = (values.first - value).abs();
    for (var i = 1; i < values.length; i++) {
      final diff = (values[i] - value).abs();
      if (diff < bestDiff) {
        best = i;
        bestDiff = diff;
      }
    }
    return labels[best];
  }

  static int valueFromLabel(List<String> labels, List<int> values, String label) {
    final index = labels.indexOf(label);
    if (index < 0) return values[1];
    return values[index];
  }
}

class _TvLoginTab extends StatefulWidget {
  const _TvLoginTab();

  @override
  State<_TvLoginTab> createState() => _TvLoginTabState();
}

class _TvLoginTabState extends State<_TvLoginTab> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(
      ProfileTvRemoteLoginEvent(token: _codeController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => current is ProfileActionSuccess,
      listener: (context, state) {
        if (state is ProfileActionSuccess &&
            state.message.contains('ورود تلویزیون')) {
          _codeController.clear();
        }
      },
      child: _SettingsCard(
        title: 'ورود با کد تلویزیون',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'کد نمایش‌داده‌شده روی تلویزیون را وارد کنید تا حساب شما روی آن دستگاه وارد شود.',
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: _profileMuted,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'کد ورود',
              style: TextStyle(fontSize: 13.5, color: _profileMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _profileInk,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'کد را وارد کنید',
                  hintStyle: TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: _profileSubtle,
                  ),
                  filled: true,
                  fillColor: _profileField,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: blueColor.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'dana',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('تأیید و ورود تلویزیون'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackTab extends StatelessWidget {
  const _PlaybackTab({
    required this.loaded,
    required this.autoplayNext,
    required this.onToggleAutoplayNext,
  });

  final ProfileLoaded loaded;
  final bool autoplayNext;
  final VoidCallback onToggleAutoplayNext;

  void _update(BuildContext context, ProfilePlaybackSetting setting, int value) {
    context.read<ProfileBloc>().add(
      ProfileUpdatePlaybackSettingEvent(setting: setting, value: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speedLabel = _PlaybackPrefs.labelFromIndex(
      _PlaybackPrefs.speeds,
      loaded.videoSpeed,
    );
    final sizeLabel = _PlaybackPrefs.labelFromValue(
      _PlaybackPrefs.sizeLabels,
      _PlaybackPrefs.sizeValues,
      loaded.subtitleSize,
    );
    final fontLabel = _PlaybackPrefs.labelFromIndex(
      _PlaybackPrefs.fonts,
      loaded.subtitleFont,
    );
    final bgLabel = _PlaybackPrefs.labelFromIndex(
      _PlaybackPrefs.bgColors,
      loaded.subtitleBgColor,
    );
    final textLabel = _PlaybackPrefs.labelFromIndex(
      _PlaybackPrefs.textColors,
      loaded.subtitleTextColor,
    );
    final marginLabel = _PlaybackPrefs.labelFromValue(
      _PlaybackPrefs.marginLabels,
      _PlaybackPrefs.marginValues,
      loaded.subtitleMargin,
    );

    return Column(
      children: [
        _OptionCard(
          title: 'سرعت پخش',
          subtitle: 'سرعت پیش‌فرض پخش فیلم و سریال',
          options: _PlaybackPrefs.speeds,
          selected: speedLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.videoSpeed,
            _PlaybackPrefs.speeds.indexOf(label),
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'اندازه فونت زیرنویس',
          subtitle: 'اندازه متن زیرنویس هنگام پخش فیلم و سریال',
          options: _PlaybackPrefs.sizeLabels,
          selected: sizeLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.subtitleSize,
            _PlaybackPrefs.valueFromLabel(
              _PlaybackPrefs.sizeLabels,
              _PlaybackPrefs.sizeValues,
              label,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'فونت زیرنویس',
          subtitle: 'قلم نمایش متن زیرنویس',
          options: _PlaybackPrefs.fonts,
          selected: fontLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.subtitleFont,
            _PlaybackPrefs.fonts.indexOf(label),
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'رنگ پس‌زمینه زیرنویس',
          subtitle: 'رنگ پس‌زمینه متن زیرنویس هنگام پخش',
          options: _PlaybackPrefs.bgColors,
          selected: bgLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.subtitleBgColor,
            _PlaybackPrefs.bgColors.indexOf(label),
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'رنگ متن زیرنویس',
          subtitle: 'رنگ نوشته‌های زیرنویس هنگام پخش',
          options: _PlaybackPrefs.textColors,
          selected: textLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.subtitleTextColor,
            _PlaybackPrefs.textColors.indexOf(label),
          ),
        ),
        const SizedBox(height: 20),
        _OptionCard(
          title: 'فاصله از پایین',
          subtitle: 'فاصله زیرنویس از پایین صفحه هنگام پخش',
          options: _PlaybackPrefs.marginLabels,
          selected: marginLabel,
          onSelect: (label) => _update(
            context,
            ProfilePlaybackSetting.subtitleMargin,
            _PlaybackPrefs.valueFromLabel(
              _PlaybackPrefs.marginLabels,
              _PlaybackPrefs.marginValues,
              label,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          title: 'پخش خودکار',
          child: Column(
            children: [
              _ToggleRow(
                title: 'پخش خودکار قسمت بعدی',
                subtitle:
                    'در سریال‌ها بعد از پایان قسمت، قسمت بعد را شروع کن',
                value: autoplayNext,
                onTap: onToggleAutoplayNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: _profileMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in options)
                _ChoiceChip(
                  label: option,
                  selected: option == selected,
                  onTap: () => onSelect(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected
                ? LinearGradient(colors: [blueColor, desktopAccentDarkColor])
                : null,
            color: selected ? null : _profileField,
            border: selected
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _profileLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
      decoration: BoxDecoration(
        color: _profileSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _profileInk,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _profileInk,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: _profileMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _Toggle(value: value, onTap: onTap),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: value
                ? LinearGradient(colors: [blueColor, desktopAccentDarkColor])
                : null,
            color: value ? null : _profileField,
            border: value
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.size,
    this.localPath,
  });

  final String url;
  final String? localPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final local = localPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [desktopAccentDarkColor, blueColor],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: local != null && local.isNotEmpty
          ? Image.file(
              File(local),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                color: Colors.white,
                size: 42,
              ),
            )
          : url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Shimmer(
                    child: ColoredBox(color: _profileField),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 42,
                  ),
                )
              : const Icon(Icons.person, color: Colors.white, size: 42),
    );
  }
}

class _ProfileShimmerBox extends StatelessWidget {
  const _ProfileShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.08,
      child: Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
