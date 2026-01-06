import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../models/reminder_model.dart';

class AdminRemindersScreen extends StatelessWidget {
  const AdminRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendBulkReminders(context),
            tooltip: 'Send Bulk Reminders',
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, _) {
          if (reminderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = reminderProvider.reminders;

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders sent',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await reminderProvider.loadReminders();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(context, reminders[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, Reminder reminder) {
    Color typeColor;
    IconData typeIcon;

    if (reminder.type == 'overdue') {
      typeColor = Colors.red;
      typeIcon = Icons.error;
    } else {
      typeColor = Colors.orange;
      typeIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.1),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          reminder.type == 'overdue' ? 'Overdue Reminder' : 'Due Soon Reminder',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reminder.message),
            const SizedBox(height: 4),
            Text(
              'Sent: ${DateFormat('MMM dd, yyyy hh:mm a').format(reminder.sentAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reminder.isRead ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.isRead ? 'Read' : 'Unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Future<void> _sendBulkReminders(BuildContext context) async {
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final contributionProvider =
        Provider.of<ContributionProvider>(context, listen: false);

    await memberProvider.loadMembers();
    await contributionProvider.loadContributions();

    await reminderProvider.checkAndSendReminders(
      members: memberProvider.members.where((m) => m.role != 'admin').toList(), // Exclude admin
      contributions: contributionProvider.contributions,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk reminders sent')),
      );
    }
  }
}

