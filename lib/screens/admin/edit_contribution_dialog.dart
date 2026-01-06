import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/contribution_model.dart';

class EditContributionDialog extends StatefulWidget {
  final Contribution contribution;

  const EditContributionDialog({super.key, required this.contribution});

  @override
  State<EditContributionDialog> createState() => _EditContributionDialogState();
}

class _EditContributionDialogState extends State<EditContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.contribution.title ?? '';
    _amountController.text = widget.contribution.amount.toString();
    _dueDate = widget.contribution.dueDate;
    _selectedStatus = widget.contribution.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final contributionProvider =
        Provider.of<ContributionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final updatedContribution = widget.contribution.copyWith(
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      dueDate: _dueDate!,
      status: _selectedStatus!,
      paidDate: _selectedStatus == 'paid' && widget.contribution.paidDate == null
          ? DateTime.now()
          : widget.contribution.paidDate,
    );

    final success = await contributionProvider.updateContribution(
      updatedContribution,
      userId: authProvider.userId,
      oldContribution: widget.contribution,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update contribution'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Contribution'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g., Monthly Dues, Special Contribution',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('MMMM dd, yyyy').format(_dueDate!)
                        : 'Select due date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info),
                ),
                items: ['unpaid', 'paid', 'overdue'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select status';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

