import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/contribution_model.dart';

class MemberHomeTab extends StatelessWidget {
  const MemberHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Consumer3<AuthProvider, ContributionProvider, ReminderProvider>(
        builder: (context, authProvider, contributionProvider, reminderProvider, _) {
          if (contributionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          final member = authProvider.currentMember;
          if (member == null) {
            return const Center(child: Text('No member data'));
          }

          final contributions = contributionProvider.contributions;
          final unpaidBalance = contributions
              .where((c) => c.status != 'paid')
              .fold(0.0, (sum, c) => sum + c.amount);

          final nextDue = contributions
              .where((c) => c.status != 'paid')
              .isNotEmpty
              ? contributions
                  .where((c) => c.status != 'paid')
                  .reduce((a, b) =>
                      a.dueDate.isBefore(b.dueDate) ? a : b)
              : null;

          final paidThisMonth = contributions
              .where((c) =>
                  c.status == 'paid' &&
                  c.paidDate != null &&
                  c.paidDate!.month == DateTime.now().month &&
                  c.paidDate!.year == DateTime.now().year)
              .fold(0.0, (sum, c) => sum + c.amount);

          final missedCount = contributions
              .where((c) => c.status == 'overdue')
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              await contributionProvider.loadContributions(
                memberId: member.id,
              );
              await reminderProvider.loadReminders(memberId: member.id);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceCard(context, unpaidBalance),
                  const SizedBox(height: 16),
                  if (nextDue != null) _buildNextDueCard(context, nextDue),
                  const SizedBox(height: 16),
                  _buildSummaryCards(
                    context,
                    paidThisMonth,
                    missedCount,
                    contributions.length,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    Color balanceColor;
    String statusText;
    
    if (balance == 0) {
      balanceColor = const Color(0xFF10B981);
      statusText = 'All Paid';
    } else {
      balanceColor = const Color(0xFFEF4444);
      statusText = 'Unpaid';
    }

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    balance == 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: balanceColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '₱').format(balance),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextDueCard(BuildContext context, Contribution nextDue) {
    final daysUntilDue = nextDue.dueDate.difference(DateTime.now()).inDays;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (daysUntilDue < 0) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Overdue';
      statusIcon = Icons.error_rounded;
    } else if (daysUntilDue <= 3) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Due Soon';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusColor = const Color(0xFF6366F1);
      statusText = 'Upcoming';
      statusIcon = Icons.calendar_today_rounded;
    }

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Next Due Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('MMMM dd, yyyy').format(nextDue.dueDate),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${NumberFormat.currency(symbol: '₱').format(nextDue.amount)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              daysUntilDue >= 0
                  ? '$daysUntilDue days remaining'
                  : '${daysUntilDue.abs()} days overdue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: daysUntilDue < 0 ? statusColor : const Color(0xFF6B7280),
                    fontWeight: daysUntilDue < 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    double paidThisMonth,
    int missedCount,
    int totalContributions,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    NumberFormat.currency(symbol: '₱').format(paidThisMonth),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid this month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$missedCount',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Missed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

