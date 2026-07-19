import 'package:bamabin_desktop/data/remote/api_service/base_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';
import 'package:bamabin_desktop/data/remote/model/comment/comment.dart';
import 'package:bamabin_desktop/data/remote/model/videos/user_list.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/data/remote/model/videos/like_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:dio/dio.dart';

class VideoApiService extends BaseApiService {
  VideoApiService(super.dioHelper);

  Future<ApiResponse<List<HomeSection>>> getHomeSections() async {
    return await get(
      '/home/sections',
      (json) => HomeSection.createFromJson(json as List<dynamic>),
    );
  }

  Future<ApiResponse<List<Post>>> getPosts(
    String type,
    int genreId,
    int imdb,
    String order,
    String broadcastStatus,
    String dlboxType,
    String miniSerial,
    String free,
    String dubbed,
    int page,
  ) async {
    return await get(
      '/archive/$type',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {
        'genre': genreId,
        'imdb': imdb,
        'order_by': order,
        'broadcast_status': broadcastStatus,
        'dlbox_type': dlboxType,
        'mini_serial': miniSerial,
        'free': free,
        'is_dubbed': dubbed,
        'page': page,
      },
    );
  }

  Future<ApiResponse<PostDetails>> getPostDetails(int id) async {
    return await get(
      '/post/$id',
      (json) => PostDetails.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<LikeInfo>> likePost(int id, String type) async {
    return await get(
      '/like_dislike/post/$id/$type',
      (json) => LikeInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Post>>> getWatchList(int page) async {
    return await get(
      '/watchlist/list',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> updateWatchList(int id, String action) async {
    return await post('/watchlist/$id/$action', (json) => null);
  }

  Future<ApiResponse<List<Post>>> getPostWithTaxonomy(
    String taxonomy,
    int id,
    int genreId,
    String type,
    String orderBy,
    int imdb,
    int page,
  ) async {
    return await get(
      '/archive/$taxonomy/$id',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {
        'genre': genreId,
        'type': type,
        'order_by': orderBy,
        'imdb': imdb,
        'page': page,
      },
    );
  }

  Future<ApiResponse<List<Post>>> search(
    String s, {
    String type = '',
    int genreId = 0,
    int imdb = 0,
    String orderBy = '',
    int country = 0,
    int language = 0,
    String ageRate = '',
    int network = 0,
    String actor = '',
    String director = '',
    bool isDubbed = false,
    int yearFrom = 0,
    int yearTo = 0,
    int page = 0,
    CancelToken? cancelToken,
  }) async {
    return await get(
      '/advanced_search',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {
        's': s,
        'type': type,
        'genre_id': genreId,
        'imdb': imdb,
        'orderby': orderBy,
        'country': country,
        'language': language,
        'age_rate': ageRate,
        'network': network,
        'actor': actor,
        'director': director,
        'is_dubbed': isDubbed ? 'on' : '',
        'year_from': yearFrom,
        'year_to': yearTo,
        'page': page,
      },
      cancelToken: cancelToken,
    );
  }

  Future<ApiResponse<List<Post>>> getRecentlyViewed(int page) async {
    return await get(
      '/recently_viewed',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> deleteRecentlyViewed(int id) async {
    return await delete('/recently_viewed/$id/delete', (json) => null);
  }

  Future<ApiResponse<LikeInfo>> likeComment(int id, String type) async {
    return await get(
      '/like_dislike/comment/$id/$type',
      (json) => LikeInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> addComment(
    int id,
    String content,
    bool hasSpoil,
    int parentId,
  ) async {
    return await post(
      '/comment/$id/add',
      (json) => null,
      data: {
        'comment': content,
        'spoil_comment': hasSpoil ? 1 : 0,
        'comment_id': parentId,
      },
    );
  }

  Future<ApiResponse<List<Comment>>> getComments(int postId, int page) async {
    return await get(
      '/post/$postId/comments',
      (json) => List<Comment>.from(json.map((x) => Comment.fromJson(x))),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> saveWatchStatus(
    int postId,
    String watchStatus,
    int seasonId,
    int episodeId,
  ) async {
    return await post(
      '/post/$postId/save-watch-status',
      (json) => null,
      data: {
        'watch_status': watchStatus,
        'season_id': seasonId,
        'episode_id': episodeId,
      },
    );
  }

  Future<ApiResponse<dynamic>> savePlayStatus(
    int postId,
    int seasonId,
    int episodeId,
    int time,
    int duration,
  ) async {
    return await post(
      '/save-play-status',
      (json) => null,
      data: {
        'post_id': postId,
        'season_id': seasonId,
        'episode_id': episodeId,
        'current_time': time,
        'duration': duration,
      },
    );
  }

  Future<ApiResponse<List<UserList>>> getPostLists(int postId, int page) async {
    return await get(
      '/post/$postId/lists',
      (json) => List<UserList>.from(json.map((x) => UserList.fromJson(x))),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<List<Post>>> getListPosts(int listId, int page) async {
    return await get(
      '/lists/$listId/posts',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<List<Post>>> getTop250Movies() async {
    return await get(
      '/top-250-movies',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
    );
  }

  Future<ApiResponse<List<Post>>> getTop250Series() async {
    return await get(
      '/top-250-series',
      (json) => List<Post>.from(json.map((x) => Post.fromJson(x))),
    );
  }
}
