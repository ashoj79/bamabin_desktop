import 'dart:async';

import 'package:bamabin_desktop/data/local/database/model/watch_data.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_episode.dart';
import 'package:bamabin_desktop/data/local/database/model/watched_movie.dart';
import 'package:bamabin_desktop/data/local/database/model/watching_episode.dart';
import 'package:bamabin_desktop/data/local/database/watch_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_episode_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_movie_dao.dart';
import 'package:bamabin_desktop/data/local/database/watching_episode_dao.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'bamabin_db.g.dart';

@Database(
  version: 1,
  entities: [WatchData, WatchedEpisode, WatchedMovie, WatchingEpisode],
)
abstract class BamabinDB extends FloorDatabase {
  WatchDao get watchDao;

  WatchedEpisodeDao get watchedEpisodeDao;

  WatchedMovieDao get watchedMovieDao;

  WatchingEpisodeDao get watchingEpisodeDao;
}

Future<BamabinDB> openBamabinDatabase(String path) {
  return $FloorBamabinDB.databaseBuilder(path).build();
}
