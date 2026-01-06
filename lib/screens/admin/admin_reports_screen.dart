import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/member_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer2<ContributionProvider, MemberProvider>(
        builder: (context, contributionProvider, memberProvider, _) {
          final contributions = _dateRange != null
              ? contributionProvider.filterByDateRange(
                  _dateRange!.start,
                  _dateRange!.end,
                )
              : contributionProvider.contributions;

          final totalPaid = contributions
              .where((c) => c.status == 'paid')
              .fold(0.0, (sum, c) => sum + c.amount);
          final totalUnpaid = contributions
              .where((c) => c.status != 'paid')
              .fold(0.0, (sum, c) => sum + c.amount);
          final totalOverdue = contributions
              .where((c) => c.status == 'overdue')
              .fold(0.0, (sum, c) => sum + c.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date Range:'),
                            TextButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _dateRange != null
                                    ? '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}'
                                    : 'Select Date Range',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  context,
                  'Total Paid',
                  NumberFormat.currency(symbol: '₱').format(totalPaid),
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  context,
                  'Total Unpaid',
                  NumberFormat.currency(symbol: '₱').format(totalUnpaid),
                  Colors.orange,
                  Icons.pending,
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  context,
                  'Total Overdue',
                  NumberFormat.currency(symbol: '₱').format(totalOverdue),
                  Colors.red,
                  Icons.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Summary by Member',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...memberProvider.members
                    .where((m) => m.role != 'admin') // Exclude admin from reports
                    .map((member) {
                  final memberContributions = contributions
                      .where((c) => c.memberId == member.id)
                      .toList();
                  final memberPaid = memberContributions
                      .where((c) => c.status == 'paid')
                      .fold(0.0, (sum, c) => sum + c.amount);
                  final memberUnpaid = memberContributions
                      .where((c) => c.status != 'paid')
                      .fold(0.0, (sum, c) => sum + c.amount);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(member.name),
                      subtitle: Text('ID: ${member.memberId}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Paid: ${NumberFormat.currency(symbol: '₱').format(memberPaid)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Unpaid: ${NumberFormat.currency(symbol: '₱').format(memberUnpaid)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

}

