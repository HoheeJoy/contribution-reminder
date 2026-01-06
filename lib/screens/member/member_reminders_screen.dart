import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/reminder_model.dart';

class MemberRemindersScreen extends StatelessWidget {
  const MemberRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Consumer2<AuthProvider, ReminderProvider>(
        builder: (context, authProvider, reminderProvider, _) {
          if (reminderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = reminderProvider.reminders;
          final upcoming = reminderProvider.getUpcomingReminders();
          final overdue = reminderProvider.getOverdueReminders();

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders',
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
              await reminderProvider.loadReminders(
                memberId: authProvider.currentMember?.id,
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (overdue.isNotEmpty) ...[
                    Text(
                      'Overdue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...overdue.map((r) => _buildReminderCard(context, r, reminderProvider)),
                    const SizedBox(height: 24),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    Text(
                      'Upcoming',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map((r) => _buildReminderCard(context, r, reminderProvider)),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...reminders
                      .where((r) => r.isRead || (!upcoming.contains(r) && !overdue.contains(r)))
                      .map((r) => _buildReminderCard(context, r, reminderProvider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderProvider reminderProvider,
  ) {
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
          reminder.type == 'overdue' ? 'Overdue Contribution' : 'Due Soon',
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
              DateFormat('MMM dd, yyyy hh:mm a').format(reminder.sentAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        trailing: reminder.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () async {
          if (!reminder.isRead) {
            await reminderProvider.markAsRead(reminder.id!);
          }
        },
      ),
    );
  }
}

