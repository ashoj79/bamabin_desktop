import 'package:bamabin_desktop/data/local/database/model/watch_data.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_episode.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_movie.dart';
import 'package:bamabin_desktop/data/local/database/model/watching_episode.dart';
import 'package:bamabin_desktop/data/remote/api_service/video_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/comment/comment.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/data/remote/model/videos/like_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/data/remote/model/videos/user_list.dart';
import 'package:bamabin_desktop/data/local/database/watch_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_episode_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_movie_dao.dart';
import 'package:bamabin_desktop/data/local/database/watching_episode_dao.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:dio/dio.dart';

class VideoRepository {
  final VideoApiService _videoApiService;
  final WatchDao _watchDao;
  final WatchedEpisodeDao _watchedEpisodeDao;
  final WatchedMovieDao _watchedMovieDao;
  final WatchingEpisodeDao _watchingEpisodeDao;

  VideoRepository(
    this._videoApiService,
    this._watchDao,
    this._watchedEpisodeDao,
    this._watchedMovieDao,
    this._watchingEpisodeDao,
  );

  Future<WatchData?> getWatchData(int id, int season, int episode) async {
    return await _watchDao.getData(id, season, episode);
  }

  Future<void> deleteWatchDataWithId(int id) async {
    await _watchDao.deleteWithId(id);
  }

  Future<void> saveWatchData(WatchData data) async {
    await _watchDao.saveOrUpdate(
      data
        ..updatedAt = DateTime.now().millisecondsSinceEpoch
        ..isSavedRemotely = false,
    );
  }

  Future<void> saveWatchStatusRemotely(
    int id,
    int season,
    int episode,
    int time,
    int duration,
  ) async {
    await _videoApiService.savePlayStatus(
      id,
      season + 1,
      episode + 1,
      time,
      duration,
    );
  }

  Future<void> saveUnsavedRemotelyData() async {
    final data = await _watchDao.getUnsavedRemotelyData();
    for (var item in data) {
      await _videoApiService.savePlayStatus(
        item.id,
        item.season,
        item.episode,
        (item.time / 1000).toInt(),
        (item.duration / 1000).toInt(),
      );
      await _watchDao.update(item..isSavedRemotely = true);
    }
  }

  Future<void> saveWatchedMovie(WatchedMovie watchedMovie) async {
    await _watchedMovieDao.insert(watchedMovie);
  }

  Future<List<WatchedEpisode>> getWatchedEpisodes(int id) async {
    return await _watchedEpisodeDao.getWatchedEpisodes(id);
  }

