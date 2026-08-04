import 'post.dart';
import 'like_info.dart';
import 'single_post.dart';

// --- MovieType Enum ---

enum MovieType { dubbed, subtitle, native_, screen }

// --- MovieInfo ---

class MovieInfo {
  final String name;
  final String link;
  final String quality;
  final String mainQuality;
  final String qualityCode;
  final String subtitleTypes;
  final String encoder;
  final String size;
  bool isWatched;
  bool isWatching;

  MovieInfo({
    this.name = '',
    required this.link,
    required this.quality,
    required this.mainQuality,
    required this.qualityCode,
    required this.subtitleTypes,
    this.encoder = '',
    this.size = '',
    this.isWatched = false,
    this.isWatching = false,
  });

  factory MovieInfo.fromJson(Map<String, dynamic> json) => MovieInfo(
    name: json['name'] ?? '',
    link: json['link'] ?? '',
    quality: json['quality'] ?? '',
    mainQuality: json['main_quality'] ?? '',
    qualityCode: json['quality_code'] ?? '',
    subtitleTypes: json['subtitle_types'] ?? '',
    encoder: json['encoder'] ?? '',
    size: json['size'] ?? '',
  );
}

// --- QualityInfo ---

class QualityInfo {
  final String quality;
  final String qualityCode;
  final String mainQuality;
  final String encoders;
  final String subtitleTypes;
  final String size;
  final List<MovieInfo> episodes;

  QualityInfo({
    required this.quality,
    required this.qualityCode,
    required this.mainQuality,
    required this.encoders,
    required this.subtitleTypes,
    required this.size,
    required this.episodes,
  });

  factory QualityInfo.fromJson(Map<String, dynamic> json) => QualityInfo(
    quality: json['quality'] ?? '',
    qualityCode: json['quality_code'] ?? '',
    mainQuality: json['main_quality'] ?? '',
    encoders: json['encoders'] ?? '',
    subtitleTypes: json['subtitle_types'] ?? '',
    size: json['size'] ?? '',
    episodes: (json['episodes'] as List?)
            ?.map((e) => MovieInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// --- Metadata ---

class Metadata {
  final int id;
  final String name;
  final String avatar;
  final String type;

  Metadata({
    required this.id,
    required this.name,
    required this.avatar,
    this.type = '',
  });

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    avatar: json['avatar'] ?? '',
    type: json['type'] ?? '',
  );
}

// --- Season ---

class Season {
  final String name;
  final SeriesDownloadBox items;

  Season({required this.name, required this.items});

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    name: json['name'] ?? '',
    items: SeriesDownloadBox.fromJson(json['items'] ?? {}),
  );
}

// --- SeasonEpisode ---

class SeasonEpisode {
  final MovieType type;
  final String label;
  final String episodeName;

  SeasonEpisode({
    required this.type,
    required this.label,
    required this.episodeName,
  });
}

// --- MovieDownloadBox ---

class MovieDownloadBox {
  final List<MovieInfo> subtitle;
  final List<MovieInfo> dubbed;
  final List<MovieInfo> nativeList;
  final List<MovieInfo> screen;

  MovieDownloadBox({
    this.subtitle = const [],
    this.dubbed = const [],
    this.nativeList = const [],
    this.screen = const [],
  });

