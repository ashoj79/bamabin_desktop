import 'package:bamabin_desktop/data/local/database/model/watched_episode.dart';
import 'package:floor/floor.dart';

@dao
abstract class WatchedEpisodeDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(WatchedEpisode watchedEpisode);

  @Query('SELECT * FROM WatchedEpisode WHERE id=:id')
  Future<List<WatchedEpisode>> getWatchedEpisodes(int id);

  @Query(
    'DELETE FROM WatchedEpisode WHERE id=:id AND season=:season AND episode=:episode',
  )
  Future<void> delete(int id, int season, int episode);

  @Query('DELETE FROM WatchedEpisode WHERE id=:id')
  Future<void> deleteWithId(int id);

  @Query('DELETE FROM WatchedEpisode')
  Future<void> deleteAll();

  @Query('SELECT * FROM WatchedEpisode ORDER BY time LIMIT 1')
  Future<WatchedEpisode?> getOldest();

  @Query(
    'SELECT COUNT(*) FROM WatchedEpisode WHERE id=:id OR season!=:season OR episode!=:episode',
  )
  Future<int?> getOtherCount(int id, int season, int episode);
}
