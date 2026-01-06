import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/contribution_model.dart';
import 'add_contribution_dialog.dart';
import 'edit_contribution_dialog.dart';

class AdminContributionsScreen extends StatefulWidget {
  const AdminContributionsScreen({super.key});

  @override
  State<AdminContributionsScreen> createState() =>
      _AdminContributionsScreenState();
}

class _AdminContributionsScreenState extends State<AdminContributionsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContributionProvider>(context, listen: false)
          .loadContributions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
      ),
      body: Consumer2<ContributionProvider, MemberProvider>(
        builder: (context, contributionProvider, memberProvider, _) {
          if (contributionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          var contributions = contributionProvider.contributions;

          if (_selectedFilter != 'All') {
            contributions = contributionProvider.filterByStatus(_selectedFilter.toLowerCase());
          }

          return Column(
            children: [
              // Record Payment Banner
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.1),
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        color: Color(0xFF10B981),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Payment',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add new contribution or record payment for a member',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddContributionDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Paid', 'Unpaid', 'Overdue'].map((filter) {
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
                child: contributions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No contributions found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await contributionProvider.loadContributions();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: contributions.length,
                          itemBuilder: (context, index) {
                            final contribution = contributions[index];
                            final member = memberProvider.getMemberById(
                              contribution.memberId,
                            );
                            return _buildContributionCard(
                              context,
                              contribution,
                              member?.name ?? 'Unknown',
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContributionCard(
    BuildContext context,
    Contribution contribution,
    String memberName,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (contribution.status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          memberName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contribution.title != null && contribution.title!.isNotEmpty) ...[
              Text(
                contribution.title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              NumberFormat.currency(symbol: '₱').format(contribution.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Due: ${DateFormat('MMM dd, yyyy').format(contribution.dueDate)}'),
            if (contribution.paidDate != null)
              Text('Paid: ${DateFormat('MMM dd, yyyy').format(contribution.paidDate!)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'mark_paid',
              child: Text('Mark as Paid'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) =>
              _handleMenuAction(context, contribution, value),
        ),
        onTap: () => _showContributionDetails(context, contribution, memberName),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    Contribution contribution,
    String action,
  ) {
    switch (action) {
      case 'view':
        _showContributionDetails(context, contribution, '');
        break;
      case 'edit':
        _showEditContributionDialog(context, contribution);
        break;
      case 'mark_paid':
        _markAsPaid(context, contribution);
        break;
      case 'delete':
        _deleteContribution(context, contribution);
        break;
    }
  }

  void _showContributionDetails(
    BuildContext context,
    Contribution contribution,
    String memberName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contribution Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (memberName.isNotEmpty)
                _buildDetailRow('Member', memberName),
              if (contribution.title != null && contribution.title!.isNotEmpty)
                _buildDetailRow('Title', contribution.title!),
              _buildDetailRow(
                'Amount',
                NumberFormat.currency(symbol: '₱').format(contribution.amount),
              ),
              _buildDetailRow(
                'Due Date',
                DateFormat('MMMM dd, yyyy').format(contribution.dueDate),
              ),
              if (contribution.paidDate != null)
                _buildDetailRow(
                  'Paid Date',
                  DateFormat('MMMM dd, yyyy').format(contribution.paidDate!),
                ),
              _buildDetailRow('Status', contribution.status.toUpperCase()),
              if (contribution.paymentMethod != null)
                _buildDetailRow('Payment Method', contribution.paymentMethod!),
              if (contribution.receiptNumber != null)
                _buildDetailRow('Receipt Number', contribution.receiptNumber!),
              if (contribution.remarks != null &&
                  contribution.remarks!.isNotEmpty)
                _buildDetailRow('Remarks', contribution.remarks!),
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
            width: 120,
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

  void _showAddContributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddContributionDialog(),
    );
  }

  void _showEditContributionDialog(
    BuildContext context,
    Contribution contribution,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditContributionDialog(contribution: contribution),
    );
  }

  Future<void> _markAsPaid(
    BuildContext context,
    Contribution contribution,
  ) async {
    final contributionProvider =
        Provider.of<ContributionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await contributionProvider.updateContribution(
      contribution.copyWith(
        status: 'paid',
        paidDate: DateTime.now(),
      ),
      userId: authProvider.userId,
      oldContribution: contribution,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution marked as paid')),
      );
    }
  }

  Future<void> _deleteContribution(
    BuildContext context,
    Contribution contribution,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: const Text('Are you sure you want to delete this contribution?'),
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
      final contributionProvider =
          Provider.of<ContributionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await contributionProvider.deleteContribution(
        contribution.id!,
        userId: authProvider.userId,
        amount: contribution.amount,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution deleted')),
        );
      }
    }
  }
}

