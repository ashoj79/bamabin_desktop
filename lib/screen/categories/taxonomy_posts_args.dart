class TaxonomyPostsArgs {
  const TaxonomyPostsArgs({
    required this.taxonomy,
    required this.id,
    required this.title,
    this.archiveType = '',
    this.broadcastStatus = '',
    this.dlboxType = '',
    this.miniSerial = '',
    this.free = '',
    this.dubbed = '',
    this.orderBy = '',
  });

  const TaxonomyPostsArgs.archive({
    required this.title,
    this.archiveType = '',
    this.broadcastStatus = '',
    this.dlboxType = '',
    this.miniSerial = '',
    this.free = '',
    this.dubbed = '',
    this.orderBy = '',
  })  : taxonomy = '',
        id = 0;

  final String taxonomy;
  final int id;
  final String title;
  final String archiveType;
  final String broadcastStatus;
  final String dlboxType;
  final String miniSerial;
  final String free;
  final String dubbed;
  final String orderBy;

  bool get isArchive => taxonomy.isEmpty;

  static String _flag(Object? value) {
    if (value == true || value == 'on' || value == '1' || value == 'true') {
      return 'on';
    }
    return '';
  }

  static TaxonomyPostsArgs fromExtra(Object? extra) {
    if (extra is TaxonomyPostsArgs) return extra;
    if (extra is Map) {
      final taxonomy = extra['taxonomy'] as String? ?? '';
      final title = extra['title'] as String? ?? 'آرشیو';
      if (taxonomy.isNotEmpty) {
        final idValue = extra['id'];
        final id = idValue is int
            ? idValue
            : int.tryParse(idValue?.toString() ?? '') ?? 0;
        return TaxonomyPostsArgs(
          taxonomy: taxonomy,
          id: id,
          title: title,
        );
      }
      return TaxonomyPostsArgs.archive(
        title: title,
        archiveType: extra['postTypes'] as String? ?? '',
        broadcastStatus: extra['broadcastStatus'] as String? ?? '',
        dlboxType: extra['dlboxType'] as String? ?? '',
        miniSerial: _flag(extra['miniSerial']),
        free: _flag(extra['free']),
        dubbed: _flag(extra['dubbed']),
        orderBy: extra['orderBy'] as String? ?? '',
      );
    }
    return const TaxonomyPostsArgs(
      taxonomy: 'genres',
      id: 0,
      title: 'آرشیو',
    );
  }
}
