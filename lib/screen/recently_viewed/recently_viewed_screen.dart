import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_empty_state.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:bamabin_desktop/screen/recently_viewed/bloc/recently_viewed_bloc.dart';
import 'package:bamabin_desktop/screen/watch_status/widgets/shelf_delete_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<RecentlyViewedBloc>().add(RecentlyViewedLoadEvent());
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
      context.read<RecentlyViewedBloc>().add(RecentlyViewedLoadMoreEvent());
    }
  }

  Future<void> _onDeleteTap(PlayStatus item) async {
    final post = item.post;
    final title = post.faTitle.isNotEmpty ? post.faTitle : post.title;
    final confirmed = await showShelfDeleteConfirmDialog(
      context,
      message: title.isNotEmpty
          ? 'آیا می‌خواهید «$title» را از مشاهده‌های اخیر حذف کنید؟'
          : 'آیا می‌خواهید این مورد را از مشاهده‌های اخیر حذف کنید؟',
    );
    if (!confirmed || !mounted) return;
    context.read<RecentlyViewedBloc>().add(
      RecentlyViewedDeleteEvent(post.id),
    );
  }

  Future<void> _onClearAllTap() async {
    final confirmed = await showShelfDeleteConfirmDialog(
      context,
      message: 'آیا می‌خواهید تمامی مشاهده‌های اخیر خود را پاک کنید؟',
    );
    if (!confirmed || !mounted) return;
    context.read<RecentlyViewedBloc>().add(RecentlyViewedClearAllEvent());
  }

  void _openPost(PlayStatus item) {
    context.push(Routes.postDetails, extra: item.post);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0C14),
      child: BlocConsumer<RecentlyViewedBloc, RecentlyViewedState>(
        listenWhen: (previous, current) {
          if (current is! RecentlyViewedSuccess) return false;
          if (previous is! RecentlyViewedSuccess) {
            return current.feedbackMessage != null;
          }
          return current.feedbackMessage != null &&
              current.feedbackMessage != previous.feedbackMessage;
        },
        listener: (context, state) {
          if (state is! RecentlyViewedSuccess) return;
          final message = state.feedbackMessage;
          if (message == null || message.isEmpty) return;
          showBamabinSnackbar(context, message);
          context
              .read<RecentlyViewedBloc>()
              .add(RecentlyViewedClearFeedbackEvent());
        },
        builder: (context, state) {
          final canClearAll = switch (state) {
            RecentlyViewedSuccess(:final items, :final isBusy) =>
              items.isNotEmpty && !isBusy,
            _ => false,
          };

          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RecentlyViewedHeader(
                  canClearAll: canClearAll,
                  onClearAll: _onClearAllTap,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: switch (state) {
                    RecentlyViewedInitial() || RecentlyViewedLoading() =>
                      const _RecentlyViewedGridShimmer(),
                    RecentlyViewedError(:final message) => Center(
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
                                .read<RecentlyViewedBloc>()
                                .add(RecentlyViewedLoadEvent()),
                            child: Text(
                              'تلاش مجدد',
                              style: TextStyle(color: blueColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RecentlyViewedLoadingMore(:final items) =>
                      _RecentlyViewedGrid(
                        items: items,
                        controller: _scrollController,
                        showFooterShimmer: true,
                        onDeleteTap: _onDeleteTap,
                        onContinueTap: _openPost,
                      ),
                    RecentlyViewedSuccess(
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
                                      'نتیجه ای برای مشاهده های اخیر شما پیدا نشد.',
                                )
                              : _RecentlyViewedGrid(
                                  items: items,
                                  controller: _scrollController,
                                  deletingPostId: deletingPostId,
                                  onDeleteTap: _onDeleteTap,
                                  onContinueTap: _openPost,
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

class _RecentlyViewedHeader extends StatelessWidget {
  const _RecentlyViewedHeader({
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
            'مشاهده های اخیر',
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
                  'حذف تمامی مشاهده‌های اخیر',
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

class _RecentlyViewedGrid extends StatelessWidget {
  const _RecentlyViewedGrid({
    required this.items,
    required this.controller,
    required this.onDeleteTap,
    required this.onContinueTap,
    this.showFooterShimmer = false,
    this.deletingPostId,
  });

  final List<PlayStatus> items;
  final ScrollController controller;
  final ValueChanged<PlayStatus> onDeleteTap;
  final ValueChanged<PlayStatus> onContinueTap;
  final bool showFooterShimmer;
  final int? deletingPostId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1400
            ? 4
            : constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;

        return CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 48),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 164,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final deleting = deletingPostId == item.post.id;
                    return Opacity(
                      opacity: deleting ? 0.45 : 1,
                      child: _RecentlyViewedCard(
                        item: item,
                        onDeleteTap: deleting ? null : () => onDeleteTap(item),
                        onContinueTap: () => onContinueTap(item),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            if (showFooterShimmer)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: _RecentlyViewedGridShimmer(
                    itemCount: columns,
                    shrinkWrap: true,
                    columns: columns,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentlyViewedCard extends StatelessWidget {
  const _RecentlyViewedCard({
    required this.item,
    required this.onContinueTap,
    this.onDeleteTap,
  });

  final PlayStatus item;
  final VoidCallback onContinueTap;
  final VoidCallback? onDeleteTap;

  String get _title {
    final post = item.post;
    return post.faTitle.isNotEmpty ? post.faTitle : post.title;
  }

  String get _remainingLabel {
    final raw = item.remainingTime.trim();
    if (raw.isEmpty) return '';
    if (raw.contains('باقی')) return raw;
    return '$raw باقی مانده';
  }

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    final bg = post.bgThumbnail.isNotEmpty ? post.bgThumbnail : post.thumbnail;
    final poster = post.thumbnail.isNotEmpty ? post.thumbnail : post.bgThumbnail;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bg.isNotEmpty)
            Opacity(
              opacity: 0.5,
              child: CachedNetworkImage(
                imageUrl: bg,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF14141F)),
              ),
            )
          else
            const ColoredBox(color: Color(0xFF14141F)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Colors.black,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (poster.isNotEmpty)
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x36000000),
                          offset: Offset(-10, 0),
                          blurRadius: 26.9,
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 134 / 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: poster,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFF1C1C2B)),
                        ),
                      ),
                    ),
                  ),
                if (poster.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'vazir',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              if (_remainingLabel.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _remainingLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'vazir',
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: onContinueTap,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ادامه تماشا',
                                        style: TextStyle(
                                          fontFamily: 'vazir',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.18,
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SvgPicture.asset(
                                        'assets/img/hero_play_circle.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: ColorFilter.mode(
                                          Colors.white.withValues(alpha: 0.75),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (onDeleteTap != null) ...[
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: onDeleteTap,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                    ),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/img/trash.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedGridShimmer extends StatelessWidget {
  const _RecentlyViewedGridShimmer({
    this.itemCount = 8,
    this.shrinkWrap = false,
    this.columns,
  });

  final int itemCount;
  final bool shrinkWrap;
  final int? columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = columns ??
            (constraints.maxWidth >= 1400
                ? 4
                : constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1);

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 164,
          ),
          itemBuilder: (_, _) => const _RecentlyViewedCardShimmer(),
        );
      },
    );
  }
}

class _RecentlyViewedCardShimmer extends StatelessWidget {
  const _RecentlyViewedCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.08,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