  factory MovieDownloadBox.fromJson(Map<String, dynamic> json) =>
      MovieDownloadBox(
        subtitle: (json['subtitle'] as List?)
                ?.map((e) => MovieInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        dubbed: (json['dubbed'] as List?)
                ?.map((e) => MovieInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nativeList: (json['native'] as List?)
                ?.map((e) => MovieInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        screen: (json['screen'] as List?)
                ?.map((e) => MovieInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  String getLink(MovieType type, int index) {
    return _getListByType(type).map((e) => e.link).toList()[index];
  }

  String getQualityCode(MovieType type, int index) {
    return _getListByType(type).map((e) => e.qualityCode).toList()[index];
  }

  List<String> getItemInfo(MovieType movieType, int index) {
    final list = _getListByType(movieType);
    return [list[index].quality, list[index].qualityCode, list[index].encoder];
  }

  List<String> getQualities(MovieType type) {
    return _getListByType(type)
        .map((e) => '${e.quality} - ${e.encoder}')
        .toList();
  }

  List<MovieInfo> _getListByType(MovieType type) {
    switch (type) {
      case MovieType.dubbed:
        return dubbed;
      case MovieType.subtitle:
        return subtitle;
      case MovieType.native_:
        return nativeList;
      case MovieType.screen:
        return screen;
    }
  }
}

// --- SeriesDownloadBox ---

class SeriesDownloadBox {
  final List<QualityInfo> subtitle;
  final List<QualityInfo> dubbed;
  final List<QualityInfo> nativeList;
  final List<QualityInfo> screen;

  SeriesDownloadBox({
    this.subtitle = const [],
    this.dubbed = const [],
    this.nativeList = const [],
    this.screen = const [],
  });

  factory SeriesDownloadBox.fromJson(Map<String, dynamic> json) =>
      SeriesDownloadBox(
        subtitle: (json['subtitle'] as List?)
                ?.map((e) => QualityInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        dubbed: (json['dubbed'] as List?)
                ?.map((e) => QualityInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nativeList: (json['native'] as List?)
                ?.map((e) => QualityInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        screen: (json['screen'] as List?)
                ?.map((e) => QualityInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  List<QualityInfo> _getListByType(MovieType type) {
    switch (type) {
      case MovieType.dubbed:
        return dubbed;
      case MovieType.subtitle:
        return subtitle;
      case MovieType.native_:
        return nativeList;
      case MovieType.screen:
        return screen;
    }
  }

  List<MovieInfo> _getAllEpisodeItems(MovieType type, int episodeIndex) {
    final allEpisodeItems = <MovieInfo>[];
    for (final q in _getListByType(type)) {
      if (episodeIndex < q.episodes.length) {
        allEpisodeItems.add(q.episodes[episodeIndex]);
      }
    }
    return allEpisodeItems;
  }

  int _getDefaultItemIndex(List<MovieInfo> items) {
    const qualities = ['720', '1080', '480'];
    for (final q in qualities) {
      for (int i = 0; i < items.length; i++) {
        if (items[i].mainQuality.contains(q) &&
            items[i].mainQuality.contains('x264')) {
          return i;
        }
      }
    }
    return 0;
  }

  String getLink(MovieType type, int episodeIndex, {int qualityIndex = -1}) {
    final items = _getAllEpisodeItems(type, episodeIndex);
    return qualityIndex == -1
        ? items[_getDefaultItemIndex(items)].link
        : items[qualityIndex].link;
  }

  String getName(MovieType type, int episodeIndex, {int qualityIndex = -1}) {
    final items = _getAllEpisodeItems(type, episodeIndex);
    return qualityIndex == -1
        ? items[_getDefaultItemIndex(items)].name
        : items[qualityIndex].name;
  }

  String getQualityCode(MovieType type, int episodeIndex, int qualityIndex) {
    final items = _getAllEpisodeItems(type, episodeIndex);
    return qualityIndex == -1
        ? items[_getDefaultItemIndex(items)].qualityCode
        : items[qualityIndex].qualityCode;
  }

  int getDefaultQualityIndex(MovieType type, int episodeIndex) {
    return _getDefaultItemIndex(_getAllEpisodeItems(type, episodeIndex));
  }

  List<String> getAllQualities(MovieType type, int episodeIndex) {
    return _getAllEpisodeItems(type, episodeIndex)
        .map((e) => '${e.quality} - ${e.encoder}')
        .toList();
  }

  List<String> getAllQualityCodes(MovieType type, int episodeIndex) {
    return _getAllEpisodeItems(type, episodeIndex)
        .map((e) => e.qualityCode)
        .toList();
  }

  List<String> getEpisodeInfo(
    MovieType type,
    int episodeIndex,
    int qualityIndex,
  ) {
    final info = _getAllEpisodeItems(type, episodeIndex)[qualityIndex];
    return [info.quality, info.qualityCode];
  }

  List<SeasonEpisode> getAllEpisodeItemsByOrder(MovieType type) {
    final data = <SeasonEpisode>[];

    final orderedTypes = {
      MovieType.dubbed: [
        MovieType.dubbed,
        MovieType.subtitle,
        MovieType.native_,
        MovieType.screen,
      ],
      MovieType.subtitle: [
        MovieType.subtitle,
        MovieType.dubbed,
        MovieType.native_,
        MovieType.screen,
      ],
      MovieType.native_: [
        MovieType.native_,
        MovieType.dubbed,
        MovieType.subtitle,
        MovieType.screen,
      ],
      MovieType.screen: [
        MovieType.screen,
        MovieType.dubbed,
        MovieType.subtitle,
        MovieType.native_,
      ],
    }[type]!;

    final labelMap = {
      MovieType.dubbed: type == MovieType.dubbed ? '' : 'دوبله',
      MovieType.subtitle: type == MovieType.subtitle ? '' : 'زیرنویس',
      MovieType.native_: type == MovieType.native_ ? '' : 'اصلی',
      MovieType.screen: type == MovieType.screen ? '' : 'کیفیت پرده',
    };

    for (final t in orderedTypes) {
      for (final q in _getListByType(t)) {
        for (final e in q.episodes) {
          if (!data.any((d) => d.episodeName == e.name)) {
            data.add(SeasonEpisode(
              type: t,
              label: labelMap[t]!,
              episodeName: e.name,
            ));
          }
        }
      }
    }

    return data;
  }

  QualityInfo getMaximumEpisodes(MovieType type) {
    final dataList = _getListByType(type);
    var previousInfo = dataList.first;
    for (final item in dataList) {
      if (item.episodes.length > previousInfo.episodes.length) {
        previousInfo = item;
      }
    }
    return previousInfo;
  }

  int getEpisodesCount() {
    int maxCount(List<QualityInfo> list) {
      int max = 0;
      for (final q in list) {
        if (q.episodes.length > max) max = q.episodes.length;
      }
      return max;
    }

    return [
      maxCount(dubbed),
      maxCount(subtitle),
      maxCount(screen),
      maxCount(nativeList),
    ].reduce((a, b) => a > b ? a : b);
  }
}

// --- PostDetails ---

class PostDetails {
  final int id;
  final String title;
  final String faTitle;
  final String link;
  final String trailer;
  final String bgThumbnail;
  final String imdbRate;
  final int imdbVoteCount;
  final bool hasDubbed;
  final bool hasSubtitle;
  final List<Metadata> years;
  final String summary;
  final String postType;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season>? seasons;
  final String status;
  final String movieStatus;
  final String updateText;
  final String ageRate;
  LikeInfo? likeInfo;
  bool isInWatchlist;
  final bool isFree;
  final String awardsSummary;
  final String top250movie;
  final String rotten;
  final String metacritic;
  final String mal;
  final String mdl;
  final String? message;
  final List<Metadata> countries;
  final List<Metadata> languages;
  final List<Metadata> networks;
  final List<Metadata> agents;
  final List<String> days;
  final List<Post> relatedPosts;
  final List<Post> collectionPosts;
  String watchStatus;
  int watchSeasonId;
  int watchEpisodeId;
  String? userRate;
  final int _time;
  final List<int> _genresId;
  final String _type;

  PostDetails({
    required this.id,
    required this.title,
    required this.faTitle,
    required this.link,
    required this.trailer,
    required this.bgThumbnail,
    required this.imdbRate,
    required this.imdbVoteCount,
    required this.hasDubbed,
    required this.hasSubtitle,
    required this.years,
    required this.summary,
    required this.postType,
    this.movieDownloadBox,
    this.seasons,
    required this.status,
    required this.movieStatus,
    required this.updateText,
    required this.ageRate,
    this.likeInfo,
    required this.isInWatchlist,
    required this.isFree,
    required this.awardsSummary,
    required this.top250movie,
    required this.rotten,
    required this.metacritic,
    required this.mal,
    required this.mdl,
    this.message,
    this.countries = const [],
    this.languages = const [],
    this.networks = const [],
    this.agents = const [],
    this.days = const [],
    required this.relatedPosts,
    required this.collectionPosts,
    required this.watchStatus,
    required this.watchSeasonId,
    required this.watchEpisodeId,
    this.userRate,
    required int time,
    required List<int> genresId,
    required String type,
  })  : _time = time,
        _genresId = genresId,
        _type = type;

  bool get isSeries => _type == 'series';

  bool get isPublished => movieStatus != 'soon';

  String getTime() => '${_time ~/ 60} دقیقه';

  String getTypeName() {
    switch (postType) {
      case 'movies':
        return 'فیلم';
      case 'series':
        return 'سریال';
      case 'anime':
        return 'انیمه';
      default:
        return 'انیمیشن';
    }
  }

  String getWatchStatusName() {
    switch (watchStatus) {
      case 'watching':
        return 'دارم می‌بینم';
      case 'watched':
        return 'دیدمش رفت';
      default:
        return 'می‌خوام ببینم';
    }
  }

  List<int> get genresId => _genresId;

  Post toPost() => Post(
    id: id,
    title: title,
    faTitle: faTitle,
    thumbnail: bgThumbnail,
    bgThumbnail: bgThumbnail,
    imdbRate: imdbRate,
    hasAudio: hasDubbed,
    genresId: _genresId,
    years: years.map((e) => int.tryParse(e.name) ?? 0).toList(),
    summary: summary,
  );

  static PostDetails fromSinglePost(SinglePost singlePost) => PostDetails(
    id: singlePost.mainData.id,
    title: singlePost.title,
    faTitle: singlePost.mainData.faTitle,
    link: '',
    trailer: '',
    bgThumbnail: singlePost.mainData.bgThumbnail,
    imdbRate: '',
    imdbVoteCount: 0,
    hasDubbed: singlePost.mainData.hasAudio,
    hasSubtitle: true,
    years: [],
    summary: '',
    postType: singlePost.postType,
    movieDownloadBox: singlePost.movieDownloadBox,
    seasons: singlePost.seasons,
    status: '',
    movieStatus: '',
    updateText: '',
    ageRate: '',
    likeInfo: null,
    isInWatchlist: false,
    isFree: false,
    awardsSummary: '',
    top250movie: '',
    rotten: '',
    metacritic: '',
    mal: '',
    mdl: '',
    relatedPosts: [],
    collectionPosts: [],
    watchStatus: '',
    watchSeasonId: 1,
    watchEpisodeId: 1,
    time: 0,
    genresId: [],
    type: singlePost.type,
  );

  factory PostDetails.fromJson(Map<String, dynamic> json) => PostDetails(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    faTitle: json['fa_title'] ?? '',
    link: json['link'] ?? '',
    trailer: json['trailer'] ?? '',
    bgThumbnail: json['bg_thumbnail'] ?? '',
    imdbRate: json['imdb_rate'] ?? '',
    imdbVoteCount: json['imdb_votes'] ?? 0,
    hasDubbed: json['has_dubbed'] ?? false,
    hasSubtitle: json['has_subtitle'] ?? false,
    years: (json['years'] as List?)
            ?.map((e) => Metadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    summary: json['summary'] ?? '',
    postType: json['post_type'] ?? '',
    movieDownloadBox: json['movies_dlbox'] != null
        ? MovieDownloadBox.fromJson(json['movies_dlbox'])
        : null,
    seasons: json['series_dlbox'] != null
        ? (json['series_dlbox'] as List)
              .map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    status: json['status'] ?? '',
    movieStatus: json['movie_status'] ?? '',
    updateText: json['update_text'] ?? '',
    ageRate: json['age_rate'] ?? '',
    likeInfo:
        json['like_info'] != null ? LikeInfo.fromJson(json['like_info']) : null,
    isInWatchlist: json['is_in_watchlist'] ?? false,
    isFree: json['is_free'] ?? false,
    awardsSummary: json['awards_summary'] ?? '',
    top250movie: json['top250movie'] ?? '',
    rotten: json['rotten_tomatometer'] ?? '',
    metacritic: json['metacritic'] ?? '',
    mal: json['mal'] ?? '',
    mdl: json['mdl'] ?? '',
    message: json['message'],
    countries: (json['countries'] as List?)
            ?.map((e) => Metadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    languages: (json['languages'] as List?)
            ?.map((e) => Metadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    networks: (json['networks'] as List?)
            ?.map((e) => Metadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    agents: (json['agents'] as List?)
            ?.map((e) => Metadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    days: (json['play_days'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    relatedPosts: (json['related_posts'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    collectionPosts: (json['collection_posts'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    watchStatus: json['watch_status'] ?? '',
    watchSeasonId: int.tryParse(json['watch_season_id'].toString()) ?? 0,
    watchEpisodeId: int.tryParse(json['watch_episode_id'].toString()) ?? 0,
    userRate: json['user_rate'],
    time: json['time'] ?? 0,
    genresId:
        (json['genres_id'] as List?)?.map((e) => e as int).toList() ?? [],
    type: json['type'] ?? '',
  );
}
