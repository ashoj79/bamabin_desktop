import 'package:floor/floor.dart';

@entity
class WatchedMovie {
  WatchedMovie({
    required this.id,
    required this.time,
  });

  @primaryKey
  final int id;
  final int time;
}
