class Reminder {
  final String? id;
  final String memberId;
  final String contributionId;
  final String type; // 'due_soon', 'overdue'
  final DateTime sentAt;
  final bool isRead;
  final String message;

  Reminder({
    this.id,
    required this.memberId,
    required this.contributionId,
    required this.type,
    required this.sentAt,
    this.isRead = false,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'contribution_id': contributionId,
      'type': type,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'message': message,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    // Handle both SQLite (1/0) and Firestore (boolean) formats
    final isReadValue = map['is_read'];
    final isRead = isReadValue is bool 
        ? isReadValue 
        : (isReadValue == 1 || isReadValue == true);
    
    return Reminder(
      id: map['id']?.toString(),
      memberId: map['member_id'] ?? '',
      contributionId: map['contribution_id'] ?? '',
      type: map['type'] ?? 'due_soon',
      sentAt: DateTime.parse(map['sent_at']),
      isRead: isRead,
      message: map['message'] ?? '',
    );
  }

  Reminder copyWith({
    String? id,
    String? memberId,
    String? contributionId,
    String? type,
    DateTime? sentAt,
    bool? isRead,
    String? message,
  }) {
    return Reminder(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      contributionId: contributionId ?? this.contributionId,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      message: message ?? this.message,
    );
  }
}

