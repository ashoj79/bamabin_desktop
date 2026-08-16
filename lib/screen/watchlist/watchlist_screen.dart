import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_empty_state.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/watch_status/widgets/shelf_delete_dialog.dart';
import 'package:bamabin_desktop/screen/watchlist/bloc/watchlist_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<WatchlistBloc>().add(WatchlistLoadEvent());
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
      context.read<WatchlistBloc>().add(WatchlistLoadMoreEvent());
    }
  }

  Future<void> _onDeleteTap(Post post) async {
    final title = post.faTitle.isNotEmpty ? post.faTitle : post.title;
    final confirmed = await showShelfDeleteConfirmDialog(
      context,
      message: title.isNotEmpty
          ? 'آیا می‌خواهید «$title» را از علاقه‌مندی‌ها حذف کنید؟'
          : 'آیا می‌خواهید این مورد را از علاقه‌مندی‌ها حذف کنید؟',
    );
    if (!confirmed || !mounted) return;
    context.read<WatchlistBloc>().add(WatchlistDeleteEvent(post.id));
  }

  Future<void> _onClearAllTap() async {
    final confirmed = await showShelfDeleteConfirmDialog(
      context,
      message: 'آیا می‌خواهید تمامی علاقه‌مندی‌های خود را پاک کنید؟',
    );
    if (!confirmed || !mounted) return;
    context.read<WatchlistBloc>().add(WatchlistClearAllEvent());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: BlocConsumer<WatchlistBloc, WatchlistState>(
        listenWhen: (previous, current) {
          if (current is! WatchlistSuccess) return false;
          if (previous is! WatchlistSuccess) {
            return current.feedbackMessage != null;
          }
          return current.feedbackMessage != null &&
              current.feedbackMessage != previous.feedbackMessage;
        },
        listener: (context, state) {
          if (state is! WatchlistSuccess) return;
          final message = state.feedbackMessage;
          if (message == null || message.isEmpty) return;
          showBamabinSnackbar(context, message);
          context.read<WatchlistBloc>().add(WatchlistClearFeedbackEvent());
        },
        builder: (context, state) {
          final canClearAll = switch (state) {
            WatchlistSuccess(:final items, :final isBusy) =>
              items.isNotEmpty && !isBusy,
            _ => false,
          };

          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WatchlistHeader(
                  canClearAll: canClearAll,
                  onClearAll: _onClearAllTap,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: switch (state) {
                    WatchlistInitial() || WatchlistLoading() =>
                      const _WatchlistGridShimmer(),
                    WatchlistError(:final message) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context
                                .read<WatchlistBloc>()
                                .add(WatchlistLoadEvent()),
                            child: Text(
                              'تلاش مجدد',
                              style: TextStyle(color: blueColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WatchlistLoadingMore(:final items) => _WatchlistGrid(
                      items: items,
                      controller: _scrollController,
                      showFooterShimmer: true,
                      onDeleteTap: _onDeleteTap,
                    ),
                    WatchlistSuccess(
                      :final items,
                      :final deletingPostId,
                      :final isClearingAll,
                    ) =>
                      isClearingAll
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : items.isEmpty
                              ? const BamabinEmptyState(
                                  message:
                                      'نتیجه ای برای علاقه مندی های شما پیدا نشد.',
                                )
                              : _WatchlistGrid(
                                  items: items,
                                  controller: _scrollController,
                                  deletingPostId: deletingPostId,
                                  onDeleteTap: _onDeleteTap,
                                ),
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  const _WatchlistHeader({
    required this.canClearAll,
    required this.onClearAll,
  });

  final bool canClearAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'علاقه مندی ها',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 30 / 24,
              letterSpacing: -0.15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canClearAll ? onClearAll : null,
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: canClearAll ? 1 : 0.4,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                ),
                child: Text(
                  'حذف تمامی علاقه‌مندی‌ها',
                  style: TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.18,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchlistGrid extends StatelessWidget {
  const _WatchlistGrid({
    required this.items,
    required this.controller,
    required this.onDeleteTap,
    this.showFooterShimmer = false,
    this.deletingPostId,
  });

  final List<Post> items;
  final ScrollController controller;
  final ValueChanged<Post> onDeleteTap;
  final bool showFooterShimmer;
  final int? deletingPostId;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 48),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 266,
              crossAxisSpacing: 16,
              mainAxisSpacing: 32,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = items[index];
                final deleting = deletingPostId == post.id;
                return Align(
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: deleting ? 0.45 : 1,
                    child: PostWidget(
                      post: post,
                      width: 162,
                      imageHeight: 214,
                      showSummaryOnHover: false,
                      onDeleteTap: deleting ? null : () => onDeleteTap(post),
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
        if (showFooterShimmer)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: _WatchlistGridShimmer(itemCount: 5, shrinkWrap: true),
            ),
          ),
      ],
    );
  }
}

class _WatchlistGridShimmer extends StatelessWidget {
  const _WatchlistGridShimmer({
    this.itemCount = 20,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisExtent: 266,
        crossAxisSpacing: 16,
        mainAxisSpacing: 32,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const Align(
        alignment: Alignment.topCenter,
        child: _WatchlistShimmerCard(),
      ),
    );
  }
}

class _WatchlistShimmerCard extends StatelessWidget {
  const _WatchlistShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.08,
      child: SizedBox(
        width: 162,
        child: Column(
          children: [
            Container(
              width: 162,
              height: 214,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 12,
              width: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
