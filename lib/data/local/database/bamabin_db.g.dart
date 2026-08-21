// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bamabin_db.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $BamabinDBBuilderContract {
  /// Adds migrations to the builder.
  $BamabinDBBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $BamabinDBBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<BamabinDB> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorBamabinDB {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $BamabinDBBuilderContract databaseBuilder(String name) =>
      _$BamabinDBBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $BamabinDBBuilderContract inMemoryDatabaseBuilder() =>
      _$BamabinDBBuilder(null);
}

class _$BamabinDBBuilder implements $BamabinDBBuilderContract {
  _$BamabinDBBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $BamabinDBBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $BamabinDBBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<BamabinDB> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$BamabinDB();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$BamabinDB extends BamabinDB {
  _$BamabinDB([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  WatchDao? _watchDaoInstance;

  WatchedEpisodeDao? _watchedEpisodeDaoInstance;

  WatchedMovieDao? _watchedMovieDaoInstance;

  WatchingEpisodeDao? _watchingEpisodeDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WatchData` (`pk` INTEGER PRIMARY KEY AUTOINCREMENT, `id` INTEGER NOT NULL, `type` TEXT NOT NULL, `quality` TEXT NOT NULL, `qualityCode` TEXT NOT NULL, `time` INTEGER NOT NULL, `duration` INTEGER NOT NULL, `season` INTEGER NOT NULL, `episode` INTEGER NOT NULL, `audioTrack` INTEGER NOT NULL, `subtitleTrack` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `isSavedRemotely` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WatchedEpisode` (`pk` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `id` INTEGER NOT NULL, `season` INTEGER NOT NULL, `episode` INTEGER NOT NULL, `type` TEXT NOT NULL, `time` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WatchedMovie` (`id` INTEGER NOT NULL, `time` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WatchingEpisode` (`pk` INTEGER PRIMARY KEY AUTOINCREMENT, `id` INTEGER NOT NULL, `season` INTEGER NOT NULL, `episode` INTEGER NOT NULL, `time` INTEGER NOT NULL, `duration` INTEGER NOT NULL, `type` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  WatchDao get watchDao {
    return _watchDaoInstance ??= _$WatchDao(database, changeListener);
  }

  @override
  WatchedEpisodeDao get watchedEpisodeDao {
    return _watchedEpisodeDaoInstance ??=
        _$WatchedEpisodeDao(database, changeListener);
  }

  @override
  WatchedMovieDao get watchedMovieDao {
    return _watchedMovieDaoInstance ??=
        _$WatchedMovieDao(database, changeListener);
  }

  @override
  WatchingEpisodeDao get watchingEpisodeDao {
    return _watchingEpisodeDaoInstance ??=
        _$WatchingEpisodeDao(database, changeListener);
  }
}

class _$WatchDao extends WatchDao {
  _$WatchDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _watchDataInsertionAdapter = InsertionAdapter(
            database,
            'WatchData',
            (WatchData item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'type': item.type,
                  'quality': item.quality,
                  'qualityCode': item.qualityCode,
                  'time': item.time,
                  'duration': item.duration,
                  'season': item.season,
                  'episode': item.episode,
                  'audioTrack': item.audioTrack,
                  'subtitleTrack': item.subtitleTrack,
                  'updatedAt': item.updatedAt,
                  'isSavedRemotely': item.isSavedRemotely ? 1 : 0
                }),
        _watchDataUpdateAdapter = UpdateAdapter(
            database,
            'WatchData',
            ['pk'],
            (WatchData item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'type': item.type,
                  'quality': item.quality,
                  'qualityCode': item.qualityCode,
                  'time': item.time,
                  'duration': item.duration,
                  'season': item.season,
                  'episode': item.episode,
                  'audioTrack': item.audioTrack,
                  'subtitleTrack': item.subtitleTrack,
                  'updatedAt': item.updatedAt,
                  'isSavedRemotely': item.isSavedRemotely ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WatchData> _watchDataInsertionAdapter;

  final UpdateAdapter<WatchData> _watchDataUpdateAdapter;

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM WatchData');
  }

  @override
  Future<void> deleteWithId(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM WatchData WHERE id=?1', arguments: [id]);
  }

  @override
  Future<void> deleteDuplicatesExcept(
    int id,
    int season,
    int episode,
    int keepPk,
  ) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM WatchData WHERE id=?1 AND season=?2 AND episode=?3 AND pk!=?4',
      arguments: [id, season, episode, keepPk],
    );
  }

  @override
  Future<WatchData?> getData(
    int id,
    int season,
    int episode,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM WatchData WHERE id=?1 AND season=?2 AND episode=?3 ORDER BY updatedAt DESC, pk DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => WatchData(
            pk: row['pk'] as int?,
            id: row['id'] as int,
            type: row['type'] as String,
            quality: row['quality'] as String,
            qualityCode: row['qualityCode'] as String,
            time: row['time'] as int,
            duration: row['duration'] as int,
            season: row['season'] as int,
            episode: row['episode'] as int,
            audioTrack: row['audioTrack'] as int,
            subtitleTrack: row['subtitleTrack'] as int,
            updatedAt: row['updatedAt'] as int),
        arguments: [id, season, episode]);
  }

  @override
  Future<List<int>> getAllIds() async {
    return _queryAdapter.queryList('SELECT id FROM WatchData',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getOtherCount(int id) async {
    return _queryAdapter.query('SELECT COUNT(*) FROM WatchData WHERE id!=?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id]);
  }

  @override
  Future<int?> getOldestId() async {
    return _queryAdapter.query(
        'SELECT id FROM WatchData ORDER BY updatedAt LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<List<WatchData>> getUnsavedRemotelyData() async {
    return _queryAdapter.queryList(
        'SELECT * FROM WatchData WHERE isSavedRemotely = 0',
        mapper: (Map<String, Object?> row) => WatchData(
            pk: row['pk'] as int?,
            id: row['id'] as int,
            type: row['type'] as String,
            quality: row['quality'] as String,
            qualityCode: row['qualityCode'] as String,
            time: row['time'] as int,
            duration: row['duration'] as int,
            season: row['season'] as int,
            episode: row['episode'] as int,
            audioTrack: row['audioTrack'] as int,
            subtitleTrack: row['subtitleTrack'] as int,
            updatedAt: row['updatedAt'] as int));
  }

  @override
  Future<void> saveOrUpdate(WatchData data) async {
    await _watchDataInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(WatchData data) async {
    await _watchDataUpdateAdapter.update(data, OnConflictStrategy.replace);
  }
}

class _$WatchedEpisodeDao extends WatchedEpisodeDao {
  _$WatchedEpisodeDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _watchedEpisodeInsertionAdapter = InsertionAdapter(
            database,
            'WatchedEpisode',
            (WatchedEpisode item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'season': item.season,
                  'episode': item.episode,
                  'type': item.type,
                  'time': item.time
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WatchedEpisode> _watchedEpisodeInsertionAdapter;

  @override
  Future<List<WatchedEpisode>> getWatchedEpisodes(int id) async {
    return _queryAdapter.queryList('SELECT * FROM WatchedEpisode WHERE id=?1',
        mapper: (Map<String, Object?> row) => WatchedEpisode(
            pk: row['pk'] as int?,
            id: row['id'] as int,
            season: row['season'] as int,
            episode: row['episode'] as int,
            type: row['type'] as String,
            time: row['time'] as int),
        arguments: [id]);
  }

  @override
  Future<void> delete(
    int id,
    int season,
    int episode,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM WatchedEpisode WHERE id=?1 AND season=?2 AND episode=?3',
        arguments: [id, season, episode]);
  }

  @override
  Future<void> deleteWithId(int id) async {
    await _queryAdapter.queryNoReturn('DELETE FROM WatchedEpisode WHERE id=?1',
        arguments: [id]);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM WatchedEpisode');
  }

  @override
  Future<WatchedEpisode?> getOldest() async {
    return _queryAdapter.query(
        'SELECT * FROM WatchedEpisode ORDER BY time LIMIT 1',
        mapper: (Map<String, Object?> row) => WatchedEpisode(
            pk: row['pk'] as int?,
            id: row['id'] as int,
            season: row['season'] as int,
            episode: row['episode'] as int,
            type: row['type'] as String,
            time: row['time'] as int));
  }

  @override
  Future<int?> getOtherCount(
    int id,
    int season,
    int episode,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM WatchedEpisode WHERE id=?1 OR season!=?2 OR episode!=?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [id, season, episode]);
  }

  @override
  Future<void> insert(WatchedEpisode watchedEpisode) async {
    await _watchedEpisodeInsertionAdapter.insert(
        watchedEpisode, OnConflictStrategy.replace);
  }
}

class _$WatchedMovieDao extends WatchedMovieDao {
  _$WatchedMovieDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _watchedMovieInsertionAdapter = InsertionAdapter(
            database,
            'WatchedMovie',
            (WatchedMovie item) =>
                <String, Object?>{'id': item.id, 'time': item.time});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WatchedMovie> _watchedMovieInsertionAdapter;

  @override
  Future<void> deleteWithId(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM WatchedMovie WHERE id=?1', arguments: [id]);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM WatchedMovie');
  }

  @override
  Future<List<WatchedMovie>> getAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM WatchedMovie ORDER BY time DESC',
        mapper: (Map<String, Object?> row) =>
            WatchedMovie(id: row['id'] as int, time: row['time'] as int));
  }

  @override
  Future<List<int>> getAllId() async {
    return _queryAdapter.queryList(
        'SELECT id FROM WatchedMovie ORDER BY time DESC',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getAllCount() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM WatchedMovie',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getOldestId() async {
    return _queryAdapter.query(
        'SELECT id FROM WatchedMovie ORDER BY time LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> insert(WatchedMovie watchedMovie) async {
    await _watchedMovieInsertionAdapter.insert(
        watchedMovie, OnConflictStrategy.replace);
  }
}

class _$WatchingEpisodeDao extends WatchingEpisodeDao {
  _$WatchingEpisodeDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _watchingEpisodeInsertionAdapter = InsertionAdapter(
            database,
            'WatchingEpisode',
            (WatchingEpisode item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'season': item.season,
                  'episode': item.episode,
                  'time': item.time,
                  'duration': item.duration,
                  'type': item.type
                }),
        _watchingEpisodeUpdateAdapter = UpdateAdapter(
            database,
            'WatchingEpisode',
            ['pk'],
            (WatchingEpisode item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'season': item.season,
                  'episode': item.episode,
                  'time': item.time,
                  'duration': item.duration,
                  'type': item.type
                }),
        _watchingEpisodeDeletionAdapter = DeletionAdapter(
            database,
            'WatchingEpisode',
            ['pk'],
            (WatchingEpisode item) => <String, Object?>{
                  'pk': item.pk,
                  'id': item.id,
                  'season': item.season,
                  'episode': item.episode,
                  'time': item.time,
                  'duration': item.duration,
                  'type': item.type
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WatchingEpisode> _watchingEpisodeInsertionAdapter;

  final UpdateAdapter<WatchingEpisode> _watchingEpisodeUpdateAdapter;

  final DeletionAdapter<WatchingEpisode> _watchingEpisodeDeletionAdapter;

  @override
  Future<List<WatchingEpisode>> getAllSerialEpisodes(int id) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WatchingEpisode WHERE id = ?1',
        mapper: (Map<String, Object?> row) => WatchingEpisode(
            pk: row['pk'] as int?,
            id: row['id'] as int,
            season: row['season'] as int,
            episode: row['episode'] as int,
            time: row['time'] as int,
            duration: row['duration'] as int,
            type: row['type'] as String),
        arguments: [id]);
  }

  @override
  Future<WatchingEpisode?> getEpisode(
    int id,
    int season,
    int episode,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM WatchingEpisode WHERE id = ?1 AND season = ?2 AND episode = ?3 ORDER BY pk DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => WatchingEpisode(pk: row['pk'] as int?, id: row['id'] as int, season: row['season'] as int, episode: row['episode'] as int, time: row['time'] as int, duration: row['duration'] as int, type: row['type'] as String),
        arguments: [id, season, episode]);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM WatchingEpisode');
  }

  @override
  Future<void> insert(WatchingEpisode watchingEpisode) async {
    await _watchingEpisodeInsertionAdapter.insert(
        watchingEpisode, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(WatchingEpisode watchingEpisode) async {
    await _watchingEpisodeUpdateAdapter.update(
        watchingEpisode, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteEpisode(WatchingEpisode watchingEpisode) async {
    await _watchingEpisodeDeletionAdapter.delete(watchingEpisode);
  }
}
