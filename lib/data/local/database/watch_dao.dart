import 'package:bamabin_desktop/data/local/database/model/watch_data.dart';
import 'package:floor/floor.dart';

@dao
abstract class WatchDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> saveOrUpdate(WatchData data);

  @Query('DELETE FROM WatchData')
  Future<void> deleteAll();

  @Query('DELETE FROM WatchData WHERE id=:id')
  Future<void> deleteWithId(int id);

  @Query(
    'DELETE FROM WatchData WHERE id=:id AND season=:season AND episode=:episode AND pk!=:keepPk',
  )
  Future<void> deleteDuplicatesExcept(
    int id,
    int season,
    int episode,
    int keepPk,
  );

  @Query(
    'SELECT * FROM WatchData WHERE id=:id AND season=:season AND episode=:episode ORDER BY updatedAt DESC, pk DESC LIMIT 1',
  )
  Future<WatchData?> getData(int id, int season, int episode);

  @Query('SELECT id FROM WatchData')
  Future<List<int>> getAllIds();

  @Query('SELECT COUNT(*) FROM WatchData WHERE id!=:id')
  Future<int?> getOtherCount(int id);

  @Query('SELECT id FROM WatchData ORDER BY updatedAt LIMIT 1')
  Future<int?> getOldestId();

  @Query('SELECT * FROM WatchData WHERE isSavedRemotely = 0')
  Future<List<WatchData>> getUnsavedRemotelyData();

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> update(WatchData data);
}