  Future<void> saveWatchedEpisode(WatchedEpisode watchedEpisode) async {
    await _watchedEpisodeDao.insert(
      watchedEpisode..time = DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> deleteAllMovieWatchData(int id) async {
    await _watchedMovieDao.deleteWithId(id);
    await _watchDao.deleteWithId(id);
    await _watchedEpisodeDao.deleteWithId(id);
    await _videoApiService.deleteRecentlyViewed(id);
  }

  Future<void> deleteAllWatchData() async {
    await _watchDao.deleteAll();
    await _watchedEpisodeDao.deleteAll();
    await _watchedMovieDao.deleteAll();
    await _videoApiService.deleteRecentlyViewed(0);
  }

  Future<void> saveWatchingEpisode(WatchingEpisode watchingEpisode) async {
    final existing = await _watchingEpisodeDao.getEpisode(
      watchingEpisode.id,
      watchingEpisode.season,
      watchingEpisode.episode,
    );
    if (existing != null) {
      await _watchingEpisodeDao.update(
        WatchingEpisode(
          pk: existing.pk,
          id: watchingEpisode.id,
          season: watchingEpisode.season,
          episode: watchingEpisode.episode,
          time: watchingEpisode.time,
          duration: watchingEpisode.duration,
          type: watchingEpisode.type,
        ),
      );
    } else {
      await _watchingEpisodeDao.insert(watchingEpisode);
    }
  }

  Future<void> updateWatchingEpisode(WatchingEpisode watchingEpisode) async {
    await _watchingEpisodeDao.update(watchingEpisode);
  }

  Future<WatchingEpisode?> getWatchingEpisode(
    int id,
    int season,
    int episode,
  ) async {
    return await _watchingEpisodeDao.getEpisode(id, season, episode);
  }

  Future<List<WatchingEpisode>> getAllWatchingEpisodes(int id) async {
    return await _watchingEpisodeDao.getAllSerialEpisodes(id);
  }

  Future<void> deleteWatchingEpisode(WatchingEpisode watchingEpisode) async {
    await _watchingEpisodeDao.deleteEpisode(watchingEpisode);
  }

  Future<DataState<List<HomeSection>>> getHomeSections() async {
    final response = await _videoApiService.getHomeSections();
    if (response.status) {
      TempDb.homeSections.value = response.data!;
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getPosts(
    String type,
    int genreId,
    int imdb,
    String order, {
    String broadcastStatus = '',
    String dlboxType = '',
    String miniSerial = '',
    String free = '',
    String dubbed = '',
    int page = 1,
  }) async {
    final response = await _videoApiService.getPosts(
      type,
      genreId,
      imdb,
      order,
      broadcastStatus,
      dlboxType,
      miniSerial,
      free,
      dubbed,
      page,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<PostDetails>> getPostDetails(int id) async {
    final response = await _videoApiService.getPostDetails(id);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<LikeInfo>> likePost(int id, String type) async {
    final response = await _videoApiService.likePost(id, type);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getWatchList(int page) async {
    final response = await _videoApiService.getWatchList(page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> updateWatchList(int id, String action) async {
    final response = await _videoApiService.updateWatchList(id, action);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getPostWithTaxonomy(
    String taxonomy,
    int id,
    int genreId,
    String type,
    String orderBy,
    int imdb,
    int page,
  ) async {
    final response = await _videoApiService.getPostWithTaxonomy(
      taxonomy,
      id,
      genreId,
      type,
      orderBy,
      imdb,
      page,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> search(
    String s, {
    required int page,
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
    CancelToken? cancelToken,
  }) async {
    final response = await _videoApiService.search(
      s,
      type: type,
      genreId: genreId,
      imdb: imdb,
      orderBy: orderBy,
      country: country,
      language: language,
      ageRate: ageRate,
      network: network,
      actor: actor,
      director: director,
      isDubbed: isDubbed,
      yearFrom: yearFrom,
      yearTo: yearTo,
      page: page,
      cancelToken: cancelToken,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getRecentlyViewed(int page) async {
    final response = await _videoApiService.getRecentlyViewed(page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> deleteRecentlyViewed(int id) async {
    final response = await _videoApiService.deleteRecentlyViewed(id);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<LikeInfo>> likeComment(int id, String type) async {
    final response = await _videoApiService.likeComment(id, type);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> addComment(
    int id,
    String content,
    bool hasSpoil,
    int parentId,
  ) async {
    final response = await _videoApiService.addComment(
      id,
      content,
      hasSpoil,
      parentId,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Comment>>> getComments(int postId, int page) async {
    final response = await _videoApiService.getComments(postId, page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> saveWatchStatus(
    int postId,
    String watchStatus,
    int seasonId,
    int episodeId,
  ) async {
    final response = await _videoApiService.saveWatchStatus(
      postId,
      watchStatus,
      seasonId,
      episodeId,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<UserList>>> getPostLists(int postId, int page) async {
    final response = await _videoApiService.getPostLists(postId, page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getListPosts(int listId, int page) async {
    final response = await _videoApiService.getListPosts(listId, page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getTop250Movies() async {
    final response = await _videoApiService.getTop250Movies();
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Post>>> getTop250Series() async {
    final response = await _videoApiService.getTop250Series();
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }
}
