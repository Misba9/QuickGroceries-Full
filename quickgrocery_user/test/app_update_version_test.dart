import 'package:flutter_test/flutter_test.dart';

import 'package:quickgrocery/core/update/app_update_config.dart';
import 'package:quickgrocery/core/update/version_checker.dart';
import 'package:quickgrocery/core/update/version_compare.dart';

void main() {
  group('compareVersions', () {
    test('orders versions correctly', () {
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('1.2.0', '1.2'), equals(0));
      expect(compareVersions('1.0.7+8', '1.0.7'), equals(0));
    });

    test('handles malformed input', () {
      expect(compareVersions('', '1.0.0'), lessThan(0));
      expect(isVersionLower('1.0.0', '1.2.0'), isTrue);
      expect(isVersionHigher('1.4.0', '1.2.0'), isTrue);
    });
  });

  group('VersionChecker', () {
    final checker = VersionChecker();

    test('force when below minimum', () async {
      const config = AppUpdateConfig(
        minimumSupportedVersion: '1.2.0',
        latestVersion: '1.4.0',
        forceUpdate: false,
        updateTitle: 'Update',
        updateMessage: 'Please update',
      );
      final d = await checker.evaluate(config, fakeInstalled: '1.0.0');
      expect(d.forceUpdate, isTrue);
      expect(d.updateAvailable, isTrue);
    });

    test('optional when newer latest and above minimum', () async {
      const config = AppUpdateConfig(
        minimumSupportedVersion: '1.0.0',
        latestVersion: '1.1.0',
        forceUpdate: false,
        updateTitle: 'Update',
        updateMessage: 'Please update',
      );
      final d = await checker.evaluate(config, fakeInstalled: '1.0.0');
      expect(d.forceUpdate, isFalse);
      expect(d.updateAvailable, isTrue);
    });

    test('force_update flag alone forces', () async {
      const config = AppUpdateConfig(
        minimumSupportedVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceUpdate: true,
        updateTitle: 'Update',
        updateMessage: 'Please update',
      );
      final d = await checker.evaluate(config, fakeInstalled: '1.0.0');
      expect(d.forceUpdate, isTrue);
      expect(d.shouldPrompt, isTrue);
    });

    test('no prompt when up to date', () async {
      const config = AppUpdateConfig(
        minimumSupportedVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceUpdate: false,
        updateTitle: 'Update',
        updateMessage: 'Please update',
      );
      final d = await checker.evaluate(config, fakeInstalled: '1.0.0');
      expect(d.shouldPrompt, isFalse);
    });
  });
}
