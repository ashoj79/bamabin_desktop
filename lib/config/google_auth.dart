/// Google OAuth credentials for desktop sign-in.
///
/// Uses the same Web client ID as iOS/Android `serverClientId`.
/// Client secret is required by desktop OAuth and is treated as public
/// for installed apps — see google_sign_in_all_platforms docs.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const clientId =
      '853087624154-ollmdcruttejpikutj2uo3p0jdb3kqa6.apps.googleusercontent.com';

  /// Prefer `--dart-define=GOOGLE_CLIENT_SECRET=...`, otherwise set [_fallbackSecret].
  static const clientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: _fallbackSecret,
  );

  static const _fallbackSecret = '';
}
