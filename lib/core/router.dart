import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/screen/home/home_screen.dart';
import 'package:bamabin_desktop/screen/main/main_placeholder_page.dart';
import 'package:bamabin_desktop/screen/main/main_screen.dart';
import 'package:bamabin_desktop/screen/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) {
    if (state.uri.scheme == 'bamabin') {
      return Routes.splash;
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
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'جستجو'),
        ),
        GoRoute(
          path: Routes.genresList,
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'دسته‌بندی'),
        ),
        GoRoute(
          path: Routes.subscription,
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'خرید اشتراک'),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'حساب کاربری'),
        ),
        GoRoute(
          path: Routes.notifications,
          builder: (context, state) =>
              const MainPlaceholderPage(title: 'اعلان‌ها'),
        ),
      ],
    ),
    GoRoute(
      path: Routes.postDetails,
      builder: (context, state) =>
          const MainPlaceholderPage(title: 'جزئیات'),
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
