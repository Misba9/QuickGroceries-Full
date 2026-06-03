import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_campaign_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_settings_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/widgets/refer_earn_settings_panel.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/referral_record_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/services/refer_earn_admin_service.dart';
import 'package:quick_grocery_admin/view/refer_earn/services/refer_earn_export_service.dart';
import 'package:quick_grocery_admin/view/refer_earn/widgets/refer_earn_campaign_form_sheet.dart';

class ReferEarnManagementScreen extends StatefulWidget {
  const ReferEarnManagementScreen({super.key});

  @override
  State<ReferEarnManagementScreen> createState() =>
      _ReferEarnManagementScreenState();
}

class _ReferEarnManagementScreenState extends State<ReferEarnManagementScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReferEarnAdminService();
  final _search = TextEditingController();
  late final TabController _tabs;
  String _statusFilter = 'all';
  ReferEarnDashboardStats? _stats;
  List<TopReferrerModel> _topReferrers = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _refreshStats();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refreshStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _service.aggregateStats();
      final top = await _service.fetchTopReferrers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _topReferrers = top;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _openCampaignForm({ReferEarnCampaignModel? existing}) async {
    final model = await ReferEarnCampaignFormSheet.show(
      context,
      existing: existing,
    );
    if (model == null || !mounted) return;
    try {
      if (existing == null) {
        final id = await _service.createCampaign(model);
        final settings = await _service.watchSettings().first;
        if (!settings.enabled || settings.activeCampaignId.isEmpty) {
          await _service.setActiveCampaign(id);
        }
      } else {
        await _service.updateCampaign(model);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runAction(String action, ReferralRecordModel r) async {
    try {
      if (action == 'reject_reward') {
        final reason = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final c = TextEditingController();
            return AlertDialog(
              title: const Text('Reject referral'),
              content: TextField(
                controller: c,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, c.text),
                  child: const Text('Reject'),
                ),
              ],
            );
          },
        );
        if (reason == null) return;
        await _service.adminAction(
          action: action,
          referralId: r.id,
          reason: reason,
        );
      } else {
        await _service.adminAction(action: action, referralId: r.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReferralDetails(ReferralRecordModel r) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Referral ${r.id.substring(0, 8)}…'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Referrer: ${r.referrerName} (${r.referrerPhone})'),
              Text('Code: ${r.referrerCode}'),
              const SizedBox(height: 8),
              Text('Referred: ${r.referredUserName} (${r.referredUserPhone})'),
              Text('Status: ${r.statusLabel} · Reward: ${r.rewardStatus}'),
              if (r.firstOrderAmount != null)
                Text('First order: ₹${r.firstOrderAmount!.toStringAsFixed(0)}'),
              if (r.referrerCouponCode != null)
                Text('Referrer coupon: ${r.referrerCouponCode}'),
              if (r.referredCouponCode != null)
                Text('Welcome coupon: ${r.referredCouponCode}'),
              if (r.fraudFlags.isNotEmpty)
                Text('Flags: ${r.fraudFlags.join(', ')}',
                    style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = adminIsMobileWidth(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Refer & Earn',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshStats,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh stats',
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: isMobile,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Settings'),
                Tab(text: 'Campaigns'),
                Tab(text: 'Referrals'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildDashboard(isMobile),
                  ReferEarnSettingsPanel(service: _service),
                  _buildCampaigns(),
                  _buildReferralsTable(isMobile),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboard(bool isMobile) {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _stats!;
    final cards = [
      _StatCard('Invites sent', '${s.totalInvitesSent}', Icons.send),
      _StatCard('Successful', '${s.totalSuccessful}', Icons.check_circle),
      _StatCard('Pending', '${s.pendingReferrals}', Icons.hourglass_top),
      _StatCard('Rewarded', '${s.rewardedReferrals}', Icons.card_giftcard),
      _StatCard(
        'Discounts given',
        '₹${s.totalDiscountGiven.toStringAsFixed(0)}',
        Icons.savings,
      ),
      _StatCard('New users', '${s.newUsersAcquired}', Icons.person_add),
    ];

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: c,
                  ),
                )
                .toList(),
          ),
          AppSpacing.h20,
          Text(
            'Top referrers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h10,
          if (_topReferrers.isEmpty)
            const Text('No referral data yet.')
          else
            ..._topReferrers.map(
              (t) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${t.count}'),
                  ),
                  title: Text(t.referrerName),
                  subtitle: Text(
                    '${t.referrerCode} · ${t.referrerPhone} · ${t.rewarded} rewarded',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaigns() {
    return StreamBuilder<List<ReferEarnCampaignModel>>(
      stream: _service.watchCampaigns(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final campaigns = snap.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _openCampaignForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('New campaign'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: campaigns.length,
                itemBuilder: (context, i) {
                  final c = campaigns[i];
                  return Card(
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: Text(
                        'Referrer ₹${c.referrerRewardAmount} · New user ₹${c.newUserRewardAmount} · Min order ₹${c.minimumOrderValue}\n'
                        'Prefix ${c.couponCodePrefix} · Max ${c.maxReferralsPerUser} refs · ${c.status}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          switch (action) {
                            case 'edit':
                              await _openCampaignForm(existing: c);
                            case 'pause':
                              await _service.setCampaignStatus(
                                c.id,
                                c.isPaused ? 'active' : 'paused',
                              );
                            case 'activate':
                              await _service.setActiveCampaign(c.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'pause',
                            child: Text(c.isPaused ? 'Resume' : 'Pause'),
                          ),
                          const PopupMenuItem(
                            value: 'activate',
                            child: Text('Set as active'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReferralsTable(bool isMobile) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 240,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search referrals…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All statuses')),
                  DropdownMenuItem(
                    value: 'first_order_pending',
                    child: Text('First order pending'),
                  ),
                  DropdownMenuItem(
                    value: 'reward_eligible',
                    child: Text('Reward eligible'),
                  ),
                  DropdownMenuItem(
                    value: 'reward_granted',
                    child: Text('Reward granted'),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('Rejected'),
                  ),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final list = await _service
                      .watchReferrals(
                        statusFilter: _statusFilter,
                        search: _search.text,
                      )
                      .first;
                  if (!mounted) return;
                  await ReferEarnExportService.exportReferralsCsv(
                    context,
                    list,
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('CSV'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final list = await _service
                      .watchReferrals(
                        statusFilter: _statusFilter,
                        search: _search.text,
                      )
                      .first;
                  if (!mounted) return;
                  await ReferEarnExportService.exportReferralsExcel(
                    context,
                    list,
                  );
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('Excel'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ReferralRecordModel>>(
            stream: _service.watchReferrals(
              statusFilter: _statusFilter,
              search: _search.text,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return const Center(child: Text('No referrals found'));
              }
              if (isMobile) {
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _referralCard(rows[i]),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Referrer')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Referred')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Signup')),
                    DataColumn(label: Text('Order ₹')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Reward')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: rows.map((r) => _dataRow(r)).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  DataRow _dataRow(ReferralRecordModel r) {
    final fmt = DateFormat('dd MMM yyyy');
    return DataRow(
      cells: [
        DataCell(Text(r.id.substring(0, 8))),
        DataCell(Text(r.referrerName)),
        DataCell(Text(r.referrerPhone)),
        DataCell(Text(r.referrerCode)),
        DataCell(Text(r.referredUserName)),
        DataCell(Text(r.referredUserPhone)),
        DataCell(Text(
          r.signupDate != null ? fmt.format(r.signupDate!) : '—',
        )),
        DataCell(Text(
          r.firstOrderAmount != null
              ? r.firstOrderAmount!.toStringAsFixed(0)
              : '—',
        )),
        DataCell(Text(r.statusLabel)),
        DataCell(Text(r.rewardStatus)),
        DataCell(_actionMenu(r)),
      ],
    );
  }

  Widget _referralCard(ReferralRecordModel r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.referrerName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Code ${r.referrerCode} → ${r.referredUserName}'),
            Text('${r.statusLabel} · ${r.rewardStatus}'),
            Align(alignment: Alignment.centerRight, child: _actionMenu(r)),
          ],
        ),
      ),
    );
  }

  Widget _actionMenu(ReferralRecordModel r) {
    return PopupMenuButton<String>(
      onSelected: (a) {
        if (a == 'view') {
          _showReferralDetails(r);
        } else {
          _runAction(a, r);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'view', child: Text('View details')),
        if (r.status == 'reward_eligible')
          const PopupMenuItem(
            value: 'approve_reward',
            child: Text('Approve reward'),
          ),
        if (r.status != 'reward_granted' && r.status != 'rejected')
          const PopupMenuItem(
            value: 'reject_reward',
            child: Text('Reject'),
          ),
        if (r.status == 'reward_granted')
          const PopupMenuItem(
            value: 'resend_coupon',
            child: Text('Resend coupon'),
          ),
        const PopupMenuItem(
          value: 'disable_referral',
          child: Text('Disable'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColor.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
