/// Flag set during account deletion so that MainNavigationScreen
/// redirects to welcome (not onboarding) when user doc is removed and
/// UserBloc emits null before signOut completes.
class AccountDeletionScope {
  static bool inProgress = false;
}
