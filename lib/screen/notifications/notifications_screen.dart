import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_empty_state.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/remote/model/app/notification.dart'
    as app;
import 'package:bamabin_desktop/screen/notifications/bloc/notifications_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<NotificationsBloc>().add(NotificationsLoadEvent());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<NotificationsBloc>().add(NotificationsLoadMoreEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 16, 48, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اعلان‌ها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'vazir',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 30 / 24,
                letterSpacing: -0.15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  return switch (state) {
                    NotificationsInitial() || NotificationsLoading() =>
                      const Center(child: LoadingWidget()),
                    NotificationsError(:final message) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'vazir',
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context
                                  .read<NotificationsBloc>()
                                  .add(NotificationsLoadEvent()),
                              child: Text(
                                'تلاش مجدد',
                                style: TextStyle(color: blueColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    NotificationsLoadingMore(:final items) =>
                      _NotificationsList(
                        items: items,
                        controller: _scrollController,
                        showFooterLoader: true,
                      ),
                    NotificationsSuccess(:final items) => items.isEmpty
                        ? const BamabinEmptyState(
                            message: 'اعلانی برای نمایش وجود ندارد',
                          )
                        : _NotificationsList(
                            items: items,
                            controller: _scrollController,
                            showFooterLoader: false,
                          ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.items,
    required this.controller,
    required this.showFooterLoader,
  });

  final List<app.Notification> items;
  final ScrollController controller;
  final bool showFooterLoader;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.separated(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 48),
          itemCount: items.length + (showFooterLoader ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
            return _NotificationCard(notification: items[index]);
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final app.Notification notification;

  @override
  Widget build(BuildContext context) {
    final isNew = notification.isNew;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131321),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? blueColor.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notification.title.isNotEmpty
                      ? notification.title
                      : 'اعلان',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: blueColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'جدید',
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: blueColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (notification.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notification.content,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'vazir',
                fontSize: 14,
                height: 22 / 14,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _formatDiffTime(notification.diffTime),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDiffTime(int minutes) {
  if (minutes <= 0) return 'همین الان';
  if (minutes < 60) return '$minutes دقیقه پیش';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours ساعت پیش';
  final days = hours ~/ 24;
  if (days < 30) return '$days روز پیش';
  final months = days ~/ 30;
  if (months < 12) return '$months ماه پیش';
  return '${months ~/ 12} سال پیش';
}
