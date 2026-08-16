import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_empty_state.dart';
import 'package:bamabin_desktop/core/widgets/filters.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/categories/bloc/taxonomy_posts_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class TaxonomyPostsScreen extends StatefulWidget {
  const TaxonomyPostsScreen({super.key, required this.title});

  final String title;

  @override
  State<TaxonomyPostsScreen> createState() => _TaxonomyPostsScreenState();
}

class _TaxonomyPostsScreenState extends State<TaxonomyPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TaxonomyPostsBloc>().add(TaxonomyPostsLoadEvent());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() => _maybeLoadMore();

  void _maybeLoadMore() {
    if (!mounted) return;
    final bloc = context.read<TaxonomyPostsBloc>();
    final hasMore = switch (bloc.state) {
      TaxonomyPostsSuccess(:final hasMore) => hasMore,
      TaxonomyPostsLoadingMore() => false,
      _ => false,
    };
    if (!hasMore) return;

    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final nearBottom = position.pixels >= position.maxScrollExtent - 400;
      final cannotScroll = position.maxScrollExtent <= 0;
      if (!nearBottom && !cannotScroll) return;
    }

    bloc.add(TaxonomyPostsLoadMoreEvent());
  }

  void _onFiltersChanged(TaxonomyPostsFiltersView filters) {
    context.read<TaxonomyPostsBloc>().add(
          TaxonomyPostsFiltersChangedEvent(
            postType: filters.postType,
            genreId: filters.genreId,
            orderBy: filters.orderBy,
            imdb: filters.imdb,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: BlocBuilder<TaxonomyPostsBloc, TaxonomyPostsState>(
        builder: (context, state) {
          final filters = state.filters;
          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: desktopInkColor,
                  ),
                ),
                const SizedBox(height: 20),
                Filters(
                  showPostTypes: true,
                  allowChangeGenre: !filters.lockGenre,
                  genre: filters.genreId,
                  order: filters.orderBy,
                  imdb: filters.imdb,
                  selectedPostType: filters.postType,
                  onGenreChanged: (genreId) => _onFiltersChanged(
                    TaxonomyPostsFiltersView(
                      postType: filters.postType,
                      genreId: genreId,
                      orderBy: filters.orderBy,
                      imdb: filters.imdb,
                      lockGenre: filters.lockGenre,
                    ),
                  ),
                  onOrderChanged: (order) => _onFiltersChanged(
                    TaxonomyPostsFiltersView(
                      postType: filters.postType,
                      genreId: filters.genreId,
                      orderBy: order,
                      imdb: filters.imdb,
                      lockGenre: filters.lockGenre,
                    ),
                  ),
                  onImdbChanged: (imdb) => _onFiltersChanged(
                    TaxonomyPostsFiltersView(
                      postType: filters.postType,
                      genreId: filters.genreId,
                      orderBy: filters.orderBy,
                      imdb: imdb,
                      lockGenre: filters.lockGenre,
                    ),
                  ),
                  onPostTypeChanged: (type) => _onFiltersChanged(
                    TaxonomyPostsFiltersView(
                      postType: type,
                      genreId: filters.genreId,
                      orderBy: filters.orderBy,
                      imdb: filters.imdb,
                      lockGenre: filters.lockGenre,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: switch (state) {
                    TaxonomyPostsInitial() || TaxonomyPostsLoading() =>
                      const _TaxonomyGridShimmer(),
                    TaxonomyPostsError(:final message) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context
                                  .read<TaxonomyPostsBloc>()
                                  .add(TaxonomyPostsLoadEvent()),
                              child: Text(
                                'تلاش مجدد',
                                style: TextStyle(color: blueColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TaxonomyPostsLoadingMore(:final items) => _TaxonomyGrid(
                        items: items,
                        controller: _scrollController,
                        showFooterShimmer: true,
                        onBuilt: _maybeLoadMore,
                      ),
                    TaxonomyPostsSuccess(:final items) => items.isEmpty
                        ? const BamabinEmptyState(
                            message: 'محتوایی در این دسته پیدا نشد',
                          )
                        : _TaxonomyGrid(
                            items: items,
                            controller: _scrollController,
                            onBuilt: _maybeLoadMore,
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

class _TaxonomyGrid extends StatefulWidget {
  const _TaxonomyGrid({
    required this.items,
    required this.controller,
    this.showFooterShimmer = false,
    this.onBuilt,
  });

  final List<Post> items;
  final ScrollController controller;
  final bool showFooterShimmer;
  final VoidCallback? onBuilt;

  @override
  State<_TaxonomyGrid> createState() => _TaxonomyGridState();
}

class _TaxonomyGridState extends State<_TaxonomyGrid> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBuilt?.call());
  }

  @override
  void didUpdateWidget(_TaxonomyGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBuilt?.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 400) {
          widget.onBuilt?.call();
        }
        return false;
      },
      child: CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisExtent: 266,
                crossAxisSpacing: 16,
                mainAxisSpacing: 32,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: PostWidget(
                      post: widget.items[index],
                      width: 162,
                      imageHeight: 214,
                      showSummaryOnHover: false,
                    ),
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
          if (widget.showFooterShimmer)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF29B6F6)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaxonomyGridShimmer extends StatelessWidget {
  const _TaxonomyGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisExtent: 266,
        crossAxisSpacing: 16,
        mainAxisSpacing: 32,
      ),
      itemCount: 20,
      itemBuilder: (_, _) => const Align(
        alignment: Alignment.topCenter,
        child: _TaxonomyShimmerCard(),
      ),
    );
  }
}

class _TaxonomyShimmerCard extends StatelessWidget {
  const _TaxonomyShimmerCard();

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
