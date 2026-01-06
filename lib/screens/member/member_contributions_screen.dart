import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../models/contribution_model.dart';

class MemberContributionsScreen extends StatefulWidget {
  const MemberContributionsScreen({super.key});

  @override
  State<MemberContributionsScreen> createState() =>
      _MemberContributionsScreenState();
}

class _MemberContributionsScreenState
    extends State<MemberContributionsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
      ),
      body: Consumer2<AuthProvider, ContributionProvider>(
        builder: (context, authProvider, contributionProvider, _) {
          if (contributionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            );
          }

          final contributions = _getFilteredContributions(
            contributionProvider.contributions,
          );

          if (contributions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No contributions found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await contributionProvider.loadContributions(
                      memberId: authProvider.currentMember?.id,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: contributions.length,
                    itemBuilder: (context, index) {
                      return _buildContributionCard(
                        context,
                        contributions[index],
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

  Widget _buildFilters() {
    return Container(
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
    );
  }

  List<Contribution> _getFilteredContributions(
    List<Contribution> contributions,
  ) {
    if (_selectedFilter == 'All') {
      return contributions;
    }
    
    switch (_selectedFilter) {
      case 'Paid':
        return contributions.where((c) => c.status == 'paid').toList();
      case 'Unpaid':
        // Unpaid includes all non-paid statuses: unpaid, overdue, due_soon
        return contributions.where((c) => c.status != 'paid').toList();
      case 'Overdue':
        return contributions.where((c) => c.status == 'overdue').toList();
      default:
        return contributions;
    }
  }

  Widget _buildContributionCard(
    BuildContext context,
    Contribution contribution,
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
      case 'due_soon':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.blue;
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
          contribution.title != null && contribution.title!.isNotEmpty
              ? contribution.title!
              : NumberFormat.currency(symbol: '₱').format(contribution.amount),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contribution.title != null && contribution.title!.isNotEmpty) ...[
              Text(
                NumberFormat.currency(symbol: '₱').format(contribution.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
            ],
            Text('Due: ${DateFormat('MMM dd, yyyy').format(contribution.dueDate)}'),
            if (contribution.paidDate != null)
              Text('Paid: ${DateFormat('MMM dd, yyyy').format(contribution.paidDate!)}'),
            if (contribution.remarks != null && contribution.remarks!.isNotEmpty)
              Text(contribution.remarks!),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            contribution.status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          _showContributionDetails(context, contribution);
        },
      ),
    );
  }

  void _showContributionDetails(
    BuildContext context,
    Contribution contribution,
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
              if (contribution.title != null && contribution.title!.isNotEmpty)
                _buildDetailRow('Title', contribution.title!),
              _buildDetailRow('Amount', NumberFormat.currency(symbol: '₱').format(contribution.amount)),
              _buildDetailRow('Due Date', DateFormat('MMMM dd, yyyy').format(contribution.dueDate)),
              if (contribution.paidDate != null)
                _buildDetailRow('Paid Date', DateFormat('MMMM dd, yyyy').format(contribution.paidDate!)),
              _buildDetailRow('Status', contribution.status.toUpperCase()),
              if (contribution.paymentMethod != null)
                _buildDetailRow('Payment Method', contribution.paymentMethod!),
              if (contribution.receiptNumber != null)
                _buildDetailRow('Receipt Number', contribution.receiptNumber!),
              if (contribution.remarks != null && contribution.remarks!.isNotEmpty)
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
}

