// Domain entity: EmergencyContact (Step P7.3)

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Contact',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
        'created_at': createdAt.toIso8601String(),
      };
}
