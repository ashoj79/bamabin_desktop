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
import 'package:bamabin_desktop/repository/ticket_repository.dart';
import 'package:bamabin_desktop/repository/url_repository.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:bamabin_desktop/screen/auth/bloc/auth_bloc.dart';
import 'package:bamabin_desktop/screen/profile/bloc/profile_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bamabin_desktop/config/dio_helper.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
  locator.registerSingleton<SharedPreferenceHelper>(
    SharedPreferenceHelper(locator()),
  );

  // Database
  var database = await $FloorBamabinDB.databaseBuilder('bamabin.db').build();
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

  // Blocs
  locator.registerSingleton<SplashBloc>(
    SplashBloc(locator(), locator(), locator()),
  );
  locator.registerFactory<SearchBloc>(() => SearchBloc(locator()));
  locator.registerFactory<PostDetailsBloc>(
    () => PostDetailsBloc(locator()),
  );
  locator.registerFactory<AuthBloc>(() => AuthBloc(locator()));
  locator.registerFactory<ProfileBloc>(
    () => ProfileBloc(locator(), locator()),
  );
}
