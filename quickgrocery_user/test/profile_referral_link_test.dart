import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/view/profile/services/profile_service.dart';

void main() {
  test('createReferralLink uses HTTPS hosting URL without Dynamic Links', () async {
    final service = ProfileService();
    final link = await service.createReferralLink('ABC123');
    expect(link, startsWith('https://www.quickgroceries.in/referral'));
    expect(link, contains('code=ABC123'));
    expect(link, isNot(contains('page.link')));
  });
}
