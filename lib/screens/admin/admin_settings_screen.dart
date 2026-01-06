import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/organization_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import 'contribution_schedule_screen.dart';
import 'admin_audit_log_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: const Text('Name'),
                      subtitle: Text(authProvider.currentMember?.name ?? 'Unknown'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editAdminName(context, authProvider),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.blue),
                      title: const Text('Email'),
                      subtitle: Text(authProvider.currentMember?.email ?? 'Unknown'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editAdminEmail(context, authProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Contribution Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Contribution Schedule'),
                      subtitle: const Text('Set default contribution schedule and amounts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ContributionScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Notification Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Reminder Settings'),
                      subtitle: const Text('Configure reminder rules'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder settings coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'System',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Audit History'),
                      subtitle: const Text('View system activity and changes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminAuditLogScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Backup Data'),
                      subtitle: const Text('Export database backup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup functionality coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Import database backup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restore functionality coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        'Signed in as',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      subtitle: Text(
                        authProvider.currentMember?.email ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Log out and return to login screen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleSignOut(context, authProvider),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _editAdminName(BuildContext context, AuthProvider authProvider) {
    final member = authProvider.currentMember;
    if (member == null) return;

    _showEditDialog(
      context,
      'Name',
      member.name,
      (value) async {
        final memberProvider = Provider.of<MemberProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final updatedMember = member.copyWith(name: value);
        await memberProvider.updateMember(
          updatedMember,
          userId: authProvider.userId,
          oldMember: member,
        );
        
        // Update auth provider's current member
        authProvider.updateCurrentMember(updatedMember);
      },
    );
  }

  void _editAdminEmail(BuildContext context, AuthProvider authProvider) {
    final member = authProvider.currentMember;
    if (member == null) return;

    _showEditDialog(
      context,
      'Email',
      member.email,
      (value) async {
        final memberProvider = Provider.of<MemberProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final updatedMember = member.copyWith(email: value);
        await memberProvider.updateMember(
          updatedMember,
          userId: authProvider.userId,
          oldMember: member,
        );
        
        // Update auth provider's current member
        authProvider.updateCurrentMember(updatedMember);
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

