class Member {
  final String? id;
  final String name;
  final String memberId;
  final String email;
  final String? phone;
  final String organizationId;
  final DateTime joinDate;
  final bool isActive;
  final String role; // 'member' or 'admin'

  Member({
    this.id,
    required this.name,
    required this.memberId,
    required this.email,
    this.phone,
    required this.organizationId,
    required this.joinDate,
    this.isActive = true,
    this.role = 'member',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'member_id': memberId,
      'email': email,
      'phone': phone,
      'organization_id': organizationId,
      'join_date': joinDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'role': role,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    // Handle both SQLite (1/0) and Firestore (boolean) formats
    final isActiveValue = map['is_active'];
    final isActive = isActiveValue is bool 
        ? isActiveValue 
        : (isActiveValue == 1 || isActiveValue == true);
    
    return Member(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      memberId: map['member_id'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      organizationId: map['organization_id'] ?? '',
      joinDate: DateTime.parse(map['join_date']),
      isActive: isActive,
      role: map['role'] ?? 'member',
    );
  }

  Member copyWith({
    String? id,
    String? name,
    String? memberId,
    String? email,
    String? phone,
    String? organizationId,
    DateTime? joinDate,
    bool? isActive,
    String? role,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      memberId: memberId ?? this.memberId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      organizationId: organizationId ?? this.organizationId,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
    );
  }
}

