import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/member_model.dart';
import 'add_member_dialog.dart';
import 'edit_member_dialog.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).loadMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: Consumer<MemberProvider>(
        builder: (context, memberProvider, _) {
          if (memberProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          // Filter out admin members - only show regular members
          var members = memberProvider.members.where((m) => m.role != 'admin').toList();

          // Apply search filter
          if (_searchController.text.isNotEmpty) {
            members = memberProvider.searchMembers(_searchController.text)
                .where((m) => m.role != 'admin').toList();
          }

          // Apply status filter
          if (_selectedFilter == 'Active') {
            members = members.where((m) => m.isActive).toList();
          } else if (_selectedFilter == 'Inactive') {
            members = members.where((m) => !m.isActive).toList();
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or email',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            color: Colors.grey.shade600,
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Inactive'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          selectedColor: const Color(0xFF6366F1),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No members found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          return _buildMemberCard(context, members[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Member',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Member member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: member.isActive
              ? const Color(0xFF6366F1)
              : Colors.grey.shade400,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
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
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: member.isActive 
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: member.isActive ? const Color(0xFF10B981) : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Deactivate/Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(context, member, value),
            ),
          ],
        ),
        onTap: () => _showMemberDetails(context, member),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    Member member,
    String action,
  ) {
    switch (action) {
      case 'view':
        _showMemberDetails(context, member);
        break;
      case 'edit':
        _showEditMemberDialog(context, member);
        break;
      case 'deactivate':
        _toggleMemberStatus(context, member);
        break;
      case 'delete':
        _deleteMember(context, member);
        break;
    }
  }

  void _showMemberDetails(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Member ID', member.memberId),
              _buildDetailRow('Email', member.email),
              if (member.phone != null)
                _buildDetailRow('Phone', member.phone!),
              _buildDetailRow('Status', member.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Role', member.role),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );
  }

  void _showEditMemberDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (context) => EditMemberDialog(member: member),
    );
  }

  Future<void> _toggleMemberStatus(BuildContext context, Member member) async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await memberProvider.updateMember(
      member.copyWith(isActive: !member.isActive),
      userId: authProvider.userId,
      oldMember: member,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member ${member.isActive ? 'deactivated' : 'activated'}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteMember(BuildContext context, Member member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final memberProvider =
          Provider.of<MemberProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await memberProvider.deleteMember(
        member.id!,
        userId: authProvider.userId,
        memberName: member.name,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member deleted')),
        );
      }
    }
  }
}

