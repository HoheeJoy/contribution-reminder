import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/contribution_model.dart';

class AddContributionDialog extends StatefulWidget {
  const AddContributionDialog({super.key});

  @override
  State<AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedMemberId;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
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

    final contribution = Contribution(
      memberId: _selectedMemberId!,
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      dueDate: _dueDate!,
      status: 'unpaid',
      createdAt: DateTime.now(),
    );

    final success = await contributionProvider.addContribution(
      contribution,
      userId: authProvider.userId,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution added successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add contribution'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contribution'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Consumer<MemberProvider>(
            builder: (context, memberProvider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Member',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: memberProvider.members
                        .where((m) => m.role != 'admin') // Exclude admin
                        .map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMemberId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a member';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAdd,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

