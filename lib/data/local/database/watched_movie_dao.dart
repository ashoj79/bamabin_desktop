import 'package:bamabin_desktop/data/local/database/model/watched_movie.dart';
import 'package:floor/floor.dart';

@dao
abstract class WatchedMovieDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(WatchedMovie watchedMovie);

  @Query('DELETE FROM WatchedMovie WHERE id=:id')
  Future<void> deleteWithId(int id);

  @Query('DELETE FROM WatchedMovie')
  Future<void> deleteAll();

  @Query('SELECT * FROM WatchedMovie ORDER BY time DESC')
  Future<List<WatchedMovie>> getAll();

  @Query('SELECT id FROM WatchedMovie ORDER BY time DESC')
  Future<List<int>> getAllId();

  @Query('SELECT COUNT(*) FROM WatchedMovie')
  Future<int?> getAllCount();

  @Query('SELECT id FROM WatchedMovie ORDER BY time LIMIT 1')
  Future<int?> getOldestId();
}
