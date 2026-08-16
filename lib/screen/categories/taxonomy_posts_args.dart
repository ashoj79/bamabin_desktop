class TaxonomyPostsArgs {
  const TaxonomyPostsArgs({
    required this.taxonomy,
    required this.id,
    required this.title,
  });

  final String taxonomy;
  final int id;
  final String title;

  static TaxonomyPostsArgs fromExtra(Object? extra) {
    if (extra is TaxonomyPostsArgs) return extra;
    if (extra is Map) {
      return TaxonomyPostsArgs(
        taxonomy: extra['taxonomy'] as String? ?? 'genres',
        id: extra['id'] as int? ?? 0,
        title: extra['title'] as String? ?? 'آرشیو',
      );
    }
    return const TaxonomyPostsArgs(
      taxonomy: 'genres',
      id: 0,
      title: 'آرشیو',
    );
  }
}
