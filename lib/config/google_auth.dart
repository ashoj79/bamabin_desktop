/// Google OAuth credentials for desktop sign-in.
///
/// Uses the same Web client ID as iOS/Android `serverClientId`.
/// Client secret is required by desktop OAuth and is treated as public
/// for installed apps — see google_sign_in_all_platforms docs.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const clientId =
      '94498494608-egb34h765g10vmqqbhdbr369pl4knp5l.apps.googleusercontent.com';

  /// Prefer `--dart-define=GOOGLE_CLIENT_SECRET=...`, otherwise set [_fallbackSecret].
  static const clientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: _fallbackSecret,
  );

  static const _fallbackSecret = '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';
}
