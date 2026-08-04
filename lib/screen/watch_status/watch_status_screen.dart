import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/watching_card.dart';
import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:bamabin_desktop/screen/watch_status/bloc/watch_status_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _bg = Color(0xFF0A0A12);
const _muted = Color(0xFFA8AABB);
const _ink = Color(0xFFF4F4F8);

class WatchStatusScreen extends StatefulWidget {
  const WatchStatusScreen({super.key});

  @override
  State<WatchStatusScreen> createState() => _WatchStatusScreenState();
}

class _WatchStatusScreenState extends State<WatchStatusScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<WatchStatusBloc>().add(WatchStatusLoadEvent());
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
      context.read<WatchStatusBloc>().add(WatchStatusLoadMoreEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.profile);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, color: _ink),
                  tooltip: 'بازگشت',
                ),
                const SizedBox(width: 4),
                const Text(
                  'در حال تماشا',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: BlocBuilder<WatchStatusBloc, WatchStatusState>(
                builder: (context, state) {
                  return switch (state) {
                    WatchStatusInitial() || WatchStatusLoading() =>
                      const _WatchingGridShimmer(),
                    WatchStatusError(:final message) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context
                                .read<WatchStatusBloc>()
                                .add(WatchStatusLoadEvent()),
                            child: Text(
                              'تلاش مجدد',
                              style: TextStyle(color: blueColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    WatchStatusLoadingMore(:final items) => _WatchingGrid(
                      items: items,
                      controller: _scrollController,
                      showFooterShimmer: true,
                    ),
                    WatchStatusSuccess(:final items) => items.isEmpty
                        ? const Center(
                            child: Text(
                              'موردی در حال تماشا نیست',
                              style: TextStyle(color: _muted),
                            ),
                          )
                        : _WatchingGrid(
                            items: items,
                            controller: _scrollController,
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

class _WatchingGrid extends StatelessWidget {
  const _WatchingGrid({
    required this.items,
    required this.controller,
    this.showFooterShimmer = false,
  });

  final List<PlayStatus> items;
  final ScrollController controller;
  final bool showFooterShimmer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 480
                    ? 2
                    : 1;

        return CustomScrollView(
          controller: controller,
          slivers: [
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => WatchingCard(item: items[index]),
                childCount: items.length,
              ),
            ),
            if (showFooterShimmer)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _WatchingGridShimmer(
                    itemCount: columns,
                    shrinkWrap: true,
                    columns: columns,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        );
      },
    );
  }
}

class _WatchingGridShimmer extends StatelessWidget {
  const _WatchingGridShimmer({
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
            (constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 700
                    ? 3
                    : constraints.maxWidth >= 480
                        ? 2
                        : 1);

        if (shrinkWrap) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, _) => const WatchingCardShimmer(),
          );
        }

        return GridView.builder(
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (_, _) => const WatchingCardShimmer(),
        );
      },
    );
  }
}
