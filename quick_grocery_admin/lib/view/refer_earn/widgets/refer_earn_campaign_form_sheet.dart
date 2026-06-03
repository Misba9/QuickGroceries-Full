import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_campaign_model.dart';

class ReferEarnCampaignFormSheet {
  static Future<ReferEarnCampaignModel?> show(
    BuildContext context, {
    ReferEarnCampaignModel? existing,
  }) async {
    return showModalBottomSheet<ReferEarnCampaignModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _FormBody(existing: existing),
    );
  }
}

class _FormBody extends StatefulWidget {
  const _FormBody({this.existing});

  final ReferEarnCampaignModel? existing;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _prefix;
  late final TextEditingController _referrerReward;
  late final TextEditingController _newUserReward;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxReferrals;
  late final TextEditingController _validityDays;
  late final TextEditingController _campaignDays;
  late bool _autoGrant;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? 'Default Referral');
    _prefix = TextEditingController(text: e?.couponCodePrefix ?? 'REF');
    _referrerReward =
        TextEditingController(text: '${e?.referrerRewardAmount ?? 50}');
    _newUserReward =
        TextEditingController(text: '${e?.newUserRewardAmount ?? 50}');
    _minOrder = TextEditingController(text: '${e?.minimumOrderValue ?? 299}');
    _maxReferrals =
        TextEditingController(text: '${e?.maxReferralsPerUser ?? 10}');
    _validityDays =
        TextEditingController(text: '${e?.referralValidityDays ?? 30}');
    _campaignDays =
        TextEditingController(text: '${e?.campaignValidityDays ?? 365}');
    _autoGrant = e?.autoGrantRewards ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _prefix.dispose();
    _referrerReward.dispose();
    _newUserReward.dispose();
    _minOrder.dispose();
    _maxReferrals.dispose();
    _validityDays.dispose();
    _campaignDays.dispose();
    super.dispose();
  }

  int _int(TextEditingController c, {int fallback = 0}) =>
      int.tryParse(c.text.trim()) ?? fallback;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'New campaign' : 'Edit campaign',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Campaign name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prefix,
                decoration: const InputDecoration(
                  labelText: 'Coupon code prefix',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _referrerReward,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Referrer reward (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _newUserReward,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'New user reward (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum first order value (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxReferrals,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max referrals per user',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _validityDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coupon validity (days)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _campaignDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Campaign validity (days)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-grant rewards on eligible delivery'),
                value: _autoGrant,
                onChanged: (v) => setState(() => _autoGrant = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final model = ReferEarnCampaignModel(
                    id: widget.existing?.id ?? '',
                    name: _name.text.trim(),
                    couponCodePrefix: _prefix.text.trim(),
                    referrerRewardAmount: _int(_referrerReward, fallback: 50),
                    newUserRewardAmount: _int(_newUserReward, fallback: 50),
                    minimumOrderValue: _int(_minOrder, fallback: 299),
                    maxReferralsPerUser: _int(_maxReferrals, fallback: 10),
                    referralValidityDays: _int(_validityDays, fallback: 30),
                    campaignValidityDays: _int(_campaignDays, fallback: 365),
                    status: widget.existing?.status ?? 'active',
                    autoGrantRewards: _autoGrant,
                    stats: widget.existing?.stats ??
                        const ReferEarnCampaignStats(),
                    createdAt: widget.existing?.createdAt,
                    updatedAt: widget.existing?.updatedAt,
                  );
                  Navigator.pop(context, model);
                },
                child: Text(widget.existing == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
