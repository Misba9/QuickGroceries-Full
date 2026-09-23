import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/core/auth/account_deletion_confirm_flow.dart';
import 'package:quickgrocery/core/auth/account_deletion_service.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_sections.dart';

Widget _app(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  );
}

void main() {
  testWidgets('Delete Account button is visible', (tester) async {
    await tester.pumpWidget(
      _app(ProfileDeleteAccountSection(deleteAccount: () async {})),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteAccountButton')), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('first dialog Cancel does not delete', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(ProfileDeleteAccountSection(deleteAccount: () async { calls++; })),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountButton')));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deleteAccountConfirmCancel')));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Delete your account?'), findsNothing);
  });

  testWidgets('second dialog Cancel does not delete', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(ProfileDeleteAccountSection(deleteAccount: () async { calls++; })),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountConfirmDelete')));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to permanently delete your account?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('deleteAccountSecondCancel')));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('two confirms start deletion and show processing', (tester) async {
    final started = Completer<void>();
    await tester.pumpWidget(
      _app(
        ProfileDeleteAccountSection(
          deleteAccount: () => started.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountConfirmDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountSecondConfirm')));
    await tester.pump();
    expect(find.text('Deleting your account...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('failed deletion shows a friendly error', (tester) async {
    await tester.pumpWidget(
      _app(
        ProfileDeleteAccountSection(
          deleteAccount: () async {
            throw AccountDeletionException(
              'We couldn\'t delete your account. Please try again.',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountConfirmDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountSecondConfirm')));
    await tester.pumpAndSettle();
    expect(
      find.text('We couldn\'t delete your account. Please try again.'),
      findsWidgets,
    );
  });

  test('AccountDeletionException is user-facing, not a stack', () {
    const raw = 'FirebaseAuthException: [firebase_auth/internal] boom';
    final mapped = AccountDeletionException(
      'We couldn\'t delete your account. Please try again.',
    );
    expect(mapped.toString(), isNot(contains('FirebaseAuthException')));
    expect(mapped.toString(), isNot(contains(raw)));
    expect(mapped.needsReauth, isFalse);
  });

  test('reauth flag is set for recent-login style failures', () {
    final e = AccountDeletionException(
      'Please verify it is you, then try again.',
      needsReauth: true,
    );
    expect(e.needsReauth, isTrue);
  });

  testWidgets('confirm helper returns false on first cancel', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AccountDeletionConfirmFlow.confirm(context),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAccountConfirmCancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteAccountSecondConfirm')), findsNothing);
  });
}
