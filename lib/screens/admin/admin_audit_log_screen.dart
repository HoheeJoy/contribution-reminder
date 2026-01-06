import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _db.getAuditLogs(limit: 100);
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedFilter == 'All') return _auditLogs;
    return _auditLogs.where((log) => log['entity_type'] == _selectedFilter.toLowerCase()).toList();
  }

  String _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'status_change':
        return '🔄';
      default:
        return '📝';
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'status_change':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit History'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Member', 'Contribution', 'Reminder'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No audit logs found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAuditLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return _buildAuditLogCard(context, log);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context, Map<String, dynamic> log) {
    final action = log['action'] ?? '';
    final entityType = log['entity_type'] ?? '';
    final timestamp = DateTime.parse(log['timestamp']);
    final description = log['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(action).withValues(alpha: 0.1),
          child: Text(
            _getActionIcon(action),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          '${action.toUpperCase()} ${entityType.toUpperCase()}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          _showAuditLogDetails(context, log);
        },
      ),
    );
  }

  void _showAuditLogDetails(BuildContext context, Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${log['action']?.toString().toUpperCase()} ${log['entity_type']?.toString().toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', log['action'] ?? ''),
              _buildDetailRow('Entity Type', log['entity_type'] ?? ''),
              _buildDetailRow('Entity ID', log['entity_id'] ?? ''),
              if (log['old_value'] != null)
                _buildDetailRow('Old Value', log['old_value']),
              if (log['new_value'] != null)
                _buildDetailRow('New Value', log['new_value']),
              if (log['description'] != null && log['description'].toString().isNotEmpty)
                _buildDetailRow('Description', log['description']),
              _buildDetailRow(
                'Timestamp',
                DateFormat('MMMM dd, yyyy hh:mm:ss a').format(
                  DateTime.parse(log['timestamp']),
                ),
              ),
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
}

