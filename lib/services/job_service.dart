import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/job.dart';

class JobService {
  JobService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('jobs');


  Future<void> addJob(Job job) async {
    await _jobs.add(job.toFirestore());
  }

  Stream<List<Job>> watchJobsForRole(UserRole role) {
    Query<Map<String, dynamic>> query =
        _jobs.orderBy('scheduledAt', descending: false);

    if (role == UserRole.dronesWorker) {
      query = query.where('department', isEqualTo: JobDepartment.drones.name);
    }

    if (role == UserRole.washWorker) {
      query = query.where('department', isEqualTo: JobDepartment.wash.name);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(Job.fromFirestore).toList(),
        );
  }
}
