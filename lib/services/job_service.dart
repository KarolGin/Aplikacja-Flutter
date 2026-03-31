import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job.dart';

class JobService {
  JobService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection('jobs');

  Future<void> addJob(Job job) async {
    await _jobs.add(job.toFirestore());
  }

  Future<void> updateJob(Job job) {
    return _jobs.doc(job.id).update(job.toFirestore());
  }

  Future<void> deleteJob(String jobId) {
    return _jobs.doc(jobId).delete();
  }

  Stream<List<Job>> watchJobs() {
    return _jobs
        .orderBy('scheduledAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Job.fromFirestore).toList());
  }

  Future<void> markInProgress(String jobId) {
    return _jobs.doc(jobId).update(<String, dynamic>{
      'status': JobStatus.inProgress.name,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeJob({
    required String jobId,
    required String clientSignatureBase64,
    required String completedBy,
  }) {
    return _jobs.doc(jobId).update(<String, dynamic>{
      'status': JobStatus.completed.name,
      'clientSignatureBase64': clientSignatureBase64,
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': completedBy,
    });
  }
}
