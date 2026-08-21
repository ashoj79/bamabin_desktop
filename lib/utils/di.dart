import 'dart:io';

import 'package:bamabin_desktop/config/dio_helper.dart';
import 'package:bamabin_desktop/data/local/database/bamabin_db.dart';
import 'package:bamabin_desktop/data/local/database/watch_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_episode_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_movie_dao.dart';
import 'package:bamabin_desktop/data/local/database/watching_episode_dao.dart';
import 'package:bamabin_desktop/data/local/shared_preference_helper.dart';
import 'package:bamabin_desktop/data/remote/api_service/app_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/root_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/ticket_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/url_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/user_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/video_api_service.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/download_repository.dart';
import 'package:bamabin_desktop/repository/ticket_repository.dart';
import 'package:bamabin_desktop/repository/url_repository.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/screen/auth/bloc/auth_bloc.dart';
import 'package:bamabin_desktop/screen/categories/bloc/taxonomy_posts_bloc.dart';
import 'package:bamabin_desktop/screen/categories/taxonomy_posts_args.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_bloc.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:bamabin_desktop/screen/notifications/bloc/notifications_bloc.dart';
import 'package:bamabin_desktop/screen/player/bloc/player_bloc.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:bamabin_desktop/screen/profile/bloc/profile_bloc.dart';
import 'package:bamabin_desktop/screen/recently_viewed/bloc/recently_viewed_bloc.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/screen/subscription/bloc/subscription_bloc.dart';
import 'package:bamabin_desktop/screen/tickets/bloc/ticket_details_bloc.dart';
import 'package:bamabin_desktop/screen/tickets/bloc/tickets_bloc.dart';
import 'package:bamabin_desktop/screen/top250/bloc/top250_bloc.dart';
import 'package:bamabin_desktop/screen/watch_status/bloc/watch_status_bloc.dart';
import 'package:bamabin_desktop/screen/watchlist/bloc/watchlist_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final locator = GetIt.instance;

Future<void> _initSqlite() async {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<String> _bamabinDbPath() async {
  final support = await getApplicationSupportDirectory();
  await support.create(recursive: true);
  return p.join(support.path, 'bamabin.db');
}

Future<void> setupLocator() async {
  await _initSqlite();

  locator.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
  // Avoid Keychain on macOS (unsigned builds keep asking for the login password).
  final secureStorage =
      (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS)
      ? const FlutterSecureStorage()
      : null;
  final sharedPreferenceHelper = SharedPreferenceHelper(
    locator(),
    secureStorage,
  );
  await sharedPreferenceHelper.init();
  locator.registerSingleton<SharedPreferenceHelper>(sharedPreferenceHelper);

  // Database must live under Application Support (app bundle / DMG is read-only).
  final database = await $FloorBamabinDB
      .databaseBuilder(await _bamabinDbPath())
      .build();
  locator.registerSingleton<WatchDao>(database.watchDao);
  locator.registerSingleton<WatchedEpisodeDao>(database.watchedEpisodeDao);
  locator.registerSingleton<WatchedMovieDao>(database.watchedMovieDao);
  locator.registerSingleton<WatchingEpisodeDao>(database.watchingEpisodeDao);

  locator.registerSingleton<DioHelper>(DioHelper());

  // Api Services
  locator.registerSingleton<AppApiService>(AppApiService(locator()));
  locator.registerSingleton<VideoApiService>(VideoApiService(locator()));
  locator.registerSingleton<UserApiService>(UserApiService(locator()));
  locator.registerSingleton<TicketApiService>(TicketApiService(locator()));
  locator.registerSingleton<UrlApiService>(UrlApiService(locator()));
  locator.registerSingleton<RootApiService>(RootApiService(locator()));

  // Repositories
  locator.registerSingleton<AppRepository>(
    AppRepository(locator(), locator(), locator()),
  );
  locator.registerSingleton<VideoRepository>(
    VideoRepository(locator(), locator(), locator(), locator(), locator()),
  );
  locator.registerSingleton<UserRepository>(
    UserRepository(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
    ),
  );
  locator.registerSingleton<TicketRepository>(TicketRepository(locator()));
  locator.registerSingleton<UrlRepository>(UrlRepository(locator(), locator()));
  locator.registerSingleton<DownloadRepository>(DownloadRepository());

  // Blocs
  locator.registerSingleton<SplashBloc>(
    SplashBloc(locator(), locator(), locator()),
  );
  locator.registerSingleton<DownloadManagerBloc>(
    DownloadManagerBloc(locator())..add(const DownloadManagerStarted()),
  );
  locator.registerFactory<SearchBloc>(() => SearchBloc(locator()));
  locator.registerFactory<PostDetailsBloc>(() => PostDetailsBloc(locator()));
  locator.registerFactory<AuthBloc>(() => AuthBloc(locator()));
  locator.registerFactory<ProfileBloc>(
    () => ProfileBloc(locator(), locator()),
  );
  locator.registerFactory<SubscriptionBloc>(
    () => SubscriptionBloc(locator()),
  );
  locator.registerFactory<WatchStatusBloc>(() => WatchStatusBloc(locator()));
  locator.registerFactory<WatchlistBloc>(() => WatchlistBloc(locator()));
  locator.registerFactory<RecentlyViewedBloc>(
    () => RecentlyViewedBloc(locator()),
  );
  locator.registerFactoryParam<Top250Bloc, Top250Type, void>(
    (type, _) => Top250Bloc(locator(), type),
  );
  locator.registerFactory<PlayerBloc>(() => PlayerBloc(locator(), locator()));
  locator.registerFactoryParam<TaxonomyPostsBloc, TaxonomyPostsArgs, void>(
    (args, _) => TaxonomyPostsBloc(locator(), args),
  );
  locator.registerFactory<TicketsBloc>(() => TicketsBloc(locator()));
  locator.registerFactory<TicketDetailsBloc>(
    () => TicketDetailsBloc(locator()),
  );
  locator.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(locator()),
  );
}
