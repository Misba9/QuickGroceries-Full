import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';

void main() {
  test('copyWith(clearUser) drops the session without wiping home snapshot', () {
    const snap = HomeBootstrapSnapshot(loadedFromDisk: true);
    const signedIn = AppBootstrapState(
      status: AppBootstrapStatus.ready,
      phase: AppBootstrapPhase.ready,
      needsOnboarding: false,
      homeSnapshot: snap,
      progress: 1,
    );

    final signedOut = signedIn.copyWith(
      clearUser: true,
      needsOnboarding: false,
    );

    expect(signedOut.user, isNull);
    expect(signedOut.phase, AppBootstrapPhase.ready);
    expect(signedOut.homeSnapshot.loadedFromDisk, isTrue);
    expect(signedOut.isComplete, isTrue);
  });

  test('signed-out home stays ready, not splash or loadingHome', () {
    const snap = HomeBootstrapSnapshot(loadedFromDisk: true);
    const signedIn = AppBootstrapState(
      status: AppBootstrapStatus.ready,
      phase: AppBootstrapPhase.ready,
      needsOnboarding: false,
      homeSnapshot: snap,
      progress: 1,
    );

    final keepHome = signedIn.phase == AppBootstrapPhase.ready ||
        signedIn.homeSnapshot.hasContent;
    final afterLogout = AppBootstrapState(
      status: keepHome ? AppBootstrapStatus.ready : AppBootstrapStatus.loading,
      phase: keepHome ? AppBootstrapPhase.ready : AppBootstrapPhase.splash,
      user: null,
      needsOnboarding: false,
      homeSnapshot: signedIn.homeSnapshot,
      progress: keepHome ? 1 : 0,
    );

    expect(afterLogout.phase, isNot(AppBootstrapPhase.splash));
    expect(afterLogout.phase, isNot(AppBootstrapPhase.loadingHome));
    expect(afterLogout.phase, AppBootstrapPhase.ready);
    expect(afterLogout.isComplete, isTrue);
  });

  test('idle initial state is splash-like loading, not ready home', () {
    expect(AppBootstrapState.initial.phase, AppBootstrapPhase.idle);
    expect(AppBootstrapState.initial.isComplete, isFalse);
  });
}
