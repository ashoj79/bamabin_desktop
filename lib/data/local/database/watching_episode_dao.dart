import 'package:bamabin_desktop/data/local/database/model/watching_episode.dart';
import 'package:floor/floor.dart';

@dao
abstract class WatchingEpisodeDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(WatchingEpisode watchingEpisode);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> update(WatchingEpisode watchingEpisode);

  @delete
  Future<void> deleteEpisode(WatchingEpisode watchingEpisode);

  @Query('SELECT * FROM WatchingEpisode WHERE id = :id')
  Future<List<WatchingEpisode>> getAllSerialEpisodes(int id);

  @Query(
    'SELECT * FROM WatchingEpisode WHERE id = :id AND season = :season AND episode = :episode ORDER BY pk DESC LIMIT 1',
  )
  Future<WatchingEpisode?> getEpisode(int id, int season, int episode);

  @Query('DELETE FROM WatchingEpisode')
  Future<void> deleteAll();
}
