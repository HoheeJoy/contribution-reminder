import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/member_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/organization_provider.dart';
import 'add_contribution_dialog.dart';
import 'send_reminder_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer4<MemberProvider, ContributionProvider, ReminderProvider,
          OrganizationProvider>(
        builder: (context, memberProvider, contributionProvider,
            reminderProvider, orgProvider, _) {
          if (memberProvider.isLoading || contributionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          // Exclude admin from member counts
          final regularMembers = memberProvider.members.where((m) => m.role != 'admin').toList();
          final totalMembers = regularMembers.length;
          final activeMembers = regularMembers.where((m) => m.isActive).length;
          final totalCollected = contributionProvider.getTotalPaid();
          final totalUnpaid = contributionProvider.getTotalUnpaid();
          final thisMonthCollected = contributionProvider.contributions
              .where((c) =>
                  c.status == 'paid' &&
                  c.paidDate != null &&
                  c.paidDate!.month == DateTime.now().month &&
                  c.paidDate!.year == DateTime.now().year)
              .fold(0.0, (sum, c) => sum + c.amount);

          return RefreshIndicator(
            onRefresh: () async {
              await memberProvider.loadMembers();
              await contributionProvider.loadContributions();
              await reminderProvider.loadReminders();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatCard(
                    context,
                    'Total Collected',
                    NumberFormat.currency(symbol: '₱').format(totalCollected),
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'This Month',
                          NumberFormat.currency(symbol: '₱')
                              .format(thisMonthCollected),
                          Icons.calendar_today_rounded,
                          const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Unpaid',
                          NumberFormat.currency(symbol: '₱').format(totalUnpaid),
                          Icons.warning_rounded,
                          const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Members',
                          '$totalMembers',
                          Icons.people_rounded,
                          const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Active',
                          '$activeMembers',
                          Icons.person_rounded,
                          const Color(0xFF14B8A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        context,
                        'Record Payment',
                        Icons.payment_rounded,
                        const Color(0xFF10B981),
                        () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddContributionDialog(),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Send Reminder',
                        Icons.notifications_rounded,
                        const Color(0xFFF59E0B),
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SendReminderScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Generate Report',
                        Icons.assessment_rounded,
                        const Color(0xFF8B5CF6),
                        () {
                          // Navigate to reports tab
                          _navigateToTab(context, 3);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex) {
    // Find the AdminDashboardScreen and change tab
    final navigator = Navigator.of(context);
    navigator.popUntil((route) {
      if (route.settings.name == '/main' || route.isFirst) {
        // Trigger tab change through a callback or state management
        return true;
      }
      return false;
    });
  }
}

