import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/screen/auth/auth_screen.dart';
import 'package:bamabin_desktop/screen/auth/bloc/auth_bloc.dart';
import 'package:bamabin_desktop/screen/categories/categories_screen.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_bloc.dart';
import 'package:bamabin_desktop/screen/download_manager/download_manager_screen.dart';
import 'package:bamabin_desktop/screen/home/home_screen.dart';
import 'package:bamabin_desktop/screen/main/main_placeholder_page.dart';
import 'package:bamabin_desktop/screen/main/main_screen.dart';
import 'package:bamabin_desktop/screen/player/bloc/player_bloc.dart';
import 'package:bamabin_desktop/screen/player/player_screen.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:bamabin_desktop/screen/post_details/post_details_screen.dart';
import 'package:bamabin_desktop/screen/profile/bloc/profile_bloc.dart';
import 'package:bamabin_desktop/screen/profile/profile_screen.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:bamabin_desktop/screen/search/search_screen.dart';
import 'package:bamabin_desktop/screen/splash/splash_screen.dart';
import 'package:bamabin_desktop/screen/subscription/bloc/subscription_bloc.dart';
import 'package:bamabin_desktop/screen/subscription/subscription_screen.dart';
import 'package:bamabin_desktop/screen/top250/bloc/top250_bloc.dart';
import 'package:bamabin_desktop/screen/top250/top250_screen.dart';
import 'package:bamabin_desktop/screen/watch_status/bloc/watch_status_bloc.dart';
import 'package:bamabin_desktop/screen/watch_status/watch_status_screen.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String _lastAppLocation = Routes.splash;

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) {
    // Deep links are handled by DeepLinkHandler; keep the current screen.
    if (state.uri.scheme.toLowerCase() == 'bamabin') {
      return _lastAppLocation;
    }
    final matched = state.matchedLocation;
    if (matched.isNotEmpty) {
      _lastAppLocation = matched;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: Routes.main,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.search,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<SearchBloc>(),
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: Routes.genresList,
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: Routes.subscription,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<SubscriptionBloc>(),
            child: const SubscriptionScreen(),
          ),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<ProfileBloc>(),
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: Routes.watchStatusPosts,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<WatchStatusBloc>(),
            child: const WatchStatusScreen(),
          ),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'اعلان‌ها'),
        ),
        GoRoute(
          path: Routes.downloadManager,
          builder: (context, state) => BlocProvider.value(
            value: locator<DownloadManagerBloc>(),
            child: const DownloadManagerScreen(),
          ),
        ),
        GoRoute(
          path: Routes.top250Movies,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<Top250Bloc>(param1: Top250Type.movies),
            child: const Top250Screen(type: Top250Type.movies),
          ),
        ),
        GoRoute(
          path: Routes.top250Series,
          builder: (context, state) => BlocProvider(
            create: (_) => locator<Top250Bloc>(param1: Top250Type.series),
            child: const Top250Screen(type: Top250Type.series),
          ),
        ),
      ],
    ),
    GoRoute(
      path: Routes.auth,
      builder: (context, state) => BlocProvider(
        create: (_) => locator<AuthBloc>(),
        child: const AuthScreen(),
      ),
    ),
    GoRoute(
      path: Routes.postDetails,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Post) {
          return const MainPlaceholderPage(title: 'جزئیات');
        }
        return BlocProvider(
          create: (_) =>
              locator<PostDetailsBloc>()..add(LoadPostDetailsEvent(extra)),
          child: const PostDetailsScreen(),
        );
      },
    ),
    GoRoute(
      path: Routes.player,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! PlayerArgs) {
          return const MainPlaceholderPage(title: 'پخش‌کننده');
        }
        return BlocProvider(
          create: (_) => locator<PlayerBloc>(),
          child: PlayerScreen(args: extra),
        );
      },
    ),
    GoRoute(
      path: Routes.taxonomyPosts,
      builder: (context, state) {
        final title = (state.extra as Map?)?['title'] as String? ?? 'آرشیو';
        return MainPlaceholderPage(title: title);
      },
    ),
    GoRoute(
      path: Routes.postTypeArchive,
      builder: (context, state) {
        final title = (state.extra as Map?)?['title'] as String? ?? 'آرشیو';
        return MainPlaceholderPage(title: title);
      },
    ),
  ],
);
