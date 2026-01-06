import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/member_model.dart';
import '../../models/contribution_model.dart';

class SendReminderScreen extends StatefulWidget {
  const SendReminderScreen({super.key});

  @override
  State<SendReminderScreen> createState() => _SendReminderScreenState();
}

class _SendReminderScreenState extends State<SendReminderScreen> {
  final Set<String> _selectedMemberIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Reminders'),
        actions: [
          if (_selectedMemberIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _sendRemindersToSelected(context),
                icon: const Icon(Icons.send, size: 18),
                label: Text('Send (${_selectedMemberIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: Consumer3<ContributionProvider, MemberProvider, ReminderProvider>(
        builder: (context, contributionProvider, memberProvider, reminderProvider, _) {
          // Get all overdue contributions
          final overdueContributions = contributionProvider.contributions
              .where((c) => c.status == 'overdue' || 
                           (c.dueDate.isBefore(DateTime.now()) && c.status != 'paid'))
              .toList();

          // Group by member
          final Map<String, List<Contribution>> memberContributions = {};
          for (var contribution in overdueContributions) {
            if (!memberContributions.containsKey(contribution.memberId)) {
              memberContributions[contribution.memberId] = [];
            }
            memberContributions[contribution.memberId]!.add(contribution);
          }

          if (memberContributions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No Overdue Contributions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All contributions are up to date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${memberContributions.length} Member(s) with Overdue Contributions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select members to send reminder notifications',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...memberContributions.entries.map((entry) {
                final member = memberProvider.getMemberById(entry.key);
                // Exclude admin from reminder list
                if (member == null || member.role == 'admin') return const SizedBox.shrink();

                final contributions = entry.value;
                final totalOverdue = contributions.fold(0.0, (sum, c) => sum + c.amount);
                final isSelected = _selectedMemberIds.contains(member.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedMemberIds.add(member.id!);
                        } else {
                          _selectedMemberIds.remove(member.id!);
                        }
                      });
                    },
                    title: Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${member.memberId}'),
                        Text(member.email),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${contributions.length} Overdue Contribution(s)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              Text(
                                'Total: ${NumberFormat.currency(symbol: '₱').format(totalOverdue)}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...contributions.take(3).map((c) {
                                final daysOverdue = DateTime.now().difference(c.dueDate).inDays;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '• ${c.title ?? "Contribution"}: ${NumberFormat.currency(symbol: '₱').format(c.amount)} (${daysOverdue} days overdue)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }),
                              if (contributions.length > 3)
                                Text(
                                  '... and ${contributions.length - 3} more',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: _selectedMemberIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _sendRemindersToSelected(context),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                'Send (${_selectedMemberIds.length})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Future<void> _sendRemindersToSelected(BuildContext context) async {
    if (_selectedMemberIds.isEmpty) return;

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    final contributionProvider = Provider.of<ContributionProvider>(context, listen: false);
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 16),
                  Text('Sending reminders...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    int successCount = 0;
    int failCount = 0;
    final List<String> successMembers = [];
    final List<String> failedMembers = [];

    for (final memberId in _selectedMemberIds) {
      final member = memberProvider.getMemberById(memberId);
      if (member == null) continue;

      // Get overdue contributions for this member
      final overdueContributions = contributionProvider.contributions
          .where((c) => c.memberId == memberId &&
                       (c.status == 'overdue' || 
                        (c.dueDate.isBefore(DateTime.now()) && c.status != 'paid')))
          .toList();

      if (overdueContributions.isEmpty) continue;

      // Send reminder for the first overdue contribution
      final contribution = overdueContributions.first;
      final success = await reminderProvider.sendReminder(
        member: member,
        contribution: contribution,
        type: 'overdue',
      );

      if (success) {
        successCount++;
        successMembers.add(member.name);
      } else {
        failCount++;
        failedMembers.add(member.name);
      }
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            failCount == 0 ? Icons.check_circle : Icons.info,
            size: 48,
            color: failCount == 0 ? Colors.green : Colors.orange,
          ),
          title: Text(
            failCount == 0 ? 'Success!' : 'Reminders Sent',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: failCount == 0 ? Colors.green : Colors.orange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failCount == 0
                      ? 'All reminders sent successfully!'
                      : 'Reminders sent: $successCount successful, $failCount failed',
                  style: const TextStyle(fontSize: 16),
                ),
                if (successMembers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sent to:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...successMembers.map((name) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                          ],
                        ),
                      )),
                ],
                if (failedMembers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Failed:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...failedMembers.map((name) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.error, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close reminder screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

