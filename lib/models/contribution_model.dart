class Contribution {
  final String? id;
  final String memberId;
  final String? title;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'paid', 'unpaid', 'overdue'
  final String? paymentMethod;
  final String? remarks;
  final String? receiptNumber;
  final DateTime createdAt;

  Contribution({
    this.id,
    required this.memberId,
    this.title,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paymentMethod,
    this.remarks,
    this.receiptNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'remarks': remarks,
      'receipt_number': receiptNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      id: map['id']?.toString(),
      memberId: map['member_id'] ?? '',
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date']),
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      status: map['status'] ?? 'unpaid',
      paymentMethod: map['payment_method'],
      remarks: map['remarks'],
      receiptNumber: map['receipt_number'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Contribution copyWith({
    String? id,
    String? memberId,
    String? title,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? paymentMethod,
    String? remarks,
    String? receiptNumber,
    DateTime? createdAt,
  }) {
    return Contribution(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Calculate status based on due date and paid date
  String calculateStatus() {
    if (paidDate != null) {
      return 'paid';
    }
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return 'overdue';
    }
    final daysUntilDue = dueDate.difference(now).inDays;
    if (daysUntilDue <= 3) {
      return 'due_soon';
    }
    return 'unpaid';
  }
}

