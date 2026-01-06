import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'edit_member_profile_dialog.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final member = authProvider.currentMember;
          if (member == null) {
            return const Center(child: Text('No member data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
                const SizedBox(height: 32),
                Container(
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
                  child: Column(
                    children: [
                      _buildProfileTile(
                        context,
                        Icons.badge,
                        'Member ID',
                        member.memberId,
                      ),
                      const Divider(),
                      _buildProfileTile(
                        context,
                        Icons.email,
                        'Email',
                        member.email,
                      ),
                      if (member.phone != null) ...[
                        const Divider(),
                        _buildProfileTile(
                          context,
                          Icons.phone,
                          'Phone',
                          member.phone!,
                        ),
                      ],
                      const Divider(),
                      _buildProfileTile(
                        context,
                        Icons.calendar_today,
                        'Join Date',
                        DateFormat('MMMM dd, yyyy').format(member.joinDate),
                      ),
                      const Divider(),
                      _buildProfileTile(
                        context,
                        Icons.person,
                        'Role',
                        member.role.toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
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
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        title: const Text(
                          'Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Update your profile information'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => EditMemberProfileDialog(member: member),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                        ),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Log out and return to login screen'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                        onTap: () => _handleSignOut(context, authProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
          fontSize: 16,
        ),
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
}

