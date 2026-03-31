import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  dronesWorker,
  washWorker,
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: _roleFromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'dronesWorker':
        return UserRole.dronesWorker;
      case 'washWorker':
        return UserRole.washWorker;
      default:
        return UserRole.washWorker;
    }
  }
}
