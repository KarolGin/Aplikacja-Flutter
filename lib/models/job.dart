import 'package:cloud_firestore/cloud_firestore.dart';

enum JobDepartment {
  drones,
  wash,
}

enum JobStatus {
  pending,
  completed,
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.status,
    required this.price,
    required this.scheduledAt,
    this.workerSignatureUrl,
    this.clientSignatureUrl,
    this.assignedToUserId,
  });

  final String id;
  final String title;
  final String description;
  final JobDepartment department;
  final JobStatus status;
  final double price;
  final DateTime scheduledAt;
  final String? workerSignatureUrl;
  final String? clientSignatureUrl;
  final String? assignedToUserId;

  bool get isCompleted => status == JobStatus.completed;

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Job(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      department: _departmentFromString(data['department'] as String?),
      status: _statusFromString(data['status'] as String?),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      workerSignatureUrl: data['workerSignatureUrl'] as String?,
      clientSignatureUrl: data['clientSignatureUrl'] as String?,
      assignedToUserId: data['assignedToUserId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'department': department.name,
      'status': status.name,
      'price': price,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'workerSignatureUrl': workerSignatureUrl,
      'clientSignatureUrl': clientSignatureUrl,
      'assignedToUserId': assignedToUserId,
    };
  }

  Job copyWith({
    JobStatus? status,
    String? workerSignatureUrl,
    String? clientSignatureUrl,
  }) {
    return Job(
      id: id,
      title: title,
      description: description,
      department: department,
      status: status ?? this.status,
      price: price,
      scheduledAt: scheduledAt,
      workerSignatureUrl: workerSignatureUrl ?? this.workerSignatureUrl,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
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
      case 'completed':
        return JobStatus.completed;
      default:
        return JobStatus.pending;
    }
  }
}
