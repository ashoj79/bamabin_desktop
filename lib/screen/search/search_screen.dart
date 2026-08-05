import 'dart:async';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:bamabin_desktop/screen/search/widgets/search_advanced_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  var _query = '';
  var _showAdvanced = false;
  var _filters = const SearchFilters();
  var _showingFilterResults = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<SearchBloc>().add(SearchResetEvent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() => _maybeLoadMore();

  void _maybeLoadMore() {
    if (!mounted) return;
    final bloc = context.read<SearchBloc>();
    final state = bloc.state;
    final hasMore = switch (state) {
      SearchSuccess(:final hasMore) => hasMore,
      SearchLoadingMore() => false,
      _ => false,
    };
    if (!hasMore) return;

    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final nearBottom =
          position.pixels >= position.maxScrollExtent - 400;
      // First pages often fit the viewport (no scroll); still load more.
      final cannotScroll = position.maxScrollExtent <= 0;
      if (!nearBottom && !cannotScroll) return;
    }

    bloc.add(SearchLoadMoreEvent());
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      if (value.trim().length >= 2) {
        _showingFilterResults = false;
      }
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryEvent(value));
    });
  }

  void _toggleAdvanced() {
    setState(() => _showAdvanced = !_showAdvanced);
  }

  void _onAdvancedSubmit(SearchFilters filters) {
    setState(() {
      _filters = filters;
      _showAdvanced = false;
      _showingFilterResults = true;
    });
    context.read<SearchBloc>().add(
          SearchFiltersSubmitEvent(
            query: _controller.text,
            filters: filters,
          ),
        );
  }

  bool get _showEmptyHint {
    if (_showingFilterResults) return false;
    return _query.trim().length < 2;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _SearchBarRow(
                  controller: _controller,
                  advancedOpen: _showAdvanced,
                  onChanged: _onQueryChanged,
                  onSettingsTap: _toggleAdvanced,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: _showEmptyHint
                      ? const _EmptySearchHint()
                      : BlocConsumer<SearchBloc, SearchState>(
                          listenWhen: (prev, next) =>
                              next is SearchSuccess && next.hasMore,
                          listener: (context, state) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _maybeLoadMore();
                            });
                          },
                          builder: (context, state) {
                            return switch (state) {
                              SearchInitial() => const _EmptySearchHint(),
                              SearchLoading() => const _PostsShimmerGrid(),
                              SearchError(:final message) => Center(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              SearchLoadingMore(:final posts) => _ResultsGrid(
                                  posts: posts,
                                  controller: _scrollController,
                                  showFooterShimmer: true,
                                ),
                              SearchSuccess(:final posts) => posts.isEmpty
                                  ? Center(
                                      child: Text(
                                        'نتیجه‌ای یافت نشد',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    )
                                  : NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification
                                            is ScrollUpdateNotification) {
                                          _maybeLoadMore();
                                        }
                                        return false;
                                      },
                                      child: _ResultsGrid(
                                        posts: posts,
                                        controller: _scrollController,
                                      ),
                                    ),
                            };
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_showAdvanced) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showAdvanced = false),
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: 78,
              left: 32,
              child: SearchAdvancedPanel(
                initial: _filters,
                onSubmit: _onAdvancedSubmit,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBarRow extends StatelessWidget {
  const _SearchBarRow({
    required this.controller,
    required this.onChanged,
    required this.onSettingsTap,
    required this.advancedOpen,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSettingsTap;
  final bool advancedOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SearchField(
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white.withValues(alpha: 0.09),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: advancedOpen
                  ? blueColor.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: InkWell(
            onTap: onSettingsTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: SvgPicture.asset(
                  'assets/img/search_settings.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: -0.18,
        ),
        cursorColor: blueColor,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'جستجو فیلم، سریال و ...',
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: -0.18,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.09),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: blueColor.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }
}

class _EmptySearchHint extends StatelessWidget {
  const _EmptySearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/img/search_empty.svg',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          Text(
            'برای جست و جو حداقل 2 کاراکتر وارد نمایید.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 24 / 20,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({
    required this.posts,
    required this.controller,
    this.showFooterShimmer = false,
  });

  final List<Post> posts;
  final ScrollController controller;
  final bool showFooterShimmer;

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
              (context, index) => Align(
                alignment: Alignment.topCenter,
                child: PostWidget(
                  post: posts[index],
                  width: 162,
                  imageHeight: 214,
                ),
              ),
              childCount: posts.length,
            ),
          ),
        ),
        if (showFooterShimmer)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: _PostsShimmerGrid(itemCount: 5, shrinkWrap: true),
            ),
          ),
      ],
    );
  }
}

class _PostsShimmerGrid extends StatelessWidget {
  const _PostsShimmerGrid({
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
      itemBuilder: (context, index) => const _PostShimmerCard(),
    );
  }
}

class _PostShimmerCard extends StatelessWidget {
  const _PostShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.08,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
