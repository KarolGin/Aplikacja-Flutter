import 'package:cloud_firestore/cloud_firestore.dart';

enum JobDepartment {
  drones,
  wash,
}

enum JobStatus {
  pending,
  inProgress,
  completed,
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.clientName,
    required this.description,
    required this.address,
    required this.department,
    required this.status,
    required this.price,
    required this.scheduledAt,
    this.completedAt,
    this.completedBy,
    this.workerSignatureUrl,
    this.clientSignatureUrl,
    this.clientSignatureBase64,
    this.assignedToUserId,
  });

  final String id;
  final String title;
  final String clientName;
  final String description;
  final String address;
  final JobDepartment department;
  final JobStatus status;
  final double price;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String? completedBy;
  final String? workerSignatureUrl;
  final String? clientSignatureUrl;
  final String? clientSignatureBase64;
  final String? assignedToUserId;

  bool get isCompleted => status == JobStatus.completed;

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Job(
      id: doc.id,
      title: data['title'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      department: _departmentFromString(data['department'] as String?),
      status: _statusFromString(data['status'] as String?),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'] as String?,
      workerSignatureUrl: data['workerSignatureUrl'] as String?,
      clientSignatureUrl: data['clientSignatureUrl'] as String?,
      clientSignatureBase64: data['clientSignatureBase64'] as String?,
      assignedToUserId: data['assignedToUserId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'clientName': clientName,
      'description': description,
      'address': address,
      'department': department.name,
      'status': status.name,
      'price': price,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'completedBy': completedBy,
      'workerSignatureUrl': workerSignatureUrl,
      'clientSignatureUrl': clientSignatureUrl,
      'clientSignatureBase64': clientSignatureBase64,
      'assignedToUserId': assignedToUserId,
    };
  }

  Job copyWith({
    String? title,
    String? clientName,
    String? description,
    String? address,
    JobDepartment? department,
    JobStatus? status,
    double? price,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? completedBy,
    String? workerSignatureUrl,
    String? clientSignatureUrl,
    String? clientSignatureBase64,
  }) {
    return Job(
      id: id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      address: address ?? this.address,
      department: department ?? this.department,
      status: status ?? this.status,
      price: price ?? this.price,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      workerSignatureUrl: workerSignatureUrl ?? this.workerSignatureUrl,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
      clientSignatureBase64: clientSignatureBase64 ?? this.clientSignatureBase64,
      assignedToUserId: assignedToUserId,
    );
  }

  static JobDepartment _departmentFromString(String? value) {
    switch (value) {
      case 'drones':
        return JobDepartment.drones;
      case 'wash':
        return JobDepartment.wash;
      default:
        return JobDepartment.wash;
    }
  }

  static JobStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return JobStatus.pending;
      case 'inProgress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      default:
        return JobStatus.pending;
    }
  }
}
