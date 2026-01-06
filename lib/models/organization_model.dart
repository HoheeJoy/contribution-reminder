class Organization {
  final String? id;
  final String name;
  final String? logo;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String currency;
  final Map<String, dynamic> settings;

  Organization({
    this.id,
    required this.name,
    this.logo,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.currency = 'USD',
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'currency': currency,
      'settings': _encodeSettings(settings),
    };
  }

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      logo: map['logo'],
      contactEmail: map['contact_email'],
      contactPhone: map['contact_phone'],
      address: map['address'],
      currency: map['currency'] ?? 'USD',
      settings: _decodeSettings(map['settings']),
    );
  }

  Organization copyWith({
    String? id,
    String? name,
    String? logo,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? currency,
    Map<String, dynamic>? settings,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      settings: settings ?? this.settings,
    );
  }

  static String _encodeSettings(Map<String, dynamic> settings) {
    // Simple JSON encoding - in production, use proper JSON encoding
    return settings.toString();
  }

  static Map<String, dynamic> _decodeSettings(dynamic settings) {
    // Simple JSON decoding - in production, use proper JSON decoding
    if (settings == null || settings == '') {
      return {};
    }
    if (settings is Map<String, dynamic>) {
      return settings;
    }
    return {};
  }
}

