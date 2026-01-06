import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/organization_provider.dart';
import '../../models/organization_model.dart';

class ContributionScheduleScreen extends StatefulWidget {
  const ContributionScheduleScreen({super.key});

  @override
  State<ContributionScheduleScreen> createState() =>
      _ContributionScheduleScreenState();
}

class _ContributionScheduleScreenState
    extends State<ContributionScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _frequency = 'Monthly';
  int _dueDay = 1;
  bool _isLoading = false;

  final List<String> _frequencies = ['Monthly', 'Weekly', 'Quarterly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _loadScheduleSettings();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleSettings() async {
    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    final org = orgProvider.currentOrganization;
    
    if (org != null && org.settings.isNotEmpty) {
      setState(() {
        _amountController.text = org.settings['default_amount']?.toString() ?? '';
        _frequency = org.settings['frequency'] ?? 'Monthly';
        _dueDay = org.settings['due_day'] ?? 1;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    final org = orgProvider.currentOrganization;

    if (org != null) {
      final updatedSettings = Map<String, dynamic>.from(org.settings);
      updatedSettings['default_amount'] = double.tryParse(_amountController.text) ?? 0.0;
      updatedSettings['frequency'] = _frequency;
      updatedSettings['due_day'] = _dueDay;

      await orgProvider.updateOrganization(
        org.copyWith(settings: updatedSettings),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution schedule saved successfully')),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribution Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure default contribution schedule for all members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Default Contribution Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Default amount for new contributions',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter default amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.calendar_today),
                  helperText: 'How often contributions are due',
                ),
                items: _frequencies.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _frequency = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _dueDay,
                decoration: const InputDecoration(
                  labelText: 'Due Day of Month',
                  prefixIcon: Icon(Icons.event),
                  helperText: 'Day of month when contributions are due',
                ),
                items: List.generate(28, (index) => index + 1).map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('Day $day'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _dueDay = value!);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSchedule,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Schedule'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Schedule Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• New contributions will use these default settings\n'
                        '• You can override these settings for individual contributions\n'
                        '• Schedule changes apply to future contributions only',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

