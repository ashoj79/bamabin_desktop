import 'package:bamabin_desktop/data/remote/model/videos/slider_post.dart';

import 'post.dart';
import 'genre.dart';
import 'country.dart';
import 'single_post.dart';
import 'post_details.dart';

// --- HomeSection (abstract base) ---

abstract class HomeSection {
  static List<HomeSection> createFromJson(List<dynamic> json) {
    final homeSections = <HomeSection>[];

    for (final item in json) {
      final type = item['type'] as String;
      switch (type) {
        case 'list':
          homeSections.add(ListSection.fromJson(item));
        case 'genres':
          homeSections.add(GenresSection.fromJson(item));
        case 'single':
          homeSections.add(SingleSection.fromJson(item));
        case 'slider':
          homeSections.add(SliderSection.fromJson(item));
        case 'app_notices':
          homeSections.add(NoticesSection.fromJson(item));
      }
    }

    return _sortSections(homeSections);
  }

  static List<HomeSection> _sortSections(List<HomeSection> sections) {
    SliderSection? sliderSection;
    GenresSection? genresSection;
    NoticesSection? noticesSection;
    final othersSections = <HomeSection>[];

    for (final s in sections) {
      if (s is SliderSection) {
        sliderSection = s;
      } else if (s is GenresSection) {
        genresSection = s;
      } else if (s is NoticesSection) {
        noticesSection = s;
      } else {
        othersSections.add(s);
      }
    }

    final sorted = <HomeSection>[];
    if (sliderSection != null) sorted.add(sliderSection);
    if (noticesSection != null) sorted.add(noticesSection);
    if (genresSection != null) sorted.add(genresSection);
    sorted.addAll(othersSections);

    return sorted;
  }
}

// --- Helper to parse Post from JSON map ---

Post _parsePost(Map<String, dynamic> postData) {
  final genresId =
      (postData['genres_id'] as List?)?.map((e) => e as int).toList() ?? [];
  final years =
      (postData['years'] as List?)?.map((e) => e as int).toList() ?? [];

  return Post(
    id: postData['id'] ?? 0,
    title: postData['title'] ?? '',
    faTitle: postData['fa_title'] ?? '',
    thumbnail: postData['thumbnail'] ?? '',
    bgThumbnail: postData['bg_thumbnail'] ?? '',
    imdbRate: postData['imdb_rate'] ?? '',
    hasAudio: postData['has_dubbed'] ?? false,
    genresId: genresId,
    years: years,
  );
}

SliderPost _parseSliderPost(Map<String, dynamic> postData) {
  final post = _parsePost(postData);
  final time = postData['time'];
  final summary = postData['summary'];
  return SliderPost(post: post, time: time, summary: summary);
}

// --- ListSection ---

class ListSection extends HomeSection {
  final String name;
  final String? taxonomy;
  final String? taxonomyId;
  final bool miniSerial;
  final List<String> broadcastStatuses;
  final String dlboxType;
  final List<String> postTypes;
  final String orderBy;
  final bool isFree;
  final bool isDubbed;
  final List<Post> posts;

  ListSection({
    required this.name,
    this.taxonomy,
    this.taxonomyId,
    this.miniSerial = false,
    this.broadcastStatuses = const [],
    this.dlboxType = '',
    this.postTypes = const [],
    this.orderBy = '',
    this.isFree = false,
    this.isDubbed = false,
    this.posts = const [],
  });

  factory ListSection.fromJson(Map<String, dynamic> data) {
    final posts = <Post>[];
    for (final postData in (data['posts'] as List? ?? [])) {
      posts.add(_parsePost(postData));
    }

    final broadcastStatuses = (data['broadcast_status'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final postTypes = (data['post_type'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final taxonomy = data['taxonomy'] as String?;
    final taxonomyId = data['taxonomy_id'] as String?;
    final miniSerial =
        (taxonomy == null && data.containsKey('mini_serial'))
            ? (data['mini_serial'] ?? false)
            : false;
    final isFree = data['free'] ?? false;
    final isDubbed = data['should_dubbed'] ?? false;
    final dlboxType = data['dlbox_type'] ?? '';
    final orderBy = data['order_by'] ?? '';

    return ListSection(
      name: data['name'] ?? '',
      taxonomy: taxonomy,
      taxonomyId: taxonomyId,
      miniSerial: miniSerial,
      broadcastStatuses: broadcastStatuses,
      dlboxType: dlboxType,
      postTypes: postTypes,
      orderBy: orderBy,
      isFree: isFree,
      isDubbed: isDubbed,
      posts: posts,
    );
  }
}

// --- SliderSection ---

class SliderSection extends HomeSection {
  final List<SliderPost> posts;

  SliderSection({this.posts = const []});

  factory SliderSection.fromJson(Map<String, dynamic> data) {
    final posts = <SliderPost>[];
    for (final postData in (data['posts'] as List? ?? [])) {
      posts.add(_parseSliderPost(postData));
    }
    return SliderSection(posts: posts);
  }
}

// --- SingleSection ---

class SingleSection extends HomeSection {
  final SinglePost? post;

  SingleSection({this.post});

  factory SingleSection.fromJson(Map<String, dynamic> data) {
    final postData = data['post'] as Map<String, dynamic>;
    final mainPost = _parsePost(postData);

    final countries = (postData['countries'] as List?)
            ?.map(
                (e) => Country.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    List<Season>? seasons;
    MovieDownloadBox? movieDownloadBox;

    if (postData.containsKey('series_dlbox') &&
        postData['series_dlbox'] != null) {
      seasons = (postData['series_dlbox'] as List)
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (postData.containsKey('movies_dlbox') &&
        postData['movies_dlbox'] != null) {
      movieDownloadBox = MovieDownloadBox.fromJson(postData['movies_dlbox']);
    }

    return SingleSection(
      post: SinglePost(
        mainData: mainPost,
        runtime: postData['runtime_movie'] ?? '',
        summary: postData['fa_plot_movie'] ?? '',
        title: postData['title_movie'] ?? '',
        type: postData['type'] ?? '',
        postType: postData['post_type'] ?? '',
        countries: countries,
        movieDownloadBox: movieDownloadBox,
        seasons: seasons,
      ),
    );
  }
}

// --- GenresSection ---

class GenresSection extends HomeSection {
  final String name;
  List<Genre> genres;

  GenresSection({this.name = '', this.genres = const []});

  factory GenresSection.fromJson(Map<String, dynamic> data,
      {List<Genre> cachedGenres = const []}) {
    return GenresSection(
      name: data['name'] ?? '',
      genres: cachedGenres,
    );
  }
}

// --- NoticesSection ---

class NoticeData {
  final String content;
  final String? specialText;

  const NoticeData({required this.content, this.specialText});

  factory NoticeData.fromJson(Map<String, dynamic> json) => NoticeData(
    content: json['content'] ?? '',
    specialText: json['special_text'] as String?,
  );
}

class NoticesSection extends HomeSection {
  final List<NoticeData> notices;

  NoticesSection({this.notices = const []});

  factory NoticesSection.fromJson(Map<String, dynamic> data) {
    final notices = (data['app_notices'] as List?)
            ?.map((e) => NoticeData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return NoticesSection(notices: notices);
  }
}