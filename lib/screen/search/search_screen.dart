import 'dart:async';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<SearchBloc>().add(SearchLoadMoreEvent());
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQueryEvent(value));
    });
  }

  bool get _showTrends => _query.trim().length < 2;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchField(
              controller: _controller,
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 26),
            Expanded(
              child: _showTrends
                  ? _TrendsView(posts: TempDb.promotions)
                  : BlocBuilder<SearchBloc, SearchState>(
                      builder: (context, state) {
                        return switch (state) {
                          SearchInitial() => _TrendsView(
                            posts: TempDb.promotions,
                          ),
                          SearchLoading() => const _PostsShimmerGrid(),
                          SearchError(:final message) => Center(
                            child: Text(
                              message,
                              style: TextStyle(color: desktopMutedColor),
                            ),
                          ),
                          SearchLoadingMore(:final posts) => _ResultsView(
                            title: 'نتایج جستجو',
                            posts: posts,
                            controller: _scrollController,
                            showFooterShimmer: true,
                          ),
                          SearchSuccess(:final posts) => posts.isEmpty
                              ? Center(
                                  child: Text(
                                    'نتیجه‌ای یافت نشد',
                                    style: TextStyle(color: desktopMutedColor),
                                  ),
                                )
                              : _ResultsView(
                                  title: 'نتایج جستجو',
                                  posts: posts,
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
      height: 50,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: desktopInkColor),
        cursorColor: blueColor,
        decoration: InputDecoration(
          hintText: 'جستجو در فیلم‌ها، سریال‌ها و...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: desktopNavInactiveColor,
          ),
          filled: true,
          fillColor: const Color(0xFF12121A),
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
            child: Icon(Icons.search, size: 18, color: desktopNavInactiveColor),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF222228), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: blueColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _TrendsView extends StatelessWidget {
  const _TrendsView({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'موردی برای نمایش نیست',
          style: TextStyle(color: desktopMutedColor),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'ترند امروز',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: desktopInkColor,
              ),
            ),
          ),
        ),
        _PostsGridSliver(posts: posts),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.title,
    required this.posts,
    required this.controller,
    this.showFooterShimmer = false,
  });

  final String title;
  final List<Post> posts;
  final ScrollController controller;
  final bool showFooterShimmer;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: desktopInkColor,
              ),
            ),
          ),
        ),
        _PostsGridSliver(posts: posts),
        if (showFooterShimmer)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: _PostsShimmerGrid(itemCount: 4, shrinkWrap: true),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

class _PostsGridSliver extends StatelessWidget {
  const _PostsGridSliver({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisExtent: 278,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Align(
          alignment: Alignment.topCenter,
          child: PostWidget(post: posts[index]),
        ),
        childCount: posts.length,
      ),
    );
  }
}

class _PostsShimmerGrid extends StatelessWidget {
  const _PostsShimmerGrid({
    this.itemCount = 12,
    this.shrinkWrap = false,
  });

  final int itemCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisExtent: 278,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _PostShimmerCard(),
    );

    if (shrinkWrap) return grid;
    return grid;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 72,
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
